// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Marketplace.sol";
import "../src/NFT.sol";

contract MarketplaceTest is Test {
    Marketplace marketplace;
    NFT nft;
    address seller;
    address buyer;
    uint256 nftPrice = 1 ether;

    function setUp() public {
        seller = makeAddr("seller");
        buyer = makeAddr("buyer");

        nft = new NFT();

        marketplace = new Marketplace();
    }

    function testBuyNFT() public {
        // Allocate Ether to the buyer
        vm.deal(buyer, 2 ether);

        // Mint an NFT to the seller
        vm.prank(seller);
        nft.mintNFT(seller);

        uint256 tokenId = 1;

        // List the NFT on the marketplace
        vm.prank(seller);
        nft.approve(address(marketplace), tokenId);
        vm.prank(seller);
        marketplace.listNFT(address(nft), tokenId, nftPrice);

        // Check initial ownership
        assertEq(nft.ownerOf(tokenId), address(marketplace));

        // Buyer purchases the NFT
        vm.prank(buyer);
        marketplace.buyNFT{value: nftPrice}(address(nft), tokenId);

        // Check final ownership
        assertEq(nft.ownerOf(tokenId), buyer);

        // Check seller's balance
        uint256 sellerBalance = seller.balance;
        assertEq(sellerBalance, nftPrice);
    }
}
