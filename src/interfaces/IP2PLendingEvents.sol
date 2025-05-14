// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IP2PLendingTypes } from "./IP2PLendingTypes.sol";

/**
 * @title Events for the P2PLending Protocol
 * @notice Defines all custom events emitted by the P2PLending protocol.
 */
interface IP2PLendingEvents is IP2PLendingTypes {
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
     * @param loanId The loan ID.
     * @param proposalHash The hash of the proposal.
     * @param loanTerms The terms of the loan.
     */
    event LoanCreated(uint256 loanId, bytes32 indexed proposalHash, Terms loanTerms);

    /**
     * @notice A loan was paid back.
     * @param loanId The loan ID.
     */
    event LoanPaidBack(uint256 loanId);

    /**
     * @notice A repaid or defaulted loan was claimed.
     * @param loanId The loan ID.
     * @param defaulted True if the loan was defaulted.
     */
    event LoanClaimed(uint256 loanId, bool defaulted);

    /**
     * @notice A proposal was created.
     * @param proposalHash The hash of the proposal.
     * @param proposal The proposal structure.
     * @param sdexBurned The SDEX fee amount burned.
     */
    event ProposalCreated(bytes32 proposalHash, Proposal proposal, uint256 sdexBurned);

    /**
     * @notice A proposal was canceled.
     * @param proposalHash The hash of the proposal.
     */
    event ProposalCanceled(bytes32 proposalHash);
}
