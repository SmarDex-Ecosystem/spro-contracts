// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { SDBaseIntegrationTest } from "test/integration/utils/Fixtures.sol";

import { ISproErrors } from "src/interfaces/ISproErrors.sol";
import { ISproTypes } from "src/interfaces/ISproTypes.sol";
import { Spro } from "src/spro/Spro.sol";

contract SproIntegrationLoan is SDBaseIntegrationTest {
    function setUp() public {
        _setUp(false);
    }

    /* -------------------------------------------------------------------------- */
    /*                                 CREATE LOAN                                */
    /* -------------------------------------------------------------------------- */

    function test_CreateLoan() external {
        _createERC20Proposal();
        uint256 loanId = _createLoan(proposal, CREDIT_LIMIT, "");

        assertEq(loanToken.ownerOf(loanId), lender);
        assertEq(sdex.balanceOf(address(0xdead)), spro._fee());
        assertEq(sdex.balanceOf(borrower), INITIAL_SDEX_BALANCE - spro._fee());
        assertEq(sdex.balanceOf(lender), INITIAL_SDEX_BALANCE);

        Spro.Loan memory loanInfo = spro.getLoan(loanId);
        assertTrue(loanInfo.status == ISproTypes.LoanStatus.RUNNING);

        assertEq(credit.balanceOf(lender), INITIAL_CREDIT_BALANCE - CREDIT_LIMIT);
        assertEq(credit.balanceOf(borrower), CREDIT_LIMIT);
    }

    function test_RevertWhen_ProposalDoesNotExists() external {
        vm.expectRevert(ISproErrors.ProposalDoesNotExists.selector);
        spro.createLoan(proposal, CREDIT_LIMIT, "");
    }

    function test_RevertWhen_proposerIsAcceptor() external {
        _createERC20Proposal();
        vm.prank(proposal.proposer);
        vm.expectRevert(abi.encodeWithSelector(ISproErrors.AcceptorIsProposer.selector, proposal.proposer));
        spro.createLoan(proposal, CREDIT_LIMIT, "");
    }

    function test_RevertWhen_proposalExpired() external {
        _createERC20Proposal();
        vm.warp(proposal.startTimestamp);
        vm.expectRevert(abi.encodeWithSelector(ISproErrors.Expired.selector, block.timestamp, proposal.startTimestamp));
        spro.createLoan(proposal, CREDIT_LIMIT, "");
    }

    function test_RevertWhen_availableCreditExceeded() external {
        _createERC20Proposal();
        vm.expectRevert(abi.encodeWithSelector(ISproErrors.AvailableCreditLimitExceeded.selector, CREDIT_LIMIT));
        spro.createLoan(proposal, CREDIT_LIMIT + 1, "");
    }

    function test_RevertWhen_PartialLoanGtCreditThreshold() external {
        _createERC20Proposal();
        uint256 BPS_DIVISOR = spro.BPS_DIVISOR();

        // 95.01% of available credit limit
        uint256 amount = (BPS_DIVISOR - spro._partialPositionBps() + 1) * CREDIT_LIMIT / BPS_DIVISOR;

        // Mint initial state & approve credit
        credit.mint(lender, INITIAL_CREDIT_BALANCE);
        vm.startPrank(lender);
        credit.approve(address(spro), CREDIT_LIMIT);

        // Create loan, expecting revert
        vm.expectRevert(
            abi.encodeWithSelector(
                ISproErrors.CreditAmountRemainingBelowMinimum.selector,
                amount,
                spro._partialPositionBps() * CREDIT_LIMIT / spro.BPS_DIVISOR()
            )
        );
        spro.createLoan(proposal, amount, "");
        vm.stopPrank();
    }

    function test_RevertWhen_partialLoanLtCreditThreshold() external {
        _createERC20Proposal();

        // 4.99% of available credit limit
        uint256 amount = spro._partialPositionBps() - 1;

        // Mint initial state & approve credit
        credit.mint(lender, INITIAL_CREDIT_BALANCE);
        vm.startPrank(lender);
        credit.approve(address(spro), CREDIT_LIMIT);

        // Create loan, expecting revert
        vm.expectRevert(
            abi.encodeWithSelector(
                ISproErrors.CreditAmountTooSmall.selector,
                amount,
                PARTIAL_POSITION_BPS * CREDIT_LIMIT / spro.BPS_DIVISOR()
            )
        );
        spro.createLoan(proposal, amount, "");
        vm.stopPrank();
    }

    function testFuzz_loanAccruedInterest(uint256 amount, uint256 future) external {
        amount =
            bound(amount, ((500 * CREDIT_LIMIT) / spro.BPS_DIVISOR()), ((9500 * CREDIT_LIMIT) / spro.BPS_DIVISOR()));
        uint256 fixedInterestAmount =
            Math.mulDiv(amount, proposal.fixedInterestAmount, proposal.availableCreditLimit, Math.Rounding.Ceil);
        future = bound(future, 1 days, proposal.startTimestamp);

        _createERC20Proposal();
        uint256 loanId = _createLoan(proposal, amount, "");

        skip(future);

        ISproTypes.Loan memory loanInfo = spro.getLoan(loanId);
        assertEq(loanInfo.principalAmount, amount);
        assertEq(loanInfo.principalAmount + loanInfo.fixedInterestAmount, amount + fixedInterestAmount);
    }
}
