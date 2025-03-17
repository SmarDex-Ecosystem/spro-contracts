// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { ISproTypes } from "src/interfaces/ISproTypes.sol";
import { ISproErrors } from "src/interfaces/ISproErrors.sol";
import { ISproEvents } from "src/interfaces/ISproEvents.sol";

/**
 * @title Spro Protocol Interface
 * @notice Interface for the Spro protocol.
 */
interface ISpro is ISproTypes, ISproErrors, ISproEvents {
    /**
     * @notice Sets the protocol fee value.
     * @param newFee The new fee value in SDEX tokens.
     */
    function setFee(uint256 newFee) external;

    /**
     * @notice Sets the minimum usage ratio for partial lending.
     * @param newPartialPositionBps The new percentage value, in basis points.
     */
    function setPartialPositionPercentage(uint16 newPartialPositionBps) external;

    /**
     * @notice Sets the metadata uri for the loan tokens.
     * @param newMetadataUri The new metadata uri.
     */
    function setLoanMetadataUri(string memory newMetadataUri) external;

    /**
     * @notice Retrieves the loan data for a given loan id.
     * @param loanId The loan ID.
     * @return loan_ The loan data.
     */
    function getLoan(uint256 loanId) external view returns (Loan memory loan_);

    /**
     * @notice Retrieves the used and remaining credit for a proposal.
     * @param proposal The proposal structure.
     * @return used_ The used credit of the proposal.
     * @return remaining_ The remaining credit of the proposal.
     */
    function getProposalCreditStatus(ISproTypes.Proposal memory proposal)
        external
        view
        returns (uint256 used_, uint256 remaining_);

    /**
     * @notice Retrieves the proposal hash.
     * @param proposal The proposal structure.
     * @return proposalHash_ The hash of the proposal.
     */
    function getProposalHash(ISproTypes.Proposal memory proposal) external returns (bytes32 proposalHash_);

    /**
     * @notice Calculates the total repayment amount for multiple loans, with the fixed interest amounts.
     * @dev The credit token must be the same for all loans.
     * @param loanIds Array of loan ids.
     * @return amount_ The total repayment amount for all loans.
     */
    function totalLoanRepaymentAmount(uint256[] memory loanIds) external view returns (uint256 amount_);

    /**
     * @notice Creates a new borrowing proposal.
     * @dev The collateral and SDEX tokens must be approved for the protocol contract.
     * @param proposal The proposal structure.
     * @param permit2Data The permit2 data, if the user opts to use permit2.
     */
    function createProposal(Proposal memory proposal, bytes calldata permit2Data) external;

    /**
     * @notice Cancels a borrowing proposal.
     * @dev Transfers unused collateral to the proposer.
     * @param proposal The proposal structure.
     */
    function cancelProposal(Proposal memory proposal) external;

    /**
     * @notice Creates a new loan.
     * @param proposal The proposal structure.
     * @param creditAmount The amount of credit tokens.
     * @param permit2Data The permit2 data, if the user opts to use permit2.
     * @return loanId_ The ID of the created loan token.
     */
    function createLoan(Proposal memory proposal, uint256 creditAmount, bytes calldata permit2Data)
        external
        returns (uint256 loanId_);

    /**
     * @notice Repays an active loan.
     * @dev Any address can repay an active loan. The collateral will be transferred to the borrower associated
     * with the loan. If the loan token holder is the original lender, the repayment credit will be transferred to them.
     * Otherwise, the repayment credit will be transferred to the protocol, awaiting the new owner to claim it.
     * @param loanId The loan ID being repaid.
     * @param permit2Data The permit2 data, if the user opts to use permit2.
     */
    function repayLoan(uint256 loanId, bytes calldata permit2Data) external;

    /**
     * @notice Repays multiple active loans.
     * @dev The credit token must be the same for all loan IDs.
     * Any address can repay an active loan. The collateral will be transferred to the borrower associated with the
     * loan. If the loan token holder is the original lender, the repayment credit will be transferred to them.
     * Otherwise, the repayment credit will be transferred to the protocol, awaiting the new owner to claim it.
     * @param loanIds An array of loan IDs being repaid.
     * @param permit2Data The permit2 data, if the user opts to use permit2.
     */
    function repayMultipleLoans(uint256[] calldata loanIds, bytes calldata permit2Data) external;

    /**
     * @notice Attempts to claim a repaid loan.
     * @dev This function can only be called by the protocol. If the transfer fails, the loan token will remain in
     * a repaid state, allowing the loan token holder to claim the repayment credit manually.
     * @param loanId The loan ID being claimed.
     * @param creditAmount The amount of credit tokens to be claimed.
     * @param creditAddress The address of the credit token send to the lender.
     * @param loanOwner The address of the loan token holder.
     */
    function tryClaimRepaidLoan(uint256 loanId, uint256 creditAmount, address creditAddress, address loanOwner)
        external;

    /**
     * @notice Claims multiple repaid or defaulted loans.
     * @dev Only a loan token holder can claim their repaid or defaulted loan. Claiming transfers the repaid credit
     * or collateral to the loan token holder and burns the loan token.
     * @param loanIds An array of loan IDs being claimed.
     */
    function claimMultipleLoans(uint256[] memory loanIds) external;

    /**
     * @notice Claims a repaid or defaulted loan.
     * @dev Only a loan token holder can claim their repaid or defaulted loan. Claiming transfers the repaid credit
     * or collateral to the loan token holder and burns the loan token.
     * @param loanId The loan ID being claimed.
     */
    function claimLoan(uint256 loanId) external;
}
