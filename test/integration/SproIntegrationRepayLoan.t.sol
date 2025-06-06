// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { SDBaseIntegrationTest } from "test/integration/utils/Fixtures.sol";

import { ISproTypes } from "src/interfaces/ISproTypes.sol";
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
        spro.repayLoan(0, "", address(0));

        _createERC20Proposal();
        uint256 loanId = _createLoan(proposal, CREDIT_AMOUNT, "");

        // Warp ahead, just when loan default
        vm.warp(proposal.loanExpiration);

        vm.expectRevert(ISproErrors.LoanCannotBeRepaid.selector);
        spro.repayLoan(loanId, "", address(0));
    }

    function testGas_MultiplePartialLoans_Original() external {
        (uint256[] memory loanIds,) = _setupMultipleRepay();
        vm.startPrank(borrower);
        uint256 startGas = gasleft();
        for (uint256 i; i < 4; ++i) {
            spro.repayLoan(loanIds[i], "", address(0));
        }
        emit log_named_uint("repayLoan with for loop", startGas - gasleft());
    }

    function test_RevertWhen_notBorrowerRepayWithRecipient() public {
        _createERC20Proposal();
        uint256 loanId = _createLoan(proposal, CREDIT_AMOUNT, "");

        ISproTypes.Loan memory loan = spro.getLoan(loanId);
        credit.mint(address(this), CREDIT_AMOUNT + loan.fixedInterestAmount);
        credit.approve(address(spro), CREDIT_AMOUNT + loan.fixedInterestAmount);

        vm.expectRevert(ISproErrors.CallerNotBorrower.selector);
        spro.repayLoan(loanId, "", address(1));
    }

    function test_borrowerRepayToAnotherAddress() public {
        _createERC20Proposal();
        uint256 loanId = _createLoan(proposal, CREDIT_AMOUNT, "");

        vm.startPrank(borrower);
        ISproTypes.Loan memory loan = spro.getLoan(loanId);
        credit.mint(borrower, loan.fixedInterestAmount);
        credit.approve(address(spro), CREDIT_AMOUNT + loan.fixedInterestAmount);

        spro.repayLoan(loanId, "", address(1));
        vm.stopPrank();

        assertEq(collateral.balanceOf(borrower), 0, "borrower shouldn't receive collateral");
        assertEq(collateral.balanceOf(address(1)), loan.collateralAmount, "recipient should receive collateral");
    }

    /* -------------------------------------------------------------------------- */
    /*                             repayMultipleLoans                             */
    /* -------------------------------------------------------------------------- */

    function test_RevertWhen_notBorrowerRepayMultipleWithRecipient() public {
        (uint256[] memory loanIds,) = _setupMultipleRepay();

        for (uint256 i; i < loanIds.length; ++i) {
            ISproTypes.Loan memory loan = spro.getLoan(loanIds[i]);
            credit.mint(address(this), CREDIT_AMOUNT + loan.fixedInterestAmount);
            credit.approve(address(spro), CREDIT_AMOUNT + loan.fixedInterestAmount);
        }

        vm.expectRevert(ISproErrors.CallerNotBorrower.selector);
        spro.repayMultipleLoans(loanIds, "", address(1));
    }

    function test_borrowerRepayMultipleToAnotherAddress() public {
        (uint256[] memory loanIds,) = _setupMultipleRepay();

        vm.prank(borrower);
        spro.repayMultipleLoans(loanIds, "", address(1));

        assertEq(collateral.balanceOf(borrower), 0, "borrower shouldn't receive collateral");
        assertEq(2000 * COLLATERAL_AMOUNT / spro.BPS_DIVISOR(), collateral.balanceOf(address(1))); // 20% since 4 loans
            // @ 5% minimum amount
        assertEq(8000 * COLLATERAL_AMOUNT / spro.BPS_DIVISOR(), collateral.balanceOf(address(spro)));
    }

    function testGas_MultiplePartialLoans_RepayMultiple() external {
        (uint256[] memory loanIds,) = _setupMultipleRepay();
        vm.startPrank(borrower);
        uint256 startGas = gasleft();
        spro.repayMultipleLoans(loanIds, "", address(0));
        emit log_named_uint("Gas used", startGas - gasleft());
    }

    function test_MultiplePartialLoans_RepayMultiple_Owner() external {
        (uint256[] memory loanIds, uint256 fixedInterestAmount) = _setupMultipleRepay();

        vm.startPrank(borrower);
        spro.repayMultipleLoans(loanIds, "", address(0));

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

        assertEq(2000 * COLLATERAL_AMOUNT / spro.BPS_DIVISOR(), collateral.balanceOf(borrower)); // 20% since 4 loans @
            // 5% minimum amount
        assertEq(8000 * COLLATERAL_AMOUNT / spro.BPS_DIVISOR(), collateral.balanceOf(address(spro)));
    }

    function test_MultiplePartialLoans_NotRevertIfOneLess() external {
        (uint256[] memory loanIds, uint256 fixedInterestAmount) = _setupMultipleRepay();

        vm.startPrank(borrower);
        spro.repayLoan(loanIds[2], "", address(0));
        spro.repayMultipleLoans(loanIds, "", address(0));

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
        spro.repayMultipleLoans(loanIds, "", address(0));
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
        spro.repayMultipleLoans(loanIds, "", address(0));
        credit.blockTransfers(false, address(0));

        uint256[] memory ids = new uint256[](2);
        ids[0] = 2;
        ids[1] = 3;

        vm.prank(lender);
        spro.claimMultipleLoans(ids);
    }

    /* -------------------------------------------------------------------------- */
    /*                          totalLoanRepaymentAmount                          */
    /* -------------------------------------------------------------------------- */

    function test_totalLoanRepaymentAmount() external {
        (uint256[] memory loanIds, uint256 fixedInterestAmount) = _setupMultipleRepay();
        uint256 totalAmount = spro.totalLoanRepaymentAmount(loanIds);
        assertEq(
            totalAmount,
            ((proposal.availableCreditLimit * spro._partialPositionBps()) / spro.BPS_DIVISOR()) * 4
                + fixedInterestAmount * 4,
            "totalLoanRepaymentAmount should be 4x the amount plus interest"
        );

        // skip to a state where the loan is not repayable
        skip(proposal.loanExpiration - block.timestamp + 1);
        totalAmount = spro.totalLoanRepaymentAmount(loanIds);
        assertEq(totalAmount, 0, "totalLoanRepaymentAmount should be 0");

        // set an non-existing loanId to test the revert
        loanIds[0] = 5;
        vm.expectRevert(abi.encodeWithSelector(ISproErrors.DifferentCreditAddress.selector, credit, address(0)));
        spro.totalLoanRepaymentAmount(loanIds);
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
