// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

library SproConstantsLibrary {
    string internal constant VERSION = "1.0";
    uint256 internal constant WAD = 1e18;
    /// @dev Percentage denominator (10_000 = 100%)
    uint256 internal constant PERCENTAGE = 1e4;
    /**
     * @notice Fee sink address.
     */
    address public constant SINK = address(0xdead);

    /* -------------------------------------------------------------------------- */
    /*                                    LOAN                                    */
    /* -------------------------------------------------------------------------- */

    uint32 public constant MIN_LOAN_DURATION = 10 minutes;
    uint40 public constant MAX_ACCRUING_INTEREST_APR = 16e6; // 160,000 APR (with 2 decimals)

    uint256 public constant ACCRUING_INTEREST_APR_DECIMALS = 1e2;
    uint256 public constant MINUTES_IN_YEAR = 525_600; // Note: Assuming 365 days in a year
    uint256 public constant ACCRUING_INTEREST_APR_DENOMINATOR = ACCRUING_INTEREST_APR_DECIMALS * MINUTES_IN_YEAR * 100;

    uint256 public constant MAX_EXTENSION_DURATION = 90 days;
    uint256 public constant MIN_EXTENSION_DURATION = 1 days;

    /* -------------------------------------------------------------------------- */
    /*                                  PROPOSAL                                  */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev EIP-712 simple proposal struct type hash.
     */
    bytes32 public constant PROPOSAL_TYPEHASH = keccak256(
        "Proposal(address collateralAddress,uint256 collateralAmount,bool checkCollateralStateFingerprint,bytes32 collateralStateFingerprint,address creditAddress,uint256 availableCreditLimit,uint256 fixedInterestAmount,uint40 accruingInterestAPR,uint32 duration,uint40 startTimestamp,address proposer,bytes32 proposerSpecHash,uint256 nonceSpace,uint256 nonce,address loanContract)"
    );
}
