// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { IPoolAdapter } from "src/interfaces/IPoolAdapter.sol";

interface ISproTypes {
    /**
     * @notice Struct defining a simple loan terms.
     * @dev This struct is created by proposal contracts and never stored.
     * @param lender Address of a lender.
     * @param borrower Address of a borrower.
     * @param startTimestamp Unix timestamp (in seconds) of a start date.
     * @param loanExpiration Unix timestamp (in seconds) of a default date.
     * @param collateral Address of a collateral asset.
     * @param collateralAmount Amount of a collateral asset.
     * @param credit Address of a credit asset.
     * @param creditAmount Amount of a credit asset.
     * @param fixedInterestAmount Fixed interest amount in credit asset tokens.
     * @param lenderSpecHash Hash of a lender specification.
     */
    struct Terms {
        address lender;
        address borrower;
        uint40 startTimestamp;
        uint40 loanExpiration;
        address collateral;
        uint256 collateralAmount;
        address credit;
        uint256 creditAmount;
        uint256 fixedInterestAmount;
        bytes32 lenderSpecHash;
    }

    /**
     * @notice Lender specification during loan creation.
     * @param sourceOfFunds Address of a source of funds. This can be the lenders address, if the loan is funded
     * directly,
     *                      or a pool address from with the funds are withdrawn on the lenders behalf.
     * @param creditAmount Amount of credit tokens to lend.
     */
    struct LenderSpec {
        address sourceOfFunds;
        uint256 creditAmount;
    }

    /**
     * @notice Loan status enum.
     * @param NONE none/dead.
     * @param RUNNING running/accepted offer/accepted request.
     * @param PAID_BACK paid back.
     * @param EXPIRED expired.
     */
    enum LoanStatus {
        NONE,
        RUNNING,
        PAID_BACK,
        EXPIRED
    }

    /**
     * @notice Struct defining a simple loan.
     * @param status Loan status.
     * @param creditAddress Address of an asset used as a loan credit.
     * @param originalSourceOfFunds Address of a source of funds that was used to fund the loan.
     * @param poolAdapter Address of a pool adapter used to withdraw and supply assets to the pool. address(0) if the
     * originalSourceOfFound is the lender.
     * @param startTimestamp Unix timestamp (in seconds) of a start date.
     * @param loanExpiration Unix timestamp (in seconds) of a default date.
     * @param borrower Address of a borrower.
     * @param originalLender Address of a lender that funded the loan.
     * @param fixedInterestAmount Fixed interest amount in credit asset tokens.
     * @param principalAmount Principal amount in credit asset tokens.
     * @param collateral Address of a collateral asset.
     * @param collateralAmount Amount of a collateral asset.
     */
    struct Loan {
        LoanStatus status;
        address creditAddress;
        address originalSourceOfFunds;
        IPoolAdapter poolAdapter;
        uint40 startTimestamp;
        uint40 loanExpiration;
        address borrower;
        address originalLender;
        uint256 fixedInterestAmount;
        uint256 principalAmount;
        address collateral;
        uint256 collateralAmount;
    }

    /**
     * @notice Construct defining a simple proposal.
     * @param collateralAddress Address of an asset used as a collateral.
     * @param collateralAmount Amount of tokens used as a collateral, in case of ERC721 should be 0.
     * @param creditAddress Address of an asset which is lent to a borrower.
     * @param availableCreditLimit Available credit limit for the proposal. It is the maximum amount of tokens which can
     * be borrowed using the proposal. If non-zero, proposal can be accepted more than once, until the credit limit is
     * reached.
     * @param fixedInterestAmount Fixed interest amount in credit asset tokens.
     * @param startTimestamp Proposal start timestamp in seconds.
     * @param loanExpiration Proposal default timestamp in seconds.
     * @param proposer Address of a proposal signer. If `isOffer` is true, the proposer is the lender. If `isOffer` is
     * false, the proposer is the borrower.
     * @param nonce Additional value to enable identical proposals in time. Without it, it would be impossible to make
     * an identical proposal again.
     * @param loanContract Address of a loan contract that will create a loan from the proposal.
     * @param partialPositionBps Minimum percentage that can be borrowed from the initial proposal.
     */
    struct Proposal {
        address collateralAddress;
        uint256 collateralAmount;
        address creditAddress;
        uint256 availableCreditLimit;
        uint256 fixedInterestAmount;
        uint40 startTimestamp;
        uint40 loanExpiration;
        address proposer;
        uint256 nonce;
        address loanContract;
        uint16 partialPositionBps;
    }

    /**
     * @notice Loan information struct.
     * @param status Loan status.
     * @param startTimestamp Unix timestamp (in seconds) of a loan creation date.
     * @param loanExpiration Unix timestamp (in seconds) of a loan default date.
     * @param borrower Address of a loan borrower.
     * @param originalLender Address of a loan original lender.
     * @param loanOwner Address of a Loan token holder.
     * @param fixedInterestAmount Fixed interest amount in credit asset tokens.
     * @param credit Address of a credit asset.
     * @param collateral Address of a collateral asset.
     * @param collateralAmount Amount of a collateral asset.
     * @param originalSourceOfFunds Address of a source of funds for the loan. Original lender address, if the loan was
     * funded directly, or a pool address from witch credit funds were withdrawn / borrowed.
     * @param repaymentAmount Loan repayment amount in credit asset tokens.
     */
    struct LoanInfo {
        LoanStatus status;
        uint40 startTimestamp;
        uint40 loanExpiration;
        address borrower;
        address originalLender;
        address loanOwner;
        uint256 fixedInterestAmount;
        address credit;
        address collateral;
        uint256 collateralAmount;
        address originalSourceOfFunds;
        uint256 repaymentAmount;
    }

    /**
     * @notice Base struct for a proposal.
     * @param collateralAddress Address of an asset used as a collateral.
     * @param availableCreditLimit Available credit limit for the proposal. It is the maximum amount of tokens which can
     * be borrowed using the proposal. If non-zero, proposal can be accepted more than once, until the credit limit is
     * reached.
     * @param startTimestamp Proposal start timestamp in seconds.
     * @param proposer Address of a proposal signer. If `isOffer` is true, the proposer is the lender. If `isOffer` is
     * false, the proposer is the borrower.
     * @param loanContract Address of a loan contract that will create a loan from the proposal.
     * @param partialPositionBps Minimum percentage that can be borrowed from the initial proposal.
     */
    struct ProposalBase {
        address collateralAddress;
        uint256 availableCreditLimit;
        uint40 startTimestamp;
        address proposer;
        address loanContract;
        uint16 partialPositionBps;
    }
}
