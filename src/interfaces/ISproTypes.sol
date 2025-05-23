// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ISproTypes {
    /**
     * @notice Represents the status of a loan.
     * @param NONE The loan doesn't exist.
     * @param RUNNING The loan is running.
     * @param PAID_BACK The loan was paid back and can be claimed.
     * @param EXPIRED The loan expired and can be claimed.
     */
    enum LoanStatus {
        NONE,
        RUNNING,
        PAID_BACK,
        EXPIRED
    }

    /**
     * @notice Structure defining a loan terms.
     * @param lender The address of a lender.
     * @param borrower The address of a borrower.
     * @param startTimestamp The start timestamp of the proposal.
     * @param loanExpiration The expiration timestamp of the proposal.
     * @param collateralAddress The address of a collateral asset.
     * @param collateralAmount The amount of a collateral asset.
     * @param creditAddress The address of a credit asset.
     * @param creditAmount The amount of a credit asset.
     * @param fixedInterestAmount Fixed interest amount in credit asset tokens.
     */
    struct Terms {
        address lender;
        address borrower;
        uint40 startTimestamp;
        uint40 loanExpiration;
        address collateralAddress;
        uint256 collateralAmount;
        address creditAddress;
        uint256 creditAmount;
        uint256 fixedInterestAmount;
    }

    /**
     * @notice Struct defining a loan.
     * @param status The loan status.
     * @param lender The address of a lender that funded the loan.
     * @param borrower The address of a borrower.
     * @param startTimestamp The start timestamp of the proposal.
     * @param loanExpiration The expiration timestamp of the proposal.
     * @param collateralAddress The address of a collateral asset.
     * @param collateralAmount The amount of a collateral asset.
     * @param creditAddress The address of an asset used as a loan credit.
     * @param principalAmount Principal amount in credit asset tokens.
     * @param fixedInterestAmount Fixed interest amount in credit asset tokens.
     */
    struct Loan {
        LoanStatus status;
        address lender;
        address borrower;
        uint40 startTimestamp;
        uint40 loanExpiration;
        address collateralAddress;
        uint256 collateralAmount;
        address creditAddress;
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
     * @param minAmount The minimum amount of credit tokens that can be borrowed from the proposal, or the remaining
     * amount the lender must leave in the proposal.
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
        uint256 minAmount;
    }
}
