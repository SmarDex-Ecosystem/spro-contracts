// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

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
