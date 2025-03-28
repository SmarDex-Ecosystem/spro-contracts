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
    function getLoan(uint256 loanId) external returns (Loan memory loan_);

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
     * @param collateralAddress The address of the collateral asset.
     * @param collateralAmount The amount of the collateral asset.
     * @param creditAddress The address of the credit asset.
     * @param availableCreditLimit The available credit limit for the proposal.
     * @param fixedInterestAmount The fixed interest amount in credit asset tokens.
     * @param startTimestamp The start timestamp of the proposal.
     * @param loanExpiration The expiration timestamp of the proposal.
     * @param permit2Data The permit2 data, if the user opts to use permit2.
     */
    function createProposal(
        address collateralAddress,
        uint256 collateralAmount,
        address creditAddress,
        uint256 availableCreditLimit,
        uint256 fixedInterestAmount,
        uint40 startTimestamp,
        uint40 loanExpiration,
        bytes calldata permit2Data
    ) external;

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
     * @dev Any address can repay an active loan if the `collateralRecipient` address is set to `address(0)`. The
     * collateral will be transferred to the borrower associated with the loan. If the caller is the borrower and
     * provides a `collateralRecipient` address, the collateral will be transferred to the specified address instead of
     * the borrower’s address. The protocol will attempt to send the credit to the lender. If the transfer fails, the
     * credit will be sent to the protocol, and the lender will be able to claim it later.
     * @param loanId The ID of the loan being repaid.
     * @param permit2Data The permit2 data, if the user opts to use permit2.
     * @param collateralRecipient The address that will receive the collateral. If address(0) is provided, the
     * borrower's address will be used.
     */
    function repayLoan(uint256 loanId, bytes calldata permit2Data, address collateralRecipient) external;

    /**
     * @notice Repays multiple active loans.
     * @dev Any address can repay an active loan if the `collateralRecipient` address is set to `address(0)`. The
     * collateral will be transferred to the borrower associated with the loan. If the caller is the borrower and
     * provides a `collateralRecipient` address, the collateral will be transferred to the specified address instead of
     * the borrower’s address. The protocol will attempt to send the credit to the lender. If the transfer fails, the
     * credit will be sent to the protocol, and the lender will be able to claim it later.
     * @param loanIds An array of loan IDs being repaid.
     * @param permit2Data The permit2 data, if the user opts to use permit2.
     * @param collateralRecipient The address that will receive the collateral. If address(0) is provided, the
     * borrower's address will be used.
     */
    function repayMultipleLoans(uint256[] calldata loanIds, bytes calldata permit2Data, address collateralRecipient)
        external;

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
