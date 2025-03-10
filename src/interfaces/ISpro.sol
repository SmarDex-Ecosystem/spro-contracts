// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { ISproTypes } from "src/interfaces/ISproTypes.sol";
import { ISproErrors } from "src/interfaces/ISproErrors.sol";
import { ISproEvents } from "src/interfaces/ISproEvents.sol";

/**
 * @title ISpro
 * @notice Interface for Spro protocol.
 */
interface ISpro is ISproTypes, ISproErrors, ISproEvents {
    /* -------------------------------------------------------------------------- */
    /*                                   SETTER                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Set new protocol fee value.
     * @param newFee New fee value in amount SDEX tokens (units 1e18)
     */
    function setFee(uint256 newFee) external;

    /**
     * @notice Set percentage of a proposal's available credit limit used in partial lending (in basis points).
     * @param percentage New percentage value.
     */
    function setPartialPositionPercentage(uint16 percentage) external;

    /**
     * @notice Set metadata uri for loan tokens.
     * @param newMetadataUri New value of token metadata uri.
     */
    function setLoanMetadataUri(string memory newMetadataUri) external;

    /* -------------------------------------------------------------------------- */
    /*                                   GETTER                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Retrieves credit used and credit remaining for a proposal.
     * @param proposal Proposal struct.
     * @return used_ Credit used for the proposal.
     * @return remaining_ Credit remaining for the proposal.
     */
    function getProposalCreditStatus(ISproTypes.Proposal memory proposal)
        external
        view
        returns (uint256 used_, uint256 remaining_);

    /**
     * @notice Retrieves loan information.
     * @param loanId Id of the loan.
     * @return loan_ Loan data struct.
     * @return repaymentAmount_ Repayment amount for the loan.
     * @return loanOwner_ Current owner of the loan token.
     */
    function getLoan(uint256 loanId)
        external
        view
        returns (Loan memory loan_, uint256 repaymentAmount_, address loanOwner_);

    /**
     * @notice Retrieves the proposal hash for a given proposal struct.
     * @param proposal Proposal struct to be hashed.
     * @return proposalHash_ Hash of the proposal.
     */
    function getProposalHash(ISproTypes.Proposal memory proposal) external returns (bytes32 proposalHash_);

    /* -------------------------------------------------------------------------- */
    /*                                    VIEW                                    */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Calculates the loan repayment amount with fixed and accrued interest for a set of loan ids.
     * @dev Intended to be used to build permit data or credit token approvals.
     * @param loanIds Array of loan ids.
     * @param creditAddress Expected credit address for all loan ids. `creditAddress` must be the same for all
     * loan ids.
     * @return amount_ Total repayment amount for all loans.
     */
    function totalLoanRepaymentAmount(uint256[] memory loanIds, address creditAddress)
        external
        view
        returns (uint256 amount_);

    /* ------------------------------------------------------------ */
    /*                      CREATE PROPOSAL                         */
    /* ------------------------------------------------------------ */

    /**
     * @notice Create a borrow request proposal and transfers collateral to the protocol and SDEX to the dead address.
     * @param proposal Proposal struct.
     * @param permit2Data Permit data if user wants to use permit2 (optional).
     */
    function createProposal(Proposal calldata proposal, bytes calldata permit2Data) external;

    /* ------------------------------------------------------------ */
    /*        CANCEL PROPOSAL AND WITHDRAW UNUSED COLLATERAL        */
    /* ------------------------------------------------------------ */

    /**
     * @notice A borrower can cancel their proposal and withdraw unused collateral.
     * @dev Resets withdrawable collateral, delete proposal, transfers unused collateral to the proposer.
     * @dev Fungible withdrawable collateral with amount == 0 calls should not revert, should transfer 0 tokens.
     * @dev Loans already created are not affected.
     * @param proposal Proposal struct.
     */
    function cancelProposal(Proposal memory proposal) external;

    /* ------------------------------------------------------------ */
    /*                          CREATE LOAN                         */
    /* ------------------------------------------------------------ */

    /**
     * @notice Create a new loan.
     * @param proposal Proposal struct.
     * @param creditAmount Amount of credit tokens.
     * @param permit2Data Permit data if user wants to use permit2 (optional).
     * @return loanId_ Id of the created loan token.
     */
    function createLoan(Proposal memory proposal, uint256 creditAmount, bytes calldata permit2Data)
        external
        returns (uint256 loanId_);

    /* ------------------------------------------------------------ */
    /*                          REPAY LOAN                          */
    /* ------------------------------------------------------------ */

    /**
     * @notice Repay running loan.
     * @dev Any address can repay a running loan, but a collateral will be transferred to a borrower address associated
     * with the loan. If the loan token holder is the same as the original lender, the repayment credit asset will be
     * transferred to the loan token holder directly. Otherwise it will transfer the repayment credit asset to the
     * protocol, waiting on a loan token holder to claim it.
     * @param loanId Id of a loan that is being repaid.
     * @param permit2Data Permit data if user wants to use permit2 (optional).
     */
    function repayLoan(uint256 loanId, bytes calldata permit2Data) external;

    /**
     * @notice Repay running loans.
     * @dev Any address can repay a running loan, but a collateral will be transferred to a borrower address associated
     * with the loan. If the loan token holder is the same as the original lender, the repayment credit asset will be
     * transferred to the loan token holder directly. Otherwise it will transfer the repayment credit asset to the
     * protocol, waiting on a loan token holder to claim it.
     * @param loanIds Id array of loans that are being repaid.
     * @param creditAddress Expected credit address for all loan ids. `creditAddress` must be the same for all
     * loan ids.
     * @param permit2Data Permit data if user wants to use permit2 (optional).
     */
    function repayMultipleLoans(uint256[] calldata loanIds, address creditAddress, bytes calldata permit2Data)
        external;

    /* ------------------------------------------------------------ */
    /*                          CLAIM LOAN                          */
    /* ------------------------------------------------------------ */

    /**
     * @notice Claim a repaid or defaulted loan.
     * @dev Only a loan token holder can claim a repaid or defaulted loan. Claim will transfer the repaid credit or
     * collateral to a loan token holder address and burn the loan token.
     * @param loanId Id of a loan that is being claimed.
     */
    function claimLoan(uint256 loanId) external;

    /**
     * @notice Claim multiple repaid or defaulted loans.
     * @dev Only a loan token holder can claim a repaid or defaulted loan. Claim will transfer the repaid credit or
     * collateral to a loan token holder address and burn the loan token.
     * @param loanIds Array of ids of loans that are being claimed.
     */
    function claimMultipleLoans(uint256[] memory loanIds) external;

    /**
     * @notice Try to claim a repaid loan for the loan owner.
     * @dev The function is called only by the protocol to repay a loan directly to the original lender. If the transfer
     * fails, the loan token will remain in repaid state and the loan token owner will be able to claim the repaid
     * credit. Otherwise lender would be able to prevent borrower from repaying the loan.
     * @param loanId Id of a loan that is being claimed.
     * @param creditAmount Amount of a credit to be claimed.
     * @param loanOwner Address of the loan token holder.
     */
    function tryClaimRepaidLoan(uint256 loanId, uint256 creditAmount, address loanOwner) external;
}
