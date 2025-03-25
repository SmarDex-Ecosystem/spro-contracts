// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import { Test } from "forge-std/Test.sol";

import { SproHandler } from "test/helper/SproHandler.sol";

import { Spro } from "src/spro/Spro.sol";
import { ISproTypes } from "src/interfaces/ISproTypes.sol";

contract SproInternalTest is Test {
    SproHandler sproHandler;

    function setUp() public {
        sproHandler = new SproHandler(address(1), address(1), 1, 1);
    }

    function test_isLoanRepayable() external view {
        bool canBeRepaid = sproHandler.i_isLoanRepayable(ISproTypes.LoanStatus.PAID_BACK, 0);
        assertFalse(canBeRepaid, "Loan shouldn't be repayable");

        canBeRepaid = sproHandler.i_isLoanRepayable(ISproTypes.LoanStatus.NONE, 0);
        assertFalse(canBeRepaid, "Loan shouldn't be repayable");

        canBeRepaid = sproHandler.i_isLoanRepayable(ISproTypes.LoanStatus.EXPIRED, 0);
        assertFalse(canBeRepaid, "Loan shouldn't be repayable");

        canBeRepaid = sproHandler.i_isLoanRepayable(ISproTypes.LoanStatus.RUNNING, 0);
        assertFalse(canBeRepaid, "Loan shouldn't be repayable");

        canBeRepaid = sproHandler.i_isLoanRepayable(ISproTypes.LoanStatus.RUNNING, uint40(block.timestamp + 1));
        assertTrue(canBeRepaid, "Loan should be repayable");
    }
}
