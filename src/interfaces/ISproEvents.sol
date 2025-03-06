// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { ISproTypes } from "./ISproTypes.sol";

/**
 * @title ISproEvents
 * @notice Events for the Spro Protocol
 */
interface ISproEvents is ISproTypes {
    /**
     * @notice Emitted when new fee is set.
     * @param newFee The new fee.
     */
    event FeeUpdated(uint256 newFee);

    /**
     * @notice Emitted when new partialPositionBps is set.
     * @param newPartialPositionBps The new partialPositionBps.
     */
    event PartialPositionBpsUpdated(uint256 newPartialPositionBps);

    /**
     * @notice Emitted when a new loan in created.
     * @param loanId The id of the loan.
     * @param proposalHash The hash of the proposal.
     * @param terms The terms of the loan.
     * @param lenderSpec The lender spec of the loan.
     */
    event LoanCreated(uint256 indexed loanId, bytes32 indexed proposalHash, Terms terms, LenderSpec lenderSpec);

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

    /**
     * @notice Emitted when a proposal is canceled.
     * @param proposalHash The hash of the proposal.
     */
    event ProposalCanceled(bytes32 indexed proposalHash);
}
