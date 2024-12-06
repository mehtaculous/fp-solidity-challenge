// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IMarketplaceEventsAndErrors} from "./IMarketplaceEventsAndErrors.sol";

struct Listing {
    address seller;
    uint96 price;
    address erc20Token;
}

struct Order {
    address nftContract;
    uint256 tokenId;
    address seller;
    uint96 price;
    address erc20Token;
    uint96 expirationTimestamp;
}

interface IMarketplace is IMarketplaceEventsAndErrors {
    function buyNFT(address _nftContract, uint256 _tokenId) external payable;

    function buyNFT(Order calldata _order, bytes calldata _signature) external payable;

    function listNFT(
        address _nftContract,
        uint256 _tokenId,
        uint96 _price,
        address _erc20Token
    ) external;

    function generateOrderHash(Order calldata _order, uint256 _nonce) external view returns (bytes32);

    function listings(address, uint256) external view returns (address, uint96, address);

    function nonces(address) external view returns (uint256);

    function ORDER_TYPEHASH() external view returns (bytes32);
}