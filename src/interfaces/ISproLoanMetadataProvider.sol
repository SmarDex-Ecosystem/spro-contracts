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
     * @return Loan token metadata uri.
     */
    function loanMetadataUri() external view returns (string memory);
}
