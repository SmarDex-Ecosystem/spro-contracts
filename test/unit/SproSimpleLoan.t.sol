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

    function test_isLoanRepayable() external view {
        bool canBeRepaid = sproHandler.exposed_isLoanRepayable(ISproTypes.LoanStatus.PAID_BACK, 0);
        assertFalse(canBeRepaid, "Loan shouldn't be repayable");

        canBeRepaid = sproHandler.exposed_isLoanRepayable(ISproTypes.LoanStatus.NONE, 0);
        assertFalse(canBeRepaid, "Loan shouldn't be repayable");

        canBeRepaid = sproHandler.exposed_isLoanRepayable(ISproTypes.LoanStatus.EXPIRED, 0);
        assertFalse(canBeRepaid, "Loan shouldn't be repayable");

        canBeRepaid = sproHandler.exposed_isLoanRepayable(ISproTypes.LoanStatus.RUNNING, 0);
        assertFalse(canBeRepaid, "Loan shouldn't be repayable");

        canBeRepaid = sproHandler.exposed_isLoanRepayable(ISproTypes.LoanStatus.RUNNING, uint40(block.timestamp + 1));
        assertTrue(canBeRepaid, "Loan should be repayable");
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
