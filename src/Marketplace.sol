// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Marketplace {
    struct Listing {
        address seller;
        uint256 price;
    }

    mapping(address => mapping(uint256 => Listing)) public listings;

    function listNFT(
        address tokenContract,
        uint256 tokenId,
        uint256 price
    ) public {
        IERC721(tokenContract).transferFrom(msg.sender, address(this), tokenId);
        listings[tokenContract][tokenId] = Listing(msg.sender, price);
    }

    function buyNFT(address tokenContract, uint256 tokenId) public payable {
        Listing memory listing = listings[tokenContract][tokenId];
        require(listing.price > 0, "NFT not for sale");
        require(msg.value == listing.price, "Incorrect ETH amount");

        address sellerAddress = listing.seller;
        bytes memory safeTransferCall = abi.encodeWithSignature(
            "safeTransferFrom(address,address,uint256)",
            address(this),
            msg.sender,
            tokenId
        );

        assembly {
            pop(call(gas(), sellerAddress, callvalue(), 0, 0, 0, 0))

            pop(
                call(
                    gas(),
                    tokenContract,
                    0,
                    add(safeTransferCall, 32),
                    mload(safeTransferCall),
                    0,
                    0
                )
            )
        }

        delete listings[tokenContract][tokenId];
    }
}
