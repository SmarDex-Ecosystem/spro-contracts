// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title ISproLoanMetadataProvider
 * @notice Interface for a provider of a Loan token metadata.
 * @dev Loan contracts should implement this interface.
 */
interface ISproLoanMetadataProvider {
    /**
     * @notice Get a loan metadata uri for a Loan token minted by this contract.
     * @param tokenId Loan token id.
     * @return uri_ Loan metadata uri.
     */
    function loanMetadataUri(uint256 tokenId) external view returns (string memory uri_);
}
