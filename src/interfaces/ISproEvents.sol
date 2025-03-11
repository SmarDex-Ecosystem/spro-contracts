// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { ISproTypes } from "./ISproTypes.sol";

/**
 * @title Events for the Spro Protocol
 * @notice Defines all custom events emitted by the Spro protocol.
 */
interface ISproEvents is ISproTypes {
    /**
     * @notice The fee was updated.
     * @param newFee The new fee.
     */
    event FeeUpdated(uint256 newFee);

    /**
     * @notice The partial position was updated.
     * @param newPartialPositionBps The new partial position.
     */
    event PartialPositionBpsUpdated(uint256 newPartialPositionBps);

    /**
     * @notice A new loan was created.
     * @param loanId The id of the loan.
     * @param proposalHash The hash of the proposal.
     * @param terms The terms of the loan.
     */
    event LoanCreated(uint256 loanId, bytes32 indexed proposalHash, Terms terms);

    /**
     * @notice A loan was paid back.
     * @param loanId The id of the loan.
     */
    event LoanPaidBack(uint256 loanId);

    /**
     * @notice A repaid or defaulted loan was claimed.
     * @param loanId The id of the loan.
     * @param defaulted True if the loan was defaulted.
     */
    event LoanClaimed(uint256 loanId, bool defaulted);

    /**
     * @notice A proposal was created.
     * @param proposer The address of the proposer.
     * @param proposal The proposal structure.
     */
    event ProposalCreated(address indexed proposer, Proposal proposal);

    /**
     * @notice A proposal was canceled.
     * @param proposalHash The hash of the proposal.
     */
    event ProposalCanceled(bytes32 proposalHash);
}
