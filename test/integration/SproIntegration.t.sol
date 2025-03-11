// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import { SDBaseIntegrationTest } from "test/integration/utils/Fixtures.sol";

import { ISproErrors } from "src/interfaces/ISproErrors.sol";
import { SproConstantsLibrary as Constants } from "src/libraries/SproConstantsLibrary.sol";
import { ISproTypes } from "src/interfaces/ISproTypes.sol";
import { Spro } from "src/spro/Spro.sol";

contract TestSproIntegration is SDBaseIntegrationTest {
    function setUp() public {
        _setUp(false);
    }

    /* -------------------------------------------------------------------------- */
    /*                               CREATE PROPOSAL                              */
    /* -------------------------------------------------------------------------- */

    function test_createProposal() external {
        // Setup listed fee and token
        address owner = deployment.config.owner();
        uint256 feeAmount = 1e17;
        vm.startPrank(owner);
        deployment.config.setFee(feeAmount);
        vm.stopPrank();

        // Create proposal
        _createERC20Proposal();

        assertEq(t20.balanceOf(address(deployment.config)), COLLATERAL_AMOUNT);
        assertEq(deployment.sdex.balanceOf(address(0xdead)), deployment.config._fee());
        assertEq(t20.balanceOf(borrower), 0);

        assertEq(deployment.sdex.balanceOf(address(0xdead)), feeAmount);
        assertEq(deployment.sdex.balanceOf(borrower), INITIAL_SDEX_BALANCE - feeAmount);
        assertEq(deployment.sdex.balanceOf(borrower), INITIAL_SDEX_BALANCE - deployment.config._fee());
    }

    function test_RevertWhen_AvailableCreditLimitZero() public {
        proposal.availableCreditLimit = 0;
        vm.expectRevert(abi.encodeWithSelector(ISproErrors.AvailableCreditLimitZero.selector));
        vm.prank(borrower);
        deployment.config.createProposal(proposal, "");
    }

    function test_RevertWhen_InvalidDurationStartTime() external {
        // Set bad timestamp value
        proposal.startTimestamp = uint40(block.timestamp);
        proposal.loanExpiration = proposal.startTimestamp;

        // Mint initial state & approve collateral
        t20.mint(borrower, proposal.collateralAmount);
        vm.prank(borrower);
        t20.approve(address(deployment.config), proposal.collateralAmount);

        vm.prank(borrower);
        vm.expectRevert(abi.encodeWithSelector(ISproErrors.InvalidDurationStartTime.selector));
        deployment.config.createProposal(proposal, "");
    }

    function test_RevertWhen_InvalidLoanDuration() external {
        // Set bad timestamp value
        uint256 minDuration = Constants.MIN_LOAN_DURATION;
        proposal.loanExpiration = proposal.startTimestamp + uint32(minDuration - 1);

        // Mint initial state & approve collateral
        t20.mint(borrower, proposal.collateralAmount);
        vm.prank(borrower);
        t20.approve(address(deployment.config), proposal.collateralAmount);

        vm.prank(borrower);
        vm.expectRevert(
            abi.encodeWithSelector(
                ISproErrors.InvalidDuration.selector, proposal.loanExpiration - proposal.startTimestamp, minDuration
            )
        );
        deployment.config.createProposal(proposal, "");
    }

    /* -------------------------------------------------------------------------- */
    /*                               CANCEL PROPOSAL                              */
    /* -------------------------------------------------------------------------- */

    function test_RevertWhen_CallerNotProposer() external {
        _createERC20Proposal();
        vm.expectRevert(ISproErrors.CallerNotProposer.selector);
        deployment.config.cancelProposal(proposal);
    }

    /* -------------------------------------------------------------------------- */
    /*                                 CREATE LOAN                                */
    /* -------------------------------------------------------------------------- */

    function test_CreateLoan() external {
        _createERC20Proposal();

        vm.startPrank(lender);
        credit.mint(lender, INITIAL_CREDIT_BALANCE);
        credit.approve(address(deployment.config), CREDIT_LIMIT);

        uint256 id = deployment.config.createLoan(proposal, CREDIT_LIMIT, "");
        vm.stopPrank();

        assertEq(deployment.loanToken.ownerOf(id), lender);
        assertEq(deployment.sdex.balanceOf(address(0xdead)), deployment.config._fee());
        assertEq(deployment.sdex.balanceOf(borrower), INITIAL_SDEX_BALANCE - deployment.config._fee());
        assertEq(deployment.sdex.balanceOf(lender), INITIAL_SDEX_BALANCE);

        (Spro.Loan memory loanInfo,,) = deployment.config.getLoan(id);
        assertTrue(loanInfo.status == ISproTypes.LoanStatus.RUNNING);

        assertEq(credit.balanceOf(lender), INITIAL_CREDIT_BALANCE - CREDIT_LIMIT);
        assertEq(credit.balanceOf(borrower), CREDIT_LIMIT);
    }

    function test_RevertWhen_proposalNotMade() external {
        vm.expectRevert(ISproErrors.ProposalNotMade.selector);
        deployment.config.createLoan(proposal, CREDIT_LIMIT, "");
    }

    function test_RevertWhen_proposerIsAcceptor() external {
        _createERC20Proposal();
        vm.prank(proposal.proposer);
        vm.expectRevert(abi.encodeWithSelector(ISproErrors.AcceptorIsProposer.selector, proposal.proposer));
        deployment.config.createLoan(proposal, CREDIT_LIMIT, "");
    }

    function test_RevertWhen_proposalExpired() external {
        _createERC20Proposal();
        vm.warp(proposal.startTimestamp);
        vm.expectRevert(abi.encodeWithSelector(ISproErrors.Expired.selector, block.timestamp, proposal.startTimestamp));
        deployment.config.createLoan(proposal, CREDIT_LIMIT, "");
    }

    function test_RevertWhen_availableCreditExceeded() external {
        _createERC20Proposal();
        vm.expectRevert(
            abi.encodeWithSelector(ISproErrors.AvailableCreditLimitExceeded.selector, CREDIT_LIMIT + 1, CREDIT_LIMIT)
        );
        deployment.config.createLoan(proposal, CREDIT_LIMIT + 1, "");
    }
}
