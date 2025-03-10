// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

library SproConstantsLibrary {
    /// @dev Percentage denominator (10_000 = 100%)
    uint256 internal constant BPS_DIVISOR = 10_000;

    /// @dev The maximum SDEX fee.
    uint256 internal constant MAX_SDEX_FEE = 1_000_000e18; // 1,000,000 SDEX

    /// @dev The minimum loan duration.
    uint32 internal constant MIN_LOAN_DURATION = 10 minutes;
}
