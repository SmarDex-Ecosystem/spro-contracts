// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { ISproTypes } from "./ISproTypes.sol";

/**
 * @title ISproEvents
 * @notice Events for the Spro Protocol
 */
interface ISproEvents is ISproTypes {
    /**
     * @notice Emitted when new listed fee is set.
     * @param oldFee The old fee.
     * @param newFee The new fee.
     */
    event FixFeeListedUpdated(uint256 oldFee, uint256 newFee);

    /**
     * @notice Emitted when new unlisted fee is set.
     * @param oldFee The old fee.
     * @param newFee The new fee.
     */
    event FixFeeUnlistedUpdated(uint256 oldFee, uint256 newFee);

    /**
     * @notice Emitted when new variable factor is set.
     * @param oldFactor The old factor.
     * @param newFactor The new factor.
     */
    event VariableFactorUpdated(uint256 oldFactor, uint256 newFactor);

    /**
     * @notice Emitted when a listed token factor is set.
     * @param token The address of the token.
     * @param factor The new factor.
     */
    event ListedTokenUpdated(address token, uint256 factor);

    /**
     * @notice Emitted when new Loan token metadata uri is set.
     * @param loanContract The address of the loan contract.
     * @param newUri The new uri.
     */
    event LoanMetadataUriUpdated(address indexed loanContract, string newUri);

    /**
     * @notice Emitted when new default Loan token metadata uri is set.
     * @param newUri The new default uri.
     */
    event DefaultLoanMetadataUriUpdated(string newUri);

    /**
     * @notice Emitted when a new loan in created.
     * @param loanId The id of the loan.
     * @param proposalHash The hash of the proposal.
     * @param terms The terms of the loan.
     * @param lenderSpec The lender spec of the loan.
     * @param extra The extra data of the loan.
     */
    event LoanCreated(
        uint256 indexed loanId, bytes32 indexed proposalHash, Terms terms, LenderSpec lenderSpec, bytes extra
    );

    /**
     * @notice Emitted when a loan is paid back.
     * @param loanId The id of the loan.
     */
    event LoanPaidBack(uint256 indexed loanId);

    /**
     * @notice Emitted when a repaid or defaulted loan is claimed.
     * @param loanId The id of the loan.
     * @param defaulted True if the loan is defaulted.
     */
    event LoanClaimed(uint256 indexed loanId, bool indexed defaulted);

    /**
     * @notice Emitted when a proposal is made.
     * @param proposalHash The hash of the proposal.
     * @param proposer The address of the proposer.
     * @param proposal The proposal.
     */
    event ProposalMade(bytes32 indexed proposalHash, address indexed proposer, Proposal proposal);
}
