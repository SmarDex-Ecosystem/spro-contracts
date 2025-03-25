// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { SDBaseIntegrationTest } from "test/integration/utils/Fixtures.sol";

import { ISproTypes } from "src/interfaces/ISproTypes.sol";
import { ISproErrors } from "src/interfaces/ISproErrors.sol";

contract SproIntegrationProposal is SDBaseIntegrationTest {
    function setUp() public {
        _setUp(false);
    }

    function test_createProposal() external {
        // Setup listed fee and token
        address owner = spro.owner();
        uint256 feeAmount = 1e17;
        vm.startPrank(owner);
        spro.setFee(feeAmount);
        vm.stopPrank();

        // Create proposal
        _createERC20Proposal();

        assertEq(collateral.balanceOf(address(spro)), COLLATERAL_AMOUNT);
        assertEq(sdex.balanceOf(address(0xdead)), spro._fee());
        assertEq(collateral.balanceOf(borrower), 0);

        assertEq(sdex.balanceOf(address(0xdead)), feeAmount);
        assertEq(sdex.balanceOf(borrower), INITIAL_SDEX_BALANCE - feeAmount);
        assertEq(sdex.balanceOf(borrower), INITIAL_SDEX_BALANCE - spro._fee());
    }

    function test_RevertWhen_CallerNotProposer() external {
        _createERC20Proposal();

        vm.expectRevert(ISproErrors.CallerNotProposer.selector);
        spro.cancelProposal(proposal);
    }

    function test_RevertWhen_AvailableCreditLimitZero() public {
        proposal.availableCreditLimit = 0;
        vm.expectRevert(abi.encodeWithSelector(ISproErrors.AvailableCreditLimitZero.selector));
        vm.prank(borrower);
        spro.createProposal(proposal, "");
    }

    function test_RevertWhen_InvalidDurationStartTime() external {
        // Set bad timestamp value
        proposal.startTimestamp = uint40(block.timestamp);
        proposal.loanExpiration = proposal.startTimestamp;

        // Mint initial state & approve collateral
        collateral.mint(borrower, proposal.collateralAmount);
        vm.prank(borrower);
        collateral.approve(address(spro), proposal.collateralAmount);

        vm.prank(borrower);
        vm.expectRevert(abi.encodeWithSelector(ISproErrors.InvalidDurationStartTime.selector));
        spro.createProposal(proposal, "");
    }

    function test_RevertWhen_InvalidLoanDuration() external {
        // Set bad timestamp value
        uint256 minDuration = spro.MIN_LOAN_DURATION();
        proposal.loanExpiration = proposal.startTimestamp + uint32(minDuration - 1);

        // Mint initial state & approve collateral
        collateral.mint(borrower, proposal.collateralAmount);
        vm.prank(borrower);
        collateral.approve(address(spro), proposal.collateralAmount);

        vm.prank(borrower);
        vm.expectRevert(
            abi.encodeWithSelector(
                ISproErrors.InvalidDuration.selector, proposal.loanExpiration - proposal.startTimestamp, minDuration
            )
        );
        spro.createProposal(proposal, "");
    }

    function test_shouldCreateERC20Proposal_shouldCreatePartialLoan_shouldWithdrawRemainingCollateral() external {
        _createERC20Proposal();

        vm.prank(lender);
        uint256 loanId = _createLoan(proposal, CREDIT_AMOUNT, "");

        // Borrower: cancels proposal, withdrawing unused collateral
        vm.prank(borrower);
        spro.cancelProposal(proposal);

        // ASSERTIONS
        // loan token
        assertEq(loanToken.ownerOf(loanId), lender, "0: loanToken owner should be lender");
        // credit token
        assertEq(
            credit.balanceOf(lender),
            INITIAL_CREDIT_BALANCE - CREDIT_AMOUNT,
            "1: initial credit token balance reduced by credit amount"
        );
        assertEq(
            credit.balanceOf(borrower), CREDIT_AMOUNT, "2: credit token balance of borrower should be CREDIT_AMOUNT"
        );
        assertEq(credit.balanceOf(address(spro)), 0, "3: credit token balance of loan contract should be 0");
        // collateral token
        assertEq(collateral.balanceOf(lender), 0, "4: ERC20 collateral token balance of lender should be 0");
        assertEq(
            collateral.balanceOf(borrower),
            COLLATERAL_AMOUNT - (CREDIT_AMOUNT * COLLATERAL_AMOUNT) / CREDIT_LIMIT,
            "5: ERC20 collateral token balance of borrower should be unused collateral"
        );
        assertEq(
            collateral.balanceOf(address(spro)),
            (CREDIT_AMOUNT * COLLATERAL_AMOUNT) / CREDIT_LIMIT,
            "6: ERC20 collateral token balance of loan contract should be used collateral"
        );
        // sdex fees
        assertEq(sdex.balanceOf(address(0xdead)), spro._fee(), "9: DEAD_ADDRESS should contain the sdex unlisted fee");
    }

    function test_PartialLoan_ERC20Collateral_CancelProposal_RepayLoan() external {
        _createERC20Proposal();
        uint256 loanId = _createLoan(proposal, CREDIT_AMOUNT, "");

        // Borrower: cancels proposal, withdrawing unused collateral
        vm.startPrank(borrower);
        spro.cancelProposal(proposal);

        // Warp ahead, just before loan default
        vm.warp(proposal.loanExpiration - proposal.startTimestamp - 1);

        // Borrower approvals for credit token
        ISproTypes.Loan memory loan = spro.getLoan(loanId);
        credit.mint(borrower, loan.fixedInterestAmount);
        credit.approve(address(spro), CREDIT_AMOUNT + loan.fixedInterestAmount);

        // Borrower: repays loan
        spro.repayLoan(loanId, "");

        // Assertions
        assertEq(credit.balanceOf(borrower), 0);
        assertEq(credit.balanceOf(lender), INITIAL_CREDIT_BALANCE + loan.fixedInterestAmount);
        assertEq(collateral.balanceOf(borrower), COLLATERAL_AMOUNT);
    }

    function test_RevertWhen_CreateAlreadyMadeProposal() external {
        _createERC20Proposal();
        collateral.mint(borrower, proposal.collateralAmount);
        vm.prank(borrower);
        collateral.approve(address(spro), proposal.collateralAmount);

        vm.expectRevert(ISproErrors.ProposalAlreadyExists.selector);
        vm.prank(borrower);
        spro.createProposal(proposal, "");
    }

    function test_RevertWhen_getProposalCreditStatus_ProposalDoesNotExists() external {
        vm.expectRevert(ISproErrors.ProposalDoesNotExists.selector);
        spro.getProposalCreditStatus(proposal);
    }

    function test_RevertWhen_ProposalDoesNotExistsCancelProposal() external {
        vm.expectRevert(ISproErrors.ProposalDoesNotExists.selector);
        vm.prank(borrower);
        spro.cancelProposal(proposal);
    }

    function testFuzz_GetProposalCreditStatus(uint256 limit, uint256 used) external {
        vm.assume(limit != 0);
        vm.assume(used <= limit);

        proposal.availableCreditLimit = limit;
        _createERC20Proposal();

        bytes32 proposalHash = spro.getProposalHash(proposal);

        vm.store(address(spro), keccak256(abi.encode(proposalHash, 0)), bytes32(uint256(1)));
        vm.store(address(spro), keccak256(abi.encode(proposalHash, 1)), bytes32(used));

        (uint256 r, uint256 u) = spro.getProposalCreditStatus(proposal);

        assertEq(r, limit - u);
    }
}
