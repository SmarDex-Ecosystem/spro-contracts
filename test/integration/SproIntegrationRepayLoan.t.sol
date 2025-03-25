// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { SDBaseIntegrationTest } from "test/integration/utils/Fixtures.sol";

import { ISproErrors } from "src/interfaces/ISproErrors.sol";

contract SproIntegrationRepayLoan is SDBaseIntegrationTest {
    function setUp() public {
        _setUp(false);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  repayLoan                                 */
    /* -------------------------------------------------------------------------- */

    function test_RevertWhen_notRepayable() external {
        vm.expectRevert(ISproErrors.LoanCannotBeRepaid.selector);
        spro.repayLoan(0, "");

        _createERC20Proposal();
        uint256 loanId = _createLoan(proposal, CREDIT_AMOUNT, "");

        // Warp ahead, just when loan default
        vm.warp(proposal.loanExpiration);

        vm.expectRevert(ISproErrors.LoanCannotBeRepaid.selector);
        spro.repayLoan(loanId, "");
    }

    function testGas_MultiplePartialLoans_Original() external {
        (uint256[] memory loanIds,) = _setupMultipleRepay();
        vm.startPrank(borrower);
        uint256 startGas = gasleft();
        for (uint256 i; i < 4; ++i) {
            spro.repayLoan(loanIds[i], "");
        }
        emit log_named_uint("repayLoan with for loop", startGas - gasleft());
    }

    /* -------------------------------------------------------------------------- */
    /*                             repayMultipleLoans                             */
    /* -------------------------------------------------------------------------- */

    function testGas_MultiplePartialLoans_RepayMultiple() external {
        (uint256[] memory loanIds,) = _setupMultipleRepay();
        vm.startPrank(borrower);
        uint256 startGas = gasleft();
        spro.repayMultipleLoans(loanIds, "");
        emit log_named_uint("Gas used", startGas - gasleft());
    }

    function test_MultiplePartialLoans_RepayMultiple_Owner() external {
        (uint256[] memory loanIds, uint256 fixedInterestAmount) = _setupMultipleRepay();

        vm.startPrank(borrower);
        spro.repayMultipleLoans(loanIds, "");

        // Assertions
        assertEq(credit.balanceOf(borrower), 0);
        require(
            credit.balanceOf(lender) == credit.balanceOf(alice) && credit.balanceOf(lender) == credit.balanceOf(bob)
                && credit.balanceOf(lender) == credit.balanceOf(charlie)
        );
        assertEq(credit.balanceOf(lender), INITIAL_CREDIT_BALANCE + fixedInterestAmount);

        assertEq(0, loanToken.balanceOf(lender));
        assertEq(0, loanToken.balanceOf(alice));
        assertEq(0, loanToken.balanceOf(bob));
        assertEq(0, loanToken.balanceOf(charlie));

        assertEq(2000 * COLLATERAL_AMOUNT / spro.BPS_DIVISOR(), collateral.balanceOf(borrower)); // 20% since 4
            // loans @ 5% minimum amount
        assertEq(8000 * COLLATERAL_AMOUNT / spro.BPS_DIVISOR(), collateral.balanceOf(address(spro)));
    }

    function test_MultiplePartialLoans_NotRevertIfOneLess() external {
        (uint256[] memory loanIds, uint256 fixedInterestAmount) = _setupMultipleRepay();

        vm.startPrank(borrower);
        spro.repayLoan(loanIds[2], "");
        spro.repayMultipleLoans(loanIds, "");

        // Assertions
        assertEq(credit.balanceOf(borrower), 0);
        require(
            credit.balanceOf(lender) == credit.balanceOf(alice) && credit.balanceOf(lender) == credit.balanceOf(bob)
                && credit.balanceOf(lender) == credit.balanceOf(charlie)
        );
        assertEq(credit.balanceOf(lender), INITIAL_CREDIT_BALANCE + fixedInterestAmount);

        assertEq(0, loanToken.balanceOf(lender));
        assertEq(0, loanToken.balanceOf(alice));
        assertEq(0, loanToken.balanceOf(bob));
        assertEq(0, loanToken.balanceOf(charlie));

        assertEq(2000 * COLLATERAL_AMOUNT / spro.BPS_DIVISOR(), collateral.balanceOf(borrower)); // 20% since 4
            // loans @ 5% minimum amount
        assertEq(8000 * COLLATERAL_AMOUNT / spro.BPS_DIVISOR(), collateral.balanceOf(address(spro)));
    }

    function test_MultiplePartialLoans_RepayMultiple_RepayerNotOwner() external {
        (uint256[] memory loanIds, uint256 fixedInterestAmount) = _setupMultipleRepay();

        address repayer = makeAddr("repayer");
        uint256 repayAmount = spro.totalLoanRepaymentAmount(loanIds);

        credit.mint(repayer, repayAmount);
        vm.startPrank(repayer);
        credit.approve(address(spro), repayAmount);
        spro.repayMultipleLoans(loanIds, "");
        vm.stopPrank();

        // Assertions
        assertEq(
            credit.balanceOf(borrower),
            4 * (proposal.availableCreditLimit * spro._partialPositionBps()) / spro.BPS_DIVISOR()
                + 4 * fixedInterestAmount
        ); // 4x minted in _setupMultipleRepay & not used
        require(
            credit.balanceOf(lender) == credit.balanceOf(alice) && credit.balanceOf(lender) == credit.balanceOf(bob)
                && credit.balanceOf(lender) == credit.balanceOf(charlie)
        );
        assertEq(credit.balanceOf(lender), INITIAL_CREDIT_BALANCE + fixedInterestAmount);

        assertEq(0, loanToken.balanceOf(lender));
        assertEq(0, loanToken.balanceOf(alice));
        assertEq(0, loanToken.balanceOf(bob));
        assertEq(0, loanToken.balanceOf(charlie));
        assertEq(2000 * COLLATERAL_AMOUNT / spro.BPS_DIVISOR(), collateral.balanceOf(borrower)); // 20% since 4
            // loans @ 5% minimum amount
        assertEq(8000 * COLLATERAL_AMOUNT / spro.BPS_DIVISOR(), collateral.balanceOf(address(spro)));
    }

    /* -------------------------------------------------------------------------- */
    /*                    repayMultiple and claimMultipleLoans                    */
    /* -------------------------------------------------------------------------- */

    function test_MultiplePartialLoans_RepayMultiple_ClaimMultiple() external {
        (uint256[] memory loanIds,) = _setupMultipleRepay();

        vm.prank(alice);
        loanToken.transferFrom(alice, lender, 2);

        vm.prank(bob);
        loanToken.transferFrom(bob, lender, 3);

        // block transfers to enter in the try/catch block
        credit.blockTransfers(true, lender);
        vm.prank(borrower);
        spro.repayMultipleLoans(loanIds, "");
        credit.blockTransfers(false, address(0));

        uint256[] memory ids = new uint256[](2);
        ids[0] = 2;
        ids[1] = 3;

        vm.prank(lender);
        spro.claimMultipleLoans(ids);
    }

    function _setupMultipleRepay() internal returns (uint256[] memory loanIds, uint256 fixedInterestAmount) {
        _createERC20Proposal();

        address[] memory lenders = new address[](4);
        lenders[0] = lender;
        lenders[1] = alice;
        lenders[2] = bob;
        lenders[3] = charlie;

        uint256 minCreditAmount = (proposal.availableCreditLimit * spro._partialPositionBps()) / spro.BPS_DIVISOR();

        // Setup loanIds array
        loanIds = new uint256[](4);

        // Create loans for lenders
        for (uint256 i; i < 4; ++i) {
            // Mint initial state & approve credit
            credit.mint(lenders[i], INITIAL_CREDIT_BALANCE);
            vm.startPrank(lenders[i]);
            credit.approve(address(spro), minCreditAmount);

            // Create loan
            loanIds[i] = spro.createLoan(proposal, minCreditAmount, "");
            vm.stopPrank();
        }

        skip(4 days);

        // Approve repayment amount
        uint256 totalAmount = spro.totalLoanRepaymentAmount(loanIds);
        fixedInterestAmount = Math.mulDiv(
            minCreditAmount, proposal.fixedInterestAmount, proposal.availableCreditLimit, Math.Rounding.Ceil
        );
        credit.mint(borrower, 4 * fixedInterestAmount);
        vm.prank(borrower);
        credit.approve(address(spro), totalAmount);
    }
}
