// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import { Test } from "forge-std/Test.sol";

import { SproHandler } from "test/helper/SproHandler.sol";

import { Spro } from "src/spro/Spro.sol";
import { ISproTypes } from "src/interfaces/ISproTypes.sol";

contract SproInternalTest is Test {
    SproHandler sproHandler;
    address sdex = makeAddr("sdex");
    address permit2 = makeAddr("permit2");

    function setUp() public {
        sproHandler = new SproHandler(sdex, permit2, 1, 1);
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
