// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ISproTypes {
    /**
     * @notice Represents the status of a loan.
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
     * @notice Structure defining a loan terms.
     * @param lender Address of a lender.
     * @param borrower Address of a borrower.
     * @param startTimestamp The start timestamp of the proposal.
     * @param loanExpiration The expiration timestamp of the proposal.
     * @param collateral Address of a collateral asset.
     * @param collateralAmount Amount of a collateral asset.
     * @param credit Address of a credit asset.
     * @param creditAmount Amount of a credit asset.
     * @param fixedInterestAmount Fixed interest amount in credit asset tokens.
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
    }

    /**
     * @notice Struct defining a loan.
     * @param status Loan status.
     * @param lender Address of a lender that funded the loan.
     * @param borrower Address of a borrower.
     * @param startTimestamp The start timestamp of the proposal.
     * @param loanExpiration The expiration timestamp of the proposal.
     * @param collateral Address of a collateral asset.
     * @param collateralAmount Amount of a collateral asset.
     * @param credit Address of an asset used as a loan credit.
     * @param principalAmount Principal amount in credit asset tokens.
     * @param fixedInterestAmount Fixed interest amount in credit asset tokens.
     */
    struct Loan {
        LoanStatus status;
        address lender;
        address borrower;
        uint40 startTimestamp;
        uint40 loanExpiration;
        address collateral;
        uint256 collateralAmount;
        address credit;
        uint256 principalAmount;
        uint256 fixedInterestAmount;
    }

    /**
     * @notice Structure defining a proposal.
     * @param collateralAddress The collateral asset address.
     * @param collateralAmount The collateral asset amount.
     * @param creditAddress The credit asset address.
     * @param availableCreditLimit Available credit limit for the proposal. It is the maximum amount of tokens which can
     * be borrowed using the proposal.
     * @param fixedInterestAmount Fixed interest amount in credit asset tokens.
     * @param startTimestamp The start timestamp of the proposal.
     * @param loanExpiration The expiration timestamp of the proposal.
     * @param proposer The address of a proposer.
     * @param nonce Additional value to enable identical proposals in time. Without it, it would be impossible to make
     * an identical proposal again.
     * @param partialPositionBps The minimum percentage that can be borrowed from the initial proposal.
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
        uint16 partialPositionBps;
    }

    /**
     * @notice The base structure for a proposal.
     * @param collateralAddress The address of the collateral asset.
     * @param availableCreditLimit Available credit limit for the proposal. It is the maximum amount of tokens which can
     * be borrowed using the proposal.
     * @param startTimestamp The proposal start timestamp.
     * @param proposer The proposer address.
     * @param partialPositionBps The minimum percentage that can be borrowed from the initial proposal.
     */
    struct ProposalBase {
        address collateralAddress;
        uint256 availableCreditLimit;
        uint40 startTimestamp;
        address proposer;
        uint16 partialPositionBps;
    }
}
