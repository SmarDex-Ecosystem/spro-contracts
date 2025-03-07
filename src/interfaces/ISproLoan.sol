// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title ISproLoan
 * @notice A Loan token representing a loan in Spro protocol.
 * @dev Token doesn't hold any loan logic, just an address of a loan contract that minted the Loan token.
 *      Spro Loan token is shared between all loan contracts.
 */
interface ISproLoan {
    /* ------------------------------------------------------------ */
    /*                VARIABLES & CONSTANTS DEFINITIONS             */
    /* ------------------------------------------------------------ */

    /// @notice Get last used Loan id. First Loan id is 1. This value is incremental.
    function _lastLoanId() external view returns (uint256);

    /// @notice Get loan metadata URI.
    function _metadataUri() external view returns (string memory);

    /* ------------------------------------------------------------ */
    /*                          EVENTS                              */
    /* ------------------------------------------------------------ */

    /**
     * @notice Emitted when a new Loan token is minted.
     * @param loanId Id of a newly minted Loan token.
     * @param owner Address of a Loan token receiver.
     */
    event LoanMinted(uint256 indexed loanId, address indexed owner);

    /**
     * @notice Emitted when a Loan token is burned.
     * @param loanId Id of a burned Loan token.
     */
    event LoanBurned(uint256 indexed loanId);

    /**
     * @notice Emitted when new token metadata uri is set.
     * @param newUri The new uri.
     */
    event LoanMetadataUriUpdated(string newUri);

    /* ------------------------------------------------------------ */
    /*                          FUNCTIONS                            */
    /* ------------------------------------------------------------ */

    /**
     * @notice Mint a new Loan token.
     * @dev Only owner can mint a new Loan token.
     * @param to Address of a Loan token receiver.
     * @return loanId Id of a newly minted Loan token.
     */
    function mint(address to) external returns (uint256 loanId);

    /**
     * @notice Burn a Loan token.
     * @dev Any address that is associated with given loan id can call this function.
     *      It is enabled to let deprecated loan contracts repay and claim existing loans.
     * @param loanId Id of a Loan token to be burned.
     */
    function burn(uint256 loanId) external;

    /**
     * @notice Return a Loan token metadata uri base on a loan contract that minted the token.
     * @param tokenId Id of a Loan token.
     * @return Metadata uri for given token id (loan id).
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /**
     * @notice Set a new metadata uri for Loan tokens.
     * @dev Only owner can set a new metadata uri.
     * @param newMetadataUri New value of token metadata uri.
     */
    function setLoanMetadataUri(string memory newMetadataUri) external;
}
