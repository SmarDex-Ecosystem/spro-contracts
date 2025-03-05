// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

library SproConstantsLibrary {
    /// @dev Percentage denominator (10_000 = 100%)
    uint256 internal constant BPS_DIVISOR = 10_000;
    /// @dev The maximum SDEX fee.
    uint256 internal constant MAX_SDEX_FEE = 1_000_000e18; // 1,000,000 SDEX

    /* -------------------------------------------------------------------------- */
    /*                                    LOAN                                    */
    /* -------------------------------------------------------------------------- */

    /// @dev The minimum loan duration.
    uint32 public constant MIN_LOAN_DURATION = 10 minutes;
}
