// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import { Test } from "forge-std/Test.sol";

import { SproHandler } from "test/helper/SproHandler.sol";

import { Spro } from "src/spro/Spro.sol";
import { ISproTypes } from "src/interfaces/ISproTypes.sol";
import { ISproErrors } from "src/interfaces/ISproErrors.sol";

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

    function test_getLoanStatus() external {
        ISproTypes.LoanStatus status = sproHandler.exposed_getLoanStatus(0);
        assertTrue(status == ISproTypes.LoanStatus.NONE, "Loan status is incorrect.");

        _setLoanAndTestStatus(0, ISproTypes.LoanStatus.RUNNING, block.timestamp + 1, ISproTypes.LoanStatus.RUNNING);

        _setLoanAndTestStatus(0, ISproTypes.LoanStatus.RUNNING, block.timestamp, ISproTypes.LoanStatus.EXPIRED);

        _setLoanAndTestStatus(0, ISproTypes.LoanStatus.PAID_BACK, 0, ISproTypes.LoanStatus.PAID_BACK);

        _setLoanAndTestStatus(0, ISproTypes.LoanStatus.EXPIRED, 0, ISproTypes.LoanStatus.EXPIRED);
    }

    function _setLoanAndTestStatus(
        uint256 loanId,
        ISproTypes.LoanStatus status,
        uint256 loanExpiration,
        ISproTypes.LoanStatus expectedStatus
    ) internal {
        ISproTypes.Loan memory loan =
            ISproTypes.Loan(status, address(0), address(0), 0, uint40(loanExpiration), address(0), 0, address(0), 0, 0);
        sproHandler.exposed_set_loans(loan, loanId);
        status = sproHandler.exposed_getLoanStatus(loanId);
        assertTrue(status == expectedStatus, "Loan status is incorrect.");
    }
}
