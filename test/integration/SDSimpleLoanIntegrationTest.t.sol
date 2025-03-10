// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { SDBaseIntegrationTest } from "test/integration/SDBaseIntegrationTest.t.sol";

import { ISproTypes } from "src/interfaces/ISproTypes.sol";
import { ISproErrors } from "src/interfaces/ISproErrors.sol";
import { SproConstantsLibrary as Constants } from "src/libraries/SproConstantsLibrary.sol";

contract SDSimpleLoanIntegrationTest is SDBaseIntegrationTest {
    function test_shouldCreateERC20Proposal_shouldCreatePartialLoan_shouldWithdrawRemainingCollateral() external {
        // Create the proposal
        vm.prank(borrower);
        _createERC20Proposal();

        // Create the loan
        vm.prank(lender);
        uint256 loanId = _createLoan(proposal, "");

        // Borrower withdraws remaining collateral
        vm.prank(borrower);
        _cancelProposal(proposal);

        // ASSERTIONS
        // loan token
        assertEq(deployment.loanToken.ownerOf(loanId), lender, "0: loanToken owner should be lender");
        // credit token
        assertEq(
            credit.balanceOf(lender),
            INITIAL_CREDIT_BALANCE - CREDIT_AMOUNT,
            "1: initial credit token balance reduced by credit amount"
        );
        assertEq(
            credit.balanceOf(borrower), CREDIT_AMOUNT, "2: credit token balance of borrower should be CREDIT_AMOUNT"
        );
        assertEq(
            credit.balanceOf(address(deployment.config)), 0, "3: credit token balance of loan contract should be 0"
        );
        // collateral token
        assertEq(t20.balanceOf(lender), 0, "4: ERC20 collateral token balance of lender should be 0");
        assertEq(
            t20.balanceOf(borrower),
            COLLATERAL_AMOUNT - (CREDIT_AMOUNT * COLLATERAL_AMOUNT) / CREDIT_LIMIT,
            "5: ERC20 collateral token balance of borrower should be unused collateral"
        );
        assertEq(
            t20.balanceOf(address(deployment.config)),
            (CREDIT_AMOUNT * COLLATERAL_AMOUNT) / CREDIT_LIMIT,
            "6: ERC20 collateral token balance of loan contract should be used collateral"
        );
        // sdex fees
        assertEq(
            deployment.sdex.balanceOf(address(0xdead)),
            deployment.config._fee(),
            "9: address(0xdead) should contain the sdex unlisted fee"
        );
    }

    function test_PartialLoan_ERC20Collateral_CancelProposal_RepayLoan() external {
        // Borrower: creates proposal
        _createERC20Proposal();

        // Mint initial state & approve credit
        credit.mint(lender, INITIAL_CREDIT_BALANCE);
        vm.prank(lender);
        credit.approve(address(deployment.config), CREDIT_LIMIT);

        // Lender: creates the loan
        vm.prank(lender);
        uint256 loanId = deployment.config.createLoan(proposal, CREDIT_AMOUNT, "");

        // Borrower: cancels proposal, withdrawing unused collateral
        vm.startPrank(borrower);
        deployment.config.cancelProposal(proposal);

        // Warp ahead, just before loan default
        vm.warp(proposal.loanExpiration - proposal.startTimestamp - 1);

        // Borrower approvals for credit token
        (ISproTypes.Loan memory loan,,) = deployment.config.getLoan(loanId);
        credit.mint(borrower, loan.fixedInterestAmount); // helper step: mint fixed interest amount for the borrower
        credit.approve(address(deployment.config), CREDIT_AMOUNT + loan.fixedInterestAmount);

        // Borrower: repays loan
        deployment.config.repayLoan(loanId, "");

        // Assertions
        assertEq(credit.balanceOf(borrower), 0);
        assertEq(credit.balanceOf(lender), INITIAL_CREDIT_BALANCE + loan.fixedInterestAmount);

        assertEq(t20.balanceOf(borrower), COLLATERAL_AMOUNT);
    }

    function test_RevertWhen_PartialLoanGtCreditThreshold() external {
        // Create the proposal
        vm.prank(borrower);
        _createERC20Proposal();

        // 95.01% of available credit limit
        uint256 amount =
            (Constants.BPS_DIVISOR - deployment.config._partialPositionBps() + 1) * CREDIT_LIMIT / Constants.BPS_DIVISOR;

        // Mint initial state & approve credit
        credit.mint(lender, INITIAL_CREDIT_BALANCE);
        vm.startPrank(lender);
        credit.approve(address(deployment.config), CREDIT_LIMIT);

        // Create loan, expecting revert
        vm.expectRevert(
            abi.encodeWithSelector(
                ISproErrors.CreditAmountRemainingBelowMinimum.selector,
                amount,
                deployment.config._partialPositionBps() * CREDIT_LIMIT / 1e4
            )
        );
        deployment.config.createLoan(proposal, amount, "");
        vm.stopPrank();
    }

    function test_RevertWhen_partialLoanLtCreditThreshold() external {
        // Create the proposal
        vm.prank(borrower);
        _createERC20Proposal();

        // 4.99% of available credit limit
        uint256 amount = deployment.config._partialPositionBps() - 1;

        // Mint initial state & approve credit
        credit.mint(lender, INITIAL_CREDIT_BALANCE);
        vm.startPrank(lender);
        credit.approve(address(deployment.config), CREDIT_LIMIT);

        // Create loan, expecting revert
        vm.expectRevert(
            abi.encodeWithSelector(
                ISproErrors.CreditAmountTooSmall.selector, amount, PARTIAL_POSITION_PERCENTAGE * CREDIT_LIMIT / 1e4
            )
        );
        deployment.config.createLoan(proposal, amount, "");
        vm.stopPrank();
    }

    function test_RevertWhen_CreateAlreadyMadeProposal() external {
        // Create the proposal
        _createERC20Proposal();
        // Mint initial state & approve collateral
        t20.mint(borrower, proposal.collateralAmount);
        vm.prank(borrower);
        t20.approve(address(deployment.config), proposal.collateralAmount);

        vm.expectRevert(ISproErrors.ProposalAlreadyExists.selector);
        vm.prank(borrower);
        deployment.config.createProposal(proposal, "");
    }

    function test_shouldFail_getProposalCreditStatus_ProposalNotExists() external {
        vm.expectRevert(ISproErrors.ProposalNotExists.selector);
        deployment.config.getProposalCreditStatus(proposal);
    }

    function testFuzz_GetProposalCreditStatus(uint256 limit, uint256 used) external {
        vm.assume(limit != 0);
        vm.assume(used <= limit);

        proposal.availableCreditLimit = limit;
        _createERC20Proposal();

        bytes32 proposalHash = deployment.config.getProposalHash(proposal);

        vm.store(address(deployment.config), keccak256(abi.encode(proposalHash, 0)), bytes32(uint256(1)));
        vm.store(address(deployment.config), keccak256(abi.encode(proposalHash, 1)), bytes32(used));

        (uint256 r, uint256 u) = deployment.config.getProposalCreditStatus(proposal);

        assertEq(r, limit - u);
    }

    function testGas_MultiplePartialLoans_Original() external {
        (uint256[] memory loanIds,) = _setupMultipleRepay();
        vm.startPrank(borrower);
        uint256 startGas = gasleft();
        for (uint256 i; i < 4; ++i) {
            deployment.config.repayLoan(loanIds[i], "");
        }
        emit log_named_uint("repayLoan with for loop", startGas - gasleft());
    }

    function testGas_MultiplePartialLoans_RepayMultiple() external {
        (uint256[] memory loanIds,) = _setupMultipleRepay();
        vm.startPrank(borrower);
        uint256 startGas = gasleft();
        deployment.config.repayMultipleLoans(loanIds, address(credit), "");
        emit log_named_uint("Gas used", startGas - gasleft());
    }

    function test_MultiplePartialLoans_RepayMultiple_Owner() external {
        (uint256[] memory loanIds, uint256 fixedInterestAmount) = _setupMultipleRepay();

        vm.startPrank(borrower);
        deployment.config.repayMultipleLoans(loanIds, address(credit), "");

        // Assertions
        assertEq(credit.balanceOf(borrower), 0);
        require(
            credit.balanceOf(lender) == credit.balanceOf(alice) && credit.balanceOf(lender) == credit.balanceOf(bob)
                && credit.balanceOf(lender) == credit.balanceOf(charlee)
        );
        assertEq(credit.balanceOf(lender), INITIAL_CREDIT_BALANCE + fixedInterestAmount);

        assertEq(0, deployment.loanToken.balanceOf(lender));
        assertEq(0, deployment.loanToken.balanceOf(alice));
        assertEq(0, deployment.loanToken.balanceOf(bob));
        assertEq(0, deployment.loanToken.balanceOf(charlee));

        assertEq(2000 * COLLATERAL_AMOUNT / 1e4, t20.balanceOf(borrower)); // 20% since 4 loans @ 5% minimum amount
        assertEq(8000 * COLLATERAL_AMOUNT / 1e4, t20.balanceOf(address(deployment.config)));
    }

    function test_MultiplePartialLoans_NotRevertIfOneLess() external {
        (uint256[] memory loanIds, uint256 fixedInterestAmount) = _setupMultipleRepay();

        vm.startPrank(borrower);
        // Simulate someone repaying one loan
        deployment.config.repayLoan(loanIds[2], "");
        // Must not revert
        deployment.config.repayMultipleLoans(loanIds, address(credit), "");

        // Assertions
        assertEq(credit.balanceOf(borrower), 0);
        require(
            credit.balanceOf(lender) == credit.balanceOf(alice) && credit.balanceOf(lender) == credit.balanceOf(bob)
                && credit.balanceOf(lender) == credit.balanceOf(charlee)
        );
        assertEq(credit.balanceOf(lender), INITIAL_CREDIT_BALANCE + fixedInterestAmount);

        assertEq(0, deployment.loanToken.balanceOf(lender));
        assertEq(0, deployment.loanToken.balanceOf(alice));
        assertEq(0, deployment.loanToken.balanceOf(bob));
        assertEq(0, deployment.loanToken.balanceOf(charlee));

        assertEq(2000 * COLLATERAL_AMOUNT / 1e4, t20.balanceOf(borrower)); // 20% since 4 loans @ 5% minimum amount
        assertEq(8000 * COLLATERAL_AMOUNT / 1e4, t20.balanceOf(address(deployment.config)));
    }

    function test_MultiplePartialLoans_RepayMultiple_RepayerNotOwner() external {
        (uint256[] memory loanIds, uint256 fixedInterestAmount) = _setupMultipleRepay();

        address repayer = makeAddr("repayer");
        uint256 repayAmount = deployment.config.totalLoanRepaymentAmount(loanIds, address(credit));

        credit.mint(repayer, repayAmount);
        vm.startPrank(repayer);
        credit.approve(address(deployment.config), repayAmount);
        deployment.config.repayMultipleLoans(loanIds, address(credit), "");
        vm.stopPrank();

        // Assertions
        assertEq(
            credit.balanceOf(borrower),
            4 * (proposal.availableCreditLimit * deployment.config._partialPositionBps()) / 1e4
                + 4 * fixedInterestAmount
        ); // 4x minted in _setupMultipleRepay & not used
        require(
            credit.balanceOf(lender) == credit.balanceOf(alice) && credit.balanceOf(lender) == credit.balanceOf(bob)
                && credit.balanceOf(lender) == credit.balanceOf(charlee)
        );
        assertEq(credit.balanceOf(lender), INITIAL_CREDIT_BALANCE + fixedInterestAmount);

        assertEq(0, deployment.loanToken.balanceOf(lender));
        assertEq(0, deployment.loanToken.balanceOf(alice));
        assertEq(0, deployment.loanToken.balanceOf(bob));
        assertEq(0, deployment.loanToken.balanceOf(charlee));
        assertEq(2000 * COLLATERAL_AMOUNT / 1e4, t20.balanceOf(borrower)); // 20% since 4 loans @ 5% minimum amount
        assertEq(8000 * COLLATERAL_AMOUNT / 1e4, t20.balanceOf(address(deployment.config)));
    }

    function test_MultiplePartialLoans_RepayMultiple_ClaimMultiple() external {
        (uint256[] memory loanIds,) = _setupMultipleRepay();

        vm.prank(alice);
        deployment.loanToken.transferFrom(alice, lender, 2);

        vm.prank(bob);
        deployment.loanToken.transferFrom(bob, lender, 3);

        vm.prank(borrower);
        deployment.config.repayMultipleLoans(loanIds, address(credit), "");

        uint256[] memory ids = new uint256[](2);
        ids[0] = 2;
        ids[1] = 3;

        vm.prank(lender);
        deployment.config.claimMultipleLoans(ids);
    }

    function _setupMultipleRepay() internal returns (uint256[] memory loanIds, uint256 fixedInterestAmount) {
        vm.prank(borrower);
        _createERC20Proposal();

        // Setup lenders array
        address[] memory lenders = new address[](4);
        lenders[0] = lender;
        lenders[1] = alice;
        lenders[2] = bob;
        lenders[3] = charlee;

        // Minimum credit amount
        uint256 minCreditAmount = (proposal.availableCreditLimit * deployment.config._partialPositionBps()) / 1e4;

        // Setup loanIds array
        loanIds = new uint256[](4);

        // Create loans for lenders
        for (uint256 i; i < 4; ++i) {
            // Mint initial state & approve credit
            credit.mint(lenders[i], INITIAL_CREDIT_BALANCE);
            vm.startPrank(lenders[i]);
            credit.approve(address(deployment.config), minCreditAmount);

            // Create loan
            loanIds[i] = deployment.config.createLoan(proposal, minCreditAmount, "");
            vm.stopPrank();
        }

        // Warp forward 4 days
        skip(4 days);

        // Approve repayment amount
        uint256 totalAmount = deployment.config.totalLoanRepaymentAmount(loanIds, address(credit));
        fixedInterestAmount = Math.mulDiv(
            minCreditAmount, proposal.fixedInterestAmount, proposal.availableCreditLimit, Math.Rounding.Ceil
        );
        credit.mint(borrower, 4 * fixedInterestAmount);
        vm.prank(borrower);
        credit.approve(address(deployment.config), totalAmount);
    }

    function test_shouldFail_claimLoan_CallerNotLoanTokenHolder() external {
        _createERC20Proposal();

        // Mint initial state & approve credit
        credit.mint(lender, INITIAL_CREDIT_BALANCE);
        vm.prank(lender);
        credit.approve(address(deployment.config), CREDIT_LIMIT);

        // Lender: creates the loan
        vm.prank(lender);
        uint256 loanId = deployment.config.createLoan(proposal, CREDIT_AMOUNT, "");

        vm.startPrank(borrower);
        // Borrower approvals for credit token
        credit.mint(borrower, FIXED_INTEREST_AMOUNT); // helper step: mint fixed interest amount for the borrower
        credit.approve(address(deployment.config), CREDIT_AMOUNT + FIXED_INTEREST_AMOUNT);
        vm.stopPrank();

        // Transfer loanToken to this address
        vm.prank(lender);
        deployment.loanToken.transferFrom(lender, address(this), loanId);

        // Borrower: repays loan
        vm.prank(borrower);
        deployment.config.repayLoan(loanId, "");

        // Initial lender repays loan
        vm.startPrank(lender);
        vm.expectRevert(ISproErrors.CallerNotLoanTokenHolder.selector);
        deployment.config.claimLoan(loanId);
    }

    function test_shouldFail_claimLoan_RunningAndExpired() external {
        _createERC20Proposal();

        // Mint initial state & approve credit
        credit.mint(lender, INITIAL_CREDIT_BALANCE);
        vm.prank(lender);
        credit.approve(address(deployment.config), CREDIT_LIMIT);

        // Lender: creates the loan
        vm.prank(lender);
        uint256 loanId = deployment.config.createLoan(proposal, CREDIT_LIMIT, "");

        // Borrower approvals for credit token
        vm.startPrank(borrower);
        credit.mint(borrower, FIXED_INTEREST_AMOUNT); // helper step: mint fixed interest amount for the borrower
        credit.approve(address(deployment.config), CREDIT_LIMIT + FIXED_INTEREST_AMOUNT);
        vm.stopPrank();

        // Transfer loanToken to this address
        vm.prank(lender);
        deployment.loanToken.transferFrom(lender, address(this), loanId);

        vm.warp(100 days); // loan should be expired

        // loan token holder claims the expired loan
        deployment.config.claimLoan(loanId);

        assertEq(t20.balanceOf(address(this)), proposal.collateralAmount); // collateral amount transferred to loan
        // token holder
        assertEq(deployment.loanToken.balanceOf(address(this)), 0); // loanToken balance should be zero now
    }

    function test_shouldFail_claimLoan_LoanRunning() external {
        _createERC20Proposal();

        // Mint initial state & approve credit
        credit.mint(lender, INITIAL_CREDIT_BALANCE);
        vm.prank(lender);
        credit.approve(address(deployment.config), CREDIT_LIMIT);

        // Lender: creates the loan
        uint256 creditAmount = CREDIT_AMOUNT;
        vm.prank(lender);
        uint256 loanId = deployment.config.createLoan(proposal, creditAmount, "");

        vm.startPrank(borrower);
        // Borrower approvals for credit token
        credit.mint(borrower, FIXED_INTEREST_AMOUNT); // helper step: mint fixed interest amount for the borrower
        credit.approve(address(deployment.config), CREDIT_AMOUNT + FIXED_INTEREST_AMOUNT);
        vm.stopPrank();

        // Try to repay loan
        vm.startPrank(lender);
        vm.expectRevert(ISproErrors.LoanRunning.selector);
        deployment.config.claimLoan(loanId);
    }

    function testFuzz_loanAccruedInterest(uint256 amount, uint256 future) external {
        amount = bound(amount, ((500 * CREDIT_LIMIT) / 1e4), ((9500 * CREDIT_LIMIT) / 1e4));
        future = bound(future, 1 days, proposal.startTimestamp);

        // Create the proposal
        vm.prank(borrower);
        _createERC20Proposal();

        // Mint initial state & approve credit
        credit.mint(lender, INITIAL_CREDIT_BALANCE);
        vm.startPrank(lender);
        credit.approve(address(deployment.config), CREDIT_LIMIT);

        uint256 loanId = deployment.config.createLoan(proposal, amount, "");

        // skip to the future
        skip(future);

        (ISproTypes.Loan memory loanInfo, uint256 repaymentAmount,) = deployment.config.getLoan(loanId);

        assertEq(repaymentAmount, amount + loanInfo.fixedInterestAmount);
    }
}
