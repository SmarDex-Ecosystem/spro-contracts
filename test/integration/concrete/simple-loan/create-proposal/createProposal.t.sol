// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import {
    SDBaseIntegrationTest,
    SDConfig,
    IPWNDeployer,
    SDSimpleLoan,
    SDSimpleLoanSimpleProposal,
    PWNLOAN,
    PWNRevokedNonce
} from "test/integration/SDBaseIntegrationTest.t.sol";

import { ISproErrors } from "src/interfaces/ISproErrors.sol";

contract CreateProposal_SDSimpleLoan_Integration_Concrete_Test is SDBaseIntegrationTest {
    modifier proposalContractHasTag() {
        _;
    }

    modifier whenValidProposalData() {
        _;
    }

    function test_RevertWhen_CallerIsNotProposer() external proposalContractHasTag whenValidProposalData {
        SDSimpleLoan.ProposalSpec memory proposalSpec = _buildProposalSpec(proposal);
        vm.expectRevert(abi.encodeWithSelector(ISproErrors.CallerIsNotStatedProposer.selector, borrower));
        deployment.simpleLoan.createProposal(proposalSpec);
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

        assertEq(t20.balanceOf(address(deployment.simpleLoan)), COLLATERAL_AMOUNT);
        assertEq(t20.balanceOf(borrower), 0);

        assertEq(deployment.sdex.balanceOf(address(deployment.config.SINK())), deployment.config.fixFeeUnlisted());
        assertEq(deployment.sdex.balanceOf(borrower), INITIAL_SDEX_BALANCE - deployment.config.fixFeeUnlisted());
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
        vm.startPrank(owner);
        deployment.config.setFixFeeListed(1e17);
        deployment.config.setVariableFactor(2e20);
        deployment.config.setListedToken(address(credit), 1e16);
        vm.stopPrank();

        // Create proposal
        _createERC20Proposal();

        assertEq(t20.balanceOf(address(deployment.simpleLoan)), COLLATERAL_AMOUNT);
        assertEq(t20.balanceOf(borrower), 0);

        uint256 lf = deployment.config.fixFeeListed();
        uint256 vf = deployment.config.variableFactor();
        uint256 tf = deployment.config.tokenFactors(address(credit));

        uint256 feeAmount = lf + (((vf * tf) / 1e18) * proposal.availableCreditLimit) / 1e18;

        assertEq(deployment.sdex.balanceOf(address(deployment.config.SINK())), feeAmount);
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
        proposal.defaultTimestamp = proposal.startTimestamp - 1;

        // Mint initial state & approve collateral
        t20.mint(borrower, proposal.collateralAmount);
        vm.prank(borrower);
        t20.approve(address(deployment.simpleLoan), proposal.collateralAmount);

        // Create the proposal
        SDSimpleLoan.ProposalSpec memory proposalSpec = _buildProposalSpec(proposal);

        vm.prank(borrower);
        vm.expectRevert(abi.encodeWithSelector(ISproErrors.InvalidDurationStartTime.selector));
        deployment.simpleLoan.createProposal(proposalSpec);
    }
}
