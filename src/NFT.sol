// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFT is ERC721 {
    uint256 private next;

    constructor() ERC721("ExampleNFT", "ENFT") {}

    function mintNFT(address to) public {
        uint256 tokenId = ++next;
        _safeMint(to, tokenId);
    }
}
