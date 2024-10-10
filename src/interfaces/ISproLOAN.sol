// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

/**
 * @title ISproLOAN
 * @notice A LOAN token representing a loan in Spro protocol.
 * @dev Token doesn't hold any loan logic, just an address of a loan contract that minted the LOAN token.
 *      Spro LOAN token is shared between all loan contracts.
 */
interface ISproLOAN {
    /* ------------------------------------------------------------ */
    /*                VARIABLES & CONSTANTS DEFINITIONS             */
    /* ------------------------------------------------------------ */

    /// @dev Last used LOAN id. First LOAN id is 1. This value is incremental.
    function lastLoanId() external view returns (uint256);

    /* ------------------------------------------------------------ */
    /*                          EVENTS                              */
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
    /*                          FUNCTIONS                            */
    /* ------------------------------------------------------------ */

    /**
     * @notice Mint a new LOAN token.
     * @dev Only owner can mint a new LOAN token.
     * @param to Address of a LOAN token receiver.
     * @return loanId Id of a newly minted LOAN token.
     */
    function mint(address to) external returns (uint256 loanId);

    /**
     * @notice Burn a LOAN token.
     * @dev Any address that is associated with given loan id can call this function.
     *      It is enabled to let deprecated loan contracts repay and claim existing loans.
     * @param loanId Id of a LOAN token to be burned.
     */
    function burn(uint256 loanId) external;

    /**
     * @notice Return a LOAN token metadata uri base on a loan contract that minted the token.
     * @param tokenId Id of a LOAN token.
     * @return Metadata uri for given token id (loan id).
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
