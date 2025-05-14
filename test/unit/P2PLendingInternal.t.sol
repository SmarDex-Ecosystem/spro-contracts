// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import { Test } from "forge-std/Test.sol";

import { P2PLendingHandler } from "test/helper/P2PLendingHandler.sol";

import { P2PLending } from "src/p2pLending/P2PLending.sol";
import { IP2PLendingTypes } from "src/interfaces/IP2PLendingTypes.sol";

contract P2PLendingInternalTest is Test {
    P2PLendingHandler sproHandler;

    function setUp() public {
        sproHandler = new P2PLendingHandler(address(1), address(1), 1, 1, address(this));
    }

    function test_isLoanRepayable() external view {
        bool canBeRepaid = sproHandler.i_isLoanRepayable(IP2PLendingTypes.LoanStatus.PAID_BACK, 0);
        assertFalse(canBeRepaid, "Loan shouldn't be repayable");

        canBeRepaid = sproHandler.i_isLoanRepayable(IP2PLendingTypes.LoanStatus.NONE, 0);
        assertFalse(canBeRepaid, "Loan shouldn't be repayable");

        canBeRepaid = sproHandler.i_isLoanRepayable(IP2PLendingTypes.LoanStatus.EXPIRED, 0);
        assertFalse(canBeRepaid, "Loan shouldn't be repayable");

        canBeRepaid = sproHandler.i_isLoanRepayable(IP2PLendingTypes.LoanStatus.RUNNING, 0);
        assertFalse(canBeRepaid, "Loan shouldn't be repayable");

        canBeRepaid = sproHandler.i_isLoanRepayable(IP2PLendingTypes.LoanStatus.RUNNING, uint40(block.timestamp + 1));
        assertTrue(canBeRepaid, "Loan should be repayable");
    }
}
