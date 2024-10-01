// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract T721 is ERC721("ERC721", "ERC721") {
    function mint(address owner, uint256 tokenId) external {
        _mint(owner, tokenId);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }
}
