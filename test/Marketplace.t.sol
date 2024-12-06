// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {Marketplace} from "../src/Marketplace.sol";
import {NFT} from "../src/NFT.sol";
import {Token} from "../src/Token.sol";

import {Order} from "../src/IMarketplace.sol";
import {IMarketplaceEventsAndErrors} from "../src/IMarketplaceEventsAndErrors.sol";

contract MarketplaceTest is Test, IMarketplaceEventsAndErrors {
    Marketplace marketplace;
    NFT nftContract;
    Order order;
    Token erc20Token;
    
    address buyer;
    address seller;
    uint96 nftPrice;
    uint96 tokenPrice;
    uint256 tokenId;
    uint96 expirationTimestamp;

    uint8 v; 
    bytes32 r; 
    bytes32 s;
    uint256 nonce;
    bytes32 digest;
    bytes signature;

    function setUp() public {
        seller = makeAddr("seller");
        buyer = makeAddr("buyer");
        nftContract = new NFT();
        marketplace = new Marketplace();
        erc20Token = new Token(1_000_000);

        tokenId = 1;
        nftPrice = 1 ether;
        tokenPrice = 1_000;

        vm.prank(seller);
        nftContract.mintNFT(seller);

        erc20Token.transfer(buyer, tokenPrice);

        vm.deal(buyer, 2 ether);
    }

    function test_ListNFT() public {
        vm.startPrank(seller);
        nftContract.setApprovalForAll(address(marketplace), true);
        marketplace.listNFT(address(nftContract), tokenId, nftPrice, address(0));
        vm.stopPrank();

        (address listingSeller, uint96 listingPrice, address listingERC20Token) = marketplace.listings(address(nftContract), tokenId);

        assertTrue(nftContract.isApprovedForAll(seller, address(marketplace)));
        assertEq(listingSeller, seller);
        assertEq(listingPrice, nftPrice);
        assertEq(listingERC20Token, address(0));
    }

    function test_ListNFT_RevertsWhen_InsufficientPrice() public {
        vm.prank(seller);
        nftContract.setApprovalForAll(address(marketplace), true);
        
        vm.expectRevert(InsufficientPrice.selector);
        vm.prank(seller);
        marketplace.listNFT(address(nftContract), tokenId, 0, address(0));        
    }

    function test_ListNFT_RevertsWhen_NotOwner() public {
        vm.prank(seller);
        nftContract.setApprovalForAll(address(marketplace), true);

        vm.expectRevert(NotOwner.selector);
        vm.prank(buyer);
        marketplace.listNFT(address(nftContract), tokenId, nftPrice, address(0));
    }

    function test_ListNFT_RevertsWhen_NotApproved() public {
        vm.expectRevert(NotApproved.selector);
        vm.prank(seller);
        marketplace.listNFT(address(nftContract), tokenId, nftPrice, address(0));
    }

    function test_BuyNFT_WithEther() public {
        vm.startPrank(seller);
        nftContract.setApprovalForAll(address(marketplace), true);
        marketplace.listNFT(address(nftContract), tokenId, nftPrice, address(0));
        vm.stopPrank();

        vm.prank(buyer);
        marketplace.buyNFT{value: nftPrice}(address(nftContract), tokenId);

        assertEq(nftContract.ownerOf(tokenId), buyer);
        assertEq(seller.balance, nftPrice);
        assertEq(buyer.balance, 2 ether - nftPrice);
    }

    function test_BuyNFT_WithERC20Token() public {
        vm.startPrank(seller);
        nftContract.setApprovalForAll(address(marketplace), true);
        marketplace.listNFT(address(nftContract), tokenId, tokenPrice, address(erc20Token));
        vm.stopPrank();

        vm.startPrank(buyer);
        erc20Token.approve(address(marketplace), tokenPrice);
        marketplace.buyNFT(address(nftContract), tokenId);
        vm.stopPrank();

        assertEq(nftContract.ownerOf(tokenId), buyer);
        assertEq(erc20Token.balanceOf(seller), tokenPrice);
        assertEq(erc20Token.balanceOf(buyer), 0);
    }

    function test_BuyNFT_RevertsWhen_NotForSale() public {
        vm.expectRevert(NotForSale.selector);
        vm.prank(buyer);
        marketplace.buyNFT(address(nftContract), tokenId);
    }

    function test_BuyNFT_RevertsWhen_InvalidPrice() public {
        vm.startPrank(seller);
        nftContract.setApprovalForAll(address(marketplace), true);
        marketplace.listNFT(address(nftContract), tokenId, nftPrice, address(0));
        vm.stopPrank();

        vm.expectRevert(InvalidPrice.selector);
        vm.prank(buyer);
        marketplace.buyNFT{value: nftPrice - 1}(address(nftContract), tokenId);
    }

    function test_BuyNFT_OffchainOrder() public {
        vm.prank(seller);
        nftContract.setApprovalForAll(address(marketplace), true);

        expirationTimestamp = uint96(block.timestamp + 1 days);
        order = Order({
            nftContract: address(nftContract),
            tokenId: tokenId,
            seller: seller,
            price: nftPrice,
            erc20Token: address(0),
            expirationTimestamp: expirationTimestamp
        });

        nonce = marketplace.nonces(seller);
        digest = marketplace.generateOrderHash(order, nonce);
        (v, r, s) = vm.sign(uint256(keccak256("seller")), digest);
        signature = abi.encodePacked(r, s, v);

        vm.prank(buyer);
        marketplace.buyNFT{value: nftPrice}(order, signature);

        assertEq(nftContract.ownerOf(tokenId), buyer);
        assertEq(seller.balance, nftPrice);
        assertEq(buyer.balance, 2 ether - nftPrice);
    }
    
    function test_BuyNFT_OffchainOrder_RevertsWhen_OrderExpired() public {
        expirationTimestamp = uint96(block.timestamp + 1 days);
        order = Order({
            nftContract: address(nftContract),
            tokenId: tokenId,
            seller: seller,
            price: nftPrice,
            erc20Token: address(0),
            expirationTimestamp: expirationTimestamp
        });
        
        vm.warp(expirationTimestamp + 1);

        vm.expectRevert(OrderExpired.selector);
        vm.prank(buyer);
        marketplace.buyNFT{value: nftPrice}(order, signature);
    }

    function test_BuyNFT_OffchainOrder_RevertsWhen_InvalidSignature() public {
        vm.prank(seller);
        nftContract.setApprovalForAll(address(marketplace), true);

        expirationTimestamp = uint96(block.timestamp + 1 days);
        order = Order({
            nftContract: address(nftContract),
            tokenId: tokenId,
            seller: seller,
            price: nftPrice,
            erc20Token: address(0),
            expirationTimestamp: expirationTimestamp
        });

        nonce = marketplace.nonces(seller);
        digest = marketplace.generateOrderHash(order, nonce);
        (v, r, s) = vm.sign(uint256(keccak256("buyer")), digest);
        signature = abi.encodePacked(r, s, v);

        vm.expectRevert(InvalidSignature.selector);
        vm.prank(buyer);
        marketplace.buyNFT{value: nftPrice}(order, signature);
    }   
}
