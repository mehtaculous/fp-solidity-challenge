// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Marketplace {
    struct Listing {
        address seller;
        uint256 price;
    }

    mapping(address => mapping(uint256 => Listing)) public listings;

    function listNFT(address nftContract, uint256 tokenId, uint256 price) public {
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        listings[nftContract][tokenId] = Listing(msg.sender, price);
    }

    function buyNFT(address nftContract, uint256 tokenId) public payable {
        Listing memory listing = listings[nftContract][tokenId];
        require(listing.price > 0, "NFT not for sale");
        require(msg.value == listing.price, "Incorrect ETH amount");

        delete listings[nftContract][tokenId];

        payable(listing.seller).transfer(msg.value);
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
    }
}
