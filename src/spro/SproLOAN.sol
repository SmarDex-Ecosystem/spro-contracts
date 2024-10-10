// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { ISproLoanMetadataProvider } from "src/interfaces/ISproLoanMetadataProvider.sol";
import { ISproLOAN } from "src/interfaces/ISproLOAN.sol";

contract SproLOAN is ISproLOAN, ERC721, Ownable {
    /* ------------------------------------------------------------ */
    /*                VARIABLES & CONSTANTS DEFINITIONS             */
    /* ------------------------------------------------------------ */

    /// @inheritdoc ISproLOAN
    uint256 public lastLoanId;

    /* ------------------------------------------------------------ */
    /*                          CONSTRUCTOR                         */
    /* ------------------------------------------------------------ */

    /**
     * @notice Initialize SproLoan contract.
     * @param creator Address of the creator.
     */
    constructor(address creator) ERC721("Spro LOAN", "LOAN") Ownable(creator) { }

    /* ------------------------------------------------------------ */
    /*                       TOKEN LIFECYCLE                        */
    /* ------------------------------------------------------------ */

    /// @inheritdoc ISproLOAN
    function mint(address to) external onlyOwner returns (uint256 loanId) {
        loanId = ++lastLoanId;
        _mint(to, loanId);
        emit LOANMinted(loanId, to);
    }

    /// @inheritdoc ISproLOAN
    function burn(uint256 loanId) external onlyOwner {
        _burn(loanId);
        emit LOANBurned(loanId);
    }

    /* ------------------------------------------------------------ */
    /*                          METADATA                            */
    /* ------------------------------------------------------------ */

    /// @inheritdoc ISproLOAN
    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ISproLOAN) returns (string memory) {
        _requireOwned(tokenId);

        return ISproLoanMetadataProvider(owner()).loanMetadataUri();
    }
}
