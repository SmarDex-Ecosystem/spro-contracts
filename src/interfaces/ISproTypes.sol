// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

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
     * @param lender Address of a lender that funded the loan.
     * @param borrower Address of a borrower.
     * @param startTimestamp Unix timestamp (in seconds) of a start date.
     * @param loanExpiration Unix timestamp (in seconds) of a default date.
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
        uint16 partialPositionBps;
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
     * @param partialPositionBps Minimum percentage that can be borrowed from the initial proposal.
     */
    struct ProposalBase {
        address collateralAddress;
        uint256 availableCreditLimit;
        uint40 startTimestamp;
        address proposer;
        uint16 partialPositionBps;
    }
}
