// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { SDBaseIntegrationTest } from "test/integration/utils/Fixtures.sol";

import { ISproErrors } from "src/interfaces/ISproErrors.sol";

contract SproIntegrationClaimLoan is SDBaseIntegrationTest {
    function setUp() public {
        _setUp(false);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  claimLoan                                 */
    /* -------------------------------------------------------------------------- */

    function test_RevertWhen_claimLoanCallerNotLoanTokenHolder() external {
        _createERC20Proposal();
        uint256 loanId = _createLoan(proposal, CREDIT_AMOUNT, "");

        vm.startPrank(borrower);
        // Borrower approvals for credit token
        credit.mint(borrower, FIXED_INTEREST_AMOUNT); // helper step: mint fixed interest amount for the borrower
        credit.approve(address(spro), CREDIT_AMOUNT + FIXED_INTEREST_AMOUNT);
        vm.stopPrank();

        // Transfer loanToken to this address
        vm.prank(lender);
        loanToken.transferFrom(lender, address(this), loanId);

        // Initial lender repays loan
        vm.startPrank(lender);
        vm.expectRevert(ISproErrors.CallerNotLoanTokenHolder.selector);
        spro.claimLoan(loanId);
    }

    function test_RevertWhen_claimLoanRunningAndExpired() external {
        _createERC20Proposal();
        uint256 loanId = _createLoan(proposal, CREDIT_LIMIT, "");

        // Borrower approvals for credit token
        vm.startPrank(borrower);
        credit.mint(borrower, FIXED_INTEREST_AMOUNT); // helper step: mint fixed interest amount for the borrower
        credit.approve(address(spro), CREDIT_LIMIT + FIXED_INTEREST_AMOUNT);
        vm.stopPrank();

        // Transfer loanToken to this address
        vm.prank(lender);
        loanToken.transferFrom(lender, address(this), loanId);

        skip(100 days); // loan should be expired

        // loan token holder claims the expired loan
        spro.claimLoan(loanId);

        assertEq(collateral.balanceOf(address(this)), proposal.collateralAmount); // collateral amount transferred to
            // loan token holder
        assertEq(loanToken.balanceOf(address(this)), 0); // loanToken balance should be zero now
    }

    function test_RevertWhen_claimLoan_LoanRunning() external {
        _createERC20Proposal();
        uint256 loanId = _createLoan(proposal, CREDIT_AMOUNT, "");

        vm.startPrank(borrower);
        // Borrower approvals for credit token
        credit.mint(borrower, FIXED_INTEREST_AMOUNT); // helper step: mint fixed interest amount for the borrower
        credit.approve(address(spro), CREDIT_AMOUNT + FIXED_INTEREST_AMOUNT);
        vm.stopPrank();

        // Try to repay loan
        vm.startPrank(lender);
        vm.expectRevert(ISproErrors.LoanRunning.selector);
        spro.claimLoan(loanId);
    }
}
