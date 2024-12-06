// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IMarketplaceEventsAndErrors {
    event ListingCanceled(address indexed nftContract, uint256 indexed tokenId, address indexed seller);
    event ListingCreated(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed seller,
        uint96 price,
        address erc20Token
    );
    event Purchased(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed buyer,
        address seller,
        uint96 price
    );

    error Marketplace__ETHTransferFailed();
    error Marketplace__InsufficientPrice();
    error Marketplace__InvalidPrice();
    error Marketplace__InvalidSignature();
    error Marketplace__NotApproved();
    error Marketplace__NotForSale();
    error Marketplace__NotOwner();
    error Marketplace__OrderExpired();
}
