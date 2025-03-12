// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import { Test } from "forge-std/Test.sol";

import { SproHandler } from "test/helper/SproHandler.sol";

import { Spro } from "src/spro/Spro.sol";
import { ISproTypes } from "src/interfaces/ISproTypes.sol";

contract SproSimpleLoanTest is Test {
    address public sdex = makeAddr("sdex");
    address public permit2 = makeAddr("permit2");
    address public config = makeAddr("config");

    SproHandler sproHandler;

    function setUp() public {
        vm.etch(config, bytes("data"));
        sproHandler = new SproHandler(sdex, permit2, 1, 1);
    }

    function test_getLoanReturnZeroForNonExistingLoan() external view {
        ISproTypes.Loan memory loan = sproHandler.getLoan(0);

        assertEq(loan.borrower, address(0), "Borrower should be zero address");
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
}
