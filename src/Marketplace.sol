// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IMarketplace, Listing, Order} from "./IMarketplace.sol";

contract Marketplace is IMarketplace, EIP712 {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    bytes32 constant public ORDER_TYPEHASH = keccak256(
        "Order(address nftContract,uint256 tokenId,address seller,uint96 price,address erc20Token,uint96 expirationTimestamp)"
    );

    mapping(address => mapping(uint256 => Listing)) public listings;
    mapping(address => uint256) public nonces;

    constructor() EIP712("Marketplace", "1") {}

    function listNFT(
        address _nftContract,
        uint256 _tokenId,
        uint96 _price,
        address _erc20Token
    ) public {
        if (_price == 0) revert InsufficientPrice();
        if (IERC721(_nftContract).ownerOf(_tokenId) != msg.sender) revert NotOwner();
        if (!IERC721(_nftContract).isApprovedForAll(msg.sender, address(this))) revert NotApproved();

        listings[_nftContract][_tokenId] = Listing(msg.sender, _price, _erc20Token);

        emit ListingCreated(_nftContract, _tokenId, msg.sender, _price, _erc20Token);
    }

    function buyNFT(address _nftContract, uint256 _tokenId) public payable {
        Listing memory listing = listings[_nftContract][_tokenId];
        if (listing.price == 0) revert NotForSale();

        delete listings[_nftContract][_tokenId];

        _executeSale(
            _nftContract, 
            _tokenId, 
            listing.seller, 
            msg.sender, 
            listing.price, 
            listing.erc20Token
        );
    }

    function buyNFT(Order calldata _order, bytes calldata _signature) public payable {
        _validateOrder(_order, _signature);
        ++nonces[_order.seller];

        if (listings[_order.nftContract][_order.tokenId].price > 0) {
            delete listings[_order.nftContract][_order.tokenId];
        }

        _executeSale(
            _order.nftContract, 
            _order.tokenId, 
            _order.seller, 
            msg.sender, 
            _order.price, 
            _order.erc20Token
        );
    }

    function generateOrderHash(Order calldata _order, uint256 _nonce) public view returns (bytes32) {
        bytes32 structHash = keccak256(abi.encode(ORDER_TYPEHASH, _order, _nonce));
        return _hashTypedDataV4(structHash);
    }

    function _executeSale(
        address _nftContract, 
        uint256 _tokenId, 
        address _seller, 
        address _buyer, 
        uint96 _price, 
        address _erc20Token
    ) internal {
        if (_erc20Token == address(0)) {
            if (msg.value != _price) revert InvalidPrice();
            (bool success, ) = payable(_seller).call{value: msg.value}("");
            if (!success) revert ETHTransferFailed();
        } else {
            IERC20(_erc20Token).transferFrom(_buyer, _seller, _price);
        }

        IERC721(_nftContract).safeTransferFrom(_seller, _buyer, _tokenId);

        emit NFTSold(_nftContract, _tokenId, _buyer, _price);
    }

    function _validateOrder(Order calldata _order, bytes calldata _signature) internal view {
        if (_order.price == 0) revert NotForSale();
        if (block.timestamp > _order.expirationTimestamp) revert OrderExpired();

        uint256 nonce = nonces[_order.seller];
        bytes32 digest = generateOrderHash(_order, nonce);
        address signer = digest.recover(_signature);
        if (signer != _order.seller) revert InvalidSignature();
    }
}
