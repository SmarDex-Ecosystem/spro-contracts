// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { SDListedFee } from "pwn/loan/lib/SDListedFee.sol";

contract SDFeeCalculator_CalculateFeeAmount_Test is Test {
    uint256 internal constant ff = 5e18;
    uint256 internal constant vf = 1e13;
    uint256 internal constant tf = 4e23;
    uint256 internal constant loanAmount = 250e18;

    function test_shouldReturnCorrectValue_zeroFee() external pure {
        uint256 feeAmount = SDListedFee.calculate(0, 0, 0, loanAmount);
        assertEq(feeAmount, 0);
    }

    function test_shouldReturnCorrectValue_zeroVariableFee_zeroVariableFactor() external pure {
        uint256 feeAmount = SDListedFee.calculate(ff, 0, tf, loanAmount);
        assertEq(feeAmount, ff);
    }

    function test_shouldReturnCorrectValue_zeroVariableFee_zeroTokenFactor() external pure {
        uint256 feeAmount = SDListedFee.calculate(ff, vf, 0, loanAmount);
        assertEq(feeAmount, ff);
    }

    function test_shouldReturnCorrectValue_zeroFixedFee() external pure {
        uint256 feeAmount = SDListedFee.calculate(0, vf, tf, loanAmount);
        uint256 expectedFee = (vf * tf * loanAmount) / 1e36;
        assertEq(feeAmount, expectedFee);
    }

    function test_shouldHandleSmallAmount() external pure {
        uint256 smallLoan = 100;
        uint256 feeAmount = SDListedFee.calculate(ff, vf, tf, smallLoan);
        uint256 expectedFee = ff + (vf * tf * smallLoan) / 1e36;
        assertEq(feeAmount, expectedFee);
    }

    function testFuzz_SDListedFee_Calculate(uint256 _ff, uint256 _vf, uint256 _tf, uint256 _loanAmount) external pure {
        _ff = bound(_ff, 0, 1e26);
        _vf = bound(_vf, 0, 1e32);
        _tf = bound(_tf, 0, 1e32);
        _loanAmount = bound(_loanAmount, 0, 1e30);

        uint256 feeAmount = SDListedFee.calculate(_ff, _vf, _tf, _loanAmount);
        uint256 intermediate = (_vf * _tf) / SDListedFee.WAD;
        uint256 expectedFee = _ff + (intermediate * _loanAmount) / 1e18;
        assertApproxEqAbs(feeAmount, expectedFee, 1);
        uint256 expectedFee2 = _ff + Math.mulDiv(intermediate, _loanAmount, SDListedFee.WAD, Math.Rounding.Ceil);
        assertEq(feeAmount, expectedFee2);
    }
}
