// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { SDBaseIntegrationTest } from "test/integration/SDBaseIntegrationTest.t.sol";

import { ISproErrors } from "src/interfaces/ISproErrors.sol";

contract CreateProposal_SDSimpleLoan_Integration_Concrete_Test is SDBaseIntegrationTest {
    modifier proposalContractHasTag() {
        _;
    }

    modifier whenValidProposalData() {
        _;
    }

    function test_RevertWhen_CallerIsNotProposer() external proposalContractHasTag whenValidProposalData {
        vm.expectRevert(abi.encodeWithSelector(ISproErrors.CallerIsNotStatedProposer.selector, borrower));
        deployment.config.createProposal(proposal, "");
    }

    modifier whenCallerIsProposer() {
        _;
    }

    modifier whenValidCollateral() {
        _;
    }

    modifier whenFeeAmountGtZero() {
        _;
    }

    function test_CreateProposal_ERC20_UnlistedFee()
        external
        proposalContractHasTag
        whenValidProposalData
        whenCallerIsProposer
        whenValidCollateral
        whenFeeAmountGtZero
    {
        _createERC20Proposal();

        assertEq(t20.balanceOf(address(deployment.config)), COLLATERAL_AMOUNT);
        assertEq(t20.balanceOf(borrower), 0);

        assertEq(deployment.sdex.balanceOf(address(0xdead)), deployment.config.fee());
        assertEq(deployment.sdex.balanceOf(borrower), INITIAL_SDEX_BALANCE - deployment.config.fee());
    }

    modifier whenListedFee() {
        _;
    }

    function test_createProposal_ERC20()
        external
        proposalContractHasTag
        whenValidProposalData
        whenCallerIsProposer
        whenValidCollateral
        whenFeeAmountGtZero
        whenListedFee
    {
        // Setup listed fee and token
        address owner = deployment.config.owner();
        uint256 feeAmount = 1e17;
        vm.startPrank(owner);
        deployment.config.setFee(feeAmount);
        vm.stopPrank();

        // Create proposal
        _createERC20Proposal();

        assertEq(t20.balanceOf(address(deployment.config)), COLLATERAL_AMOUNT);
        assertEq(t20.balanceOf(borrower), 0);

        assertEq(deployment.sdex.balanceOf(address(0xdead)), feeAmount);
        assertEq(deployment.sdex.balanceOf(borrower), INITIAL_SDEX_BALANCE - feeAmount);
    }

    function test_RevertWhen_InvalidDurationStartTime()
        external
        proposalContractHasTag
        whenValidProposalData
        whenCallerIsProposer
        whenValidCollateral
        whenFeeAmountGtZero
        whenListedFee
    {
        // Set bad timestamp value
        proposal.startTimestamp = uint40(block.timestamp);
        proposal.loanExpiration = proposal.startTimestamp - 1;

        // Mint initial state & approve collateral
        t20.mint(borrower, proposal.collateralAmount);
        vm.prank(borrower);
        t20.approve(address(deployment.config), proposal.collateralAmount);

        vm.prank(borrower);
        vm.expectRevert(abi.encodeWithSelector(ISproErrors.InvalidDurationStartTime.selector));
        deployment.config.createProposal(proposal, "");
    }
}
