// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title ISproLoan
 * @notice A loan token representing a loan in Spro protocol.
 * @dev Token doesn't hold any loan logic. The owner, Spro, is responsible for loan logic.
 */
interface ISproLoan {
    /// @notice Get last used Loan id. First Loan id is 1. This value is incremental.
    function _lastLoanId() external view returns (uint256);

    /// @notice Get loan metadata URI.
    function _metadataUri() external view returns (string memory);

    /**
     * @notice The loan token is minted.
     * @param loanId Id of a newly minted loan token.
     * @param owner Address of a loan token receiver.
     */
    event LoanMinted(uint256 indexed loanId, address indexed owner);

    /**
     * @notice The loan token is burned.
     * @param loanId Id of a burned loan token.
     */
    event LoanBurned(uint256 indexed loanId);

    /**
     * @notice The token metadata uri is updated.
     * @param newUri The new uri.
     */
    event LoanMetadataUriUpdated(string newUri);

    /**
     * @notice Mint a new loan token.
     * @dev Only owner can mint a new loan token.
     * @param to Address of a loan token receiver.
     * @return loanId Id of a newly minted loan token.
     */
    function mint(address to) external returns (uint256 loanId);

    /**
     * @notice Burn a loan token.
     * @dev Only owner can burn a new loan token.
     * @param loanId Id of a loan token to be burned.
     */
    function burn(uint256 loanId) external;

    /**
     * @notice Return a loan token metadata uri.
     * @param tokenId Id of a loan token.
     * @return uri_ Metadata uri for given token id (loan id).
     */
    function tokenURI(uint256 tokenId) external view returns (string memory uri_);

    /**
     * @notice Set a new metadata uri for Loan tokens.
     * @dev Only owner can set a new metadata uri.
     * @param newMetadataUri New value of token metadata uri.
     */
    function setLoanMetadataUri(string memory newMetadataUri) external;
}
