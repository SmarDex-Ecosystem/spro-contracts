// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { ISproLoanMetadataProvider } from "src/interfaces/ISproLoanMetadataProvider.sol";

/**
 * @title Spro LOAN token
 * @notice A LOAN token representing a loan in Spro protocol.
 * @dev Token doesn't hold any loan logic, just an address of a loan contract that minted the LOAN token.
 *      Spro LOAN token is shared between all loan contracts.
 */
contract SproLOAN is ERC721, Ownable {
    /* ------------------------------------------------------------ */
    /*                VARIABLES & CONSTANTS DEFINITIONS             */
    /* ------------------------------------------------------------ */

    /// @dev Last used LOAN id. First LOAN id is 1. This value is incremental.
    uint256 public lastLoanId;

    /* ------------------------------------------------------------ */
    /*                      EVENTS DEFINITIONS                      */
    /* ------------------------------------------------------------ */

    /**
     * @notice Emitted when a new LOAN token is minted.
     * @param loanId Id of a newly minted LOAN token.
     * @param owner Address of a LOAN token receiver.
     */
    event LOANMinted(uint256 indexed loanId, address indexed owner);

    /**
     * @notice Emitted when a LOAN token is burned.
     * @param loanId Id of a burned LOAN token.
     */
    event LOANBurned(uint256 indexed loanId);

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

    /**
     * @notice Mint a new LOAN token.
     * @dev Only owner can mint a new LOAN token.
     * @param to Address of a LOAN token receiver.
     * @return loanId Id of a newly minted LOAN token.
     */
    function mint(address to) external onlyOwner returns (uint256 loanId) {
        loanId = ++lastLoanId;
        _mint(to, loanId);
        emit LOANMinted(loanId, to);
    }

    /**
     * @notice Burn a LOAN token.
     * @dev Any address that is associated with given loan id can call this function.
     *      It is enabled to let deprecated loan contracts repay and claim existing loans.
     * @param loanId Id of a LOAN token to be burned.
     */
    function burn(uint256 loanId) external onlyOwner {
        _burn(loanId);
        emit LOANBurned(loanId);
    }

    /* ------------------------------------------------------------ */
    /*                          METADATA                            */
    /* ------------------------------------------------------------ */

    /**
     * @notice Return a LOAN token metadata uri base on a loan contract that minted the token.
     * @param tokenId Id of a LOAN token.
     * @return Metadata uri for given token id (loan id).
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireOwned(tokenId);

        return ISproLoanMetadataProvider(owner()).loanMetadataUri();
    }
}
