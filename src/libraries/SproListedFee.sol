// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { SproConstantsLibrary as Constants } from "./SproConstantsLibrary.sol";

library SproListedFee {
    /**
     * @notice Compute list fee amount.
     * @param fixFeeListed Fixed fee value in units of fee token (basis 1e18)
     * @param variableFactor Variable factor (basis 1e18)
     * @param tokenFactor Listed credit token factor (basis 1e18)
     * @param loanAmount Amount of an asset used as a loan credit.
     * @return feeAmount_ Amount of SDEX that represents a protocol fee.
     */
    function calculate(uint256 fixFeeListed, uint256 variableFactor, uint256 tokenFactor, uint256 loanAmount)
        internal
        pure
        returns (uint256 feeAmount_)
    {
        feeAmount_ = fixFeeListed
            + Math.mulDiv((variableFactor * tokenFactor) / Constants.WAD, loanAmount, Constants.WAD, Math.Rounding.Ceil);
    }
}
