// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IMarketplaceEventsAndErrors {
    event ListingCanceled(address indexed nftContract, uint256 indexed tokenId, address indexed seller);
    event ListingCreated(address indexed nftContract, uint256 indexed tokenId, address indexed seller, uint96 price, address erc20Token);
    event NFTSold(address indexed nftContract, uint256 indexed tokenId, address indexed buyer, uint96 price);

    error ETHTransferFailed();
    error InsufficientPrice();
    error InvalidPrice();
    error InvalidSignature();
    error NotApproved();
    error NotForSale();
    error NotOwner();
    error OrderExpired();
}