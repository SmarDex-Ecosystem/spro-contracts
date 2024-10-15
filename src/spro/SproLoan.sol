// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { ISproLoanMetadataProvider } from "src/interfaces/ISproLoanMetadataProvider.sol";
import { ISproLoan } from "src/interfaces/ISproLoan.sol";

contract SproLoan is ISproLoan, ERC721, Ownable {
    /* ------------------------------------------------------------ */
    /*                VARIABLES & CONSTANTS DEFINITIONS             */
    /* ------------------------------------------------------------ */

    /// @inheritdoc ISproLoan
    uint256 public lastLoanId;

    /* ------------------------------------------------------------ */
    /*                          CONSTRUCTOR                         */
    /* ------------------------------------------------------------ */

    /**
     * @notice Initialize SproLoan contract.
     * @param creator Address of the creator.
     */
    constructor(address creator) ERC721("Spro Loan", "LOAN") Ownable(creator) { }

    /* ------------------------------------------------------------ */
    /*                       TOKEN LIFECYCLE                        */
    /* ------------------------------------------------------------ */

    /// @inheritdoc ISproLoan
    function mint(address to) external onlyOwner returns (uint256 loanId_) {
        loanId_ = ++lastLoanId;
        _mint(to, loanId_);
        emit LoanMinted(loanId_, to);
    }

    /// @inheritdoc ISproLoan
    function burn(uint256 loanId) external onlyOwner {
        _burn(loanId);
        emit LoanBurned(loanId);
    }

    /* ------------------------------------------------------------ */
    /*                          METADATA                            */
    /* ------------------------------------------------------------ */

    /// @inheritdoc ISproLoan
    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ISproLoan) returns (string memory) {
        _requireOwned(tokenId);

        return ISproLoanMetadataProvider(owner()).loanMetadataUri();
    }
}
