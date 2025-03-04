// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";

import { SproHandler } from "test/helper/SproHandler.sol";

import { Spro } from "src/spro/Spro.sol";
import { ISproTypes } from "src/interfaces/ISproTypes.sol";
import { ISproErrors } from "src/interfaces/ISproErrors.sol";

contract SproSimpleLoanTest is Test {
    address public sdex = makeAddr("sdex");
    address public permit2 = makeAddr("permit2");
    address public config = makeAddr("config");

    address public permitAsset = makeAddr("permitAsset");
    address public credit = makeAddr("credit");

    SproHandler sproHandler;

    function setUp() public {
        vm.etch(config, bytes("data"));
        sproHandler = new SproHandler(sdex, permit2, 1, 1);
    }

    function test_loanRepaymentAmount_shouldReturnZeroForNonExistingLoan() external view {
        (, uint256 repaymentAmount,) = sproHandler.getLoan(0);

        assertEq(repaymentAmount, 0);
    }

    function test_shouldFail_checkLoanCanBeRepaid_NonExistingLoan() external {
        vm.expectRevert(ISproErrors.NonExistingLoan.selector);
        sproHandler.exposed_checkLoanCanBeRepaid(ISproTypes.LoanStatus.NONE, 0);

        vm.expectRevert(ISproErrors.LoanNotRunning.selector);
        sproHandler.exposed_checkLoanCanBeRepaid(ISproTypes.LoanStatus.PAID_BACK, 0);
    }

    function test_shouldFail_checkLoanCanBeRepaid_LoanNotRunning() external {
        vm.expectRevert(ISproErrors.LoanNotRunning.selector);
        sproHandler.exposed_checkLoanCanBeRepaid(ISproTypes.LoanStatus.PAID_BACK, 0);
    }

    function test_shouldFail_checkLoanCanBeRepaid_LoanDefaulted() external {
        skip(30 days);
        uint40 ts = uint40(block.timestamp - 1);
        vm.expectRevert(abi.encodeWithSelector(ISproErrors.LoanDefaulted.selector, ts));
        sproHandler.exposed_checkLoanCanBeRepaid(ISproTypes.LoanStatus.RUNNING, ts);
    }

    function test_shouldFail_DifferentCreditAddress(address loanCreditAddress, address expectedCreditAddress)
        external
    {
        vm.assume(loanCreditAddress != expectedCreditAddress);

        vm.expectRevert(
            abi.encodeWithSelector(
                ISproErrors.DifferentCreditAddress.selector, loanCreditAddress, expectedCreditAddress
            )
        );
        sproHandler.exposed_checkLoanCreditAddress(loanCreditAddress, expectedCreditAddress);
    }
}
