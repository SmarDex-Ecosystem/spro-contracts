// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import {
    MultiToken,
    MultiTokenCategoryRegistry,
    SDBaseIntegrationTest,
    SDConfig,
    IPWNDeployer,
    PWNHub,
    PWNHubTags,
    SDSimpleLoan,
    SDSimpleLoanSimpleProposal,
    PWNLOAN,
    PWNRevokedNonce
} from "test/integration/SDBaseIntegrationTest.t.sol";

import {SDSimpleLoanProposal} from "pwn/loan/terms/simple/proposal/SDSimpleLoanProposal.sol";
import {Expired, AddressMissingHubTag} from "pwn/PWNErrors.sol";

contract CreateProposal_SDSimpleLoan_Integration_Concrete_Test is SDBaseIntegrationTest {
    function test_RevertWhen_NoProposalLoanTag() external {
        // Remove LOAN_PROPOSAL tag for proposal contract
        address[] memory addrs = new address[](1);
        addrs[0] = address(deployment.simpleLoanSimpleProposal);
        bytes32[] memory tags = new bytes32[](1);
        tags[0] = PWNHubTags.LOAN_PROPOSAL;

        vm.prank(deployment.protocolAdmin);
        deployment.hub.setTags(addrs, tags, false);

        SDSimpleLoan.ProposalSpec memory proposalSpec = _buildProposalSpec(proposal);
        vm.prank(borrower);
        vm.expectRevert(
            abi.encodeWithSelector(
                AddressMissingHubTag.selector, address(deployment.simpleLoanSimpleProposal), PWNHubTags.LOAN_PROPOSAL
            )
        );
        deployment.simpleLoan.createProposal(proposalSpec);
    }

    modifier proposalContractHasTag() {
        _;
    }

    modifier whenValidProposalData() {
        _;
    }

    function test_RevertWhen_CallerIsNotProposer() external proposalContractHasTag whenValidProposalData {
        SDSimpleLoan.ProposalSpec memory proposalSpec = _buildProposalSpec(proposal);
        vm.expectRevert(abi.encodeWithSelector(SDSimpleLoan.CallerIsNotStatedProposer.selector, borrower));
        deployment.simpleLoan.createProposal(proposalSpec);
    }

    modifier whenCallerIsProposer() {
        _;
    }

    function test_RevertWhen_InvalidCollateral_ERC721()
        external
        proposalContractHasTag
        whenValidProposalData
        whenCallerIsProposer
    {
        // Adjust base proposal
        proposal.collateralCategory = MultiToken.Category.ERC721;
        proposal.collateralAddress = address(t721);
        proposal.collateralId = COLLATERAL_ID;
        proposal.collateralAmount = 2; // this is invalid

        // Mint initial state & approve collateral
        t721.mint(borrower, COLLATERAL_ID);
        vm.prank(borrower);
        t721.approve(address(deployment.simpleLoan), COLLATERAL_ID);

        // Create the proposal
        SDSimpleLoan.ProposalSpec memory proposalSpec = _buildProposalSpec(proposal);

        vm.prank(borrower);
        vm.expectRevert(
            abi.encodeWithSelector(
                SDSimpleLoan.InvalidMultiTokenAsset.selector,
                proposal.collateralCategory,
                proposal.collateralAddress,
                proposal.collateralId,
                proposal.collateralAmount
            )
        );
        deployment.simpleLoan.createProposal(proposalSpec);
    }

    function test_RevertWhen_InvalidCollateral_ERC1155()
        external
        proposalContractHasTag
        whenValidProposalData
        whenCallerIsProposer
    {
        // Adjust base proposal
        proposal.collateralCategory = MultiToken.Category.ERC1155;
        proposal.collateralAddress = address(t1155);
        proposal.collateralId = COLLATERAL_ID;
        proposal.collateralAmount = 0;

        // Mint initial state & approve collateral
        t1155.mint(borrower, COLLATERAL_ID, 1);
        vm.prank(borrower);
        t1155.setApprovalForAll(address(deployment.simpleLoan), true);

        // Create the proposal
        SDSimpleLoan.ProposalSpec memory proposalSpec = _buildProposalSpec(proposal);

        vm.prank(borrower);
        vm.expectRevert(
            abi.encodeWithSelector(
                SDSimpleLoan.InvalidMultiTokenAsset.selector,
                proposal.collateralCategory,
                proposal.collateralAddress,
                proposal.collateralId,
                proposal.collateralAmount
            )
        );
        deployment.simpleLoan.createProposal(proposalSpec);
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

        assertEq(deployment.sdex.balanceOf(address(deployment.sink)), deployment.config.unlistedFee());
        assertEq(deployment.sdex.balanceOf(borrower), INITIAL_SDEX_BALANCE - deployment.config.unlistedFee());
    }

    function test_CreateProposal_ERC721_UnlistedFee()
        external
        proposalContractHasTag
        whenValidProposalData
        whenCallerIsProposer
        whenValidCollateral
        whenFeeAmountGtZero
    {
        _createERC721Proposal();

        assertEq(t721.balanceOf(address(deployment.simpleLoan)), 1);
        assertEq(t721.balanceOf(borrower), 0);

        assertEq(deployment.sdex.balanceOf(address(deployment.sink)), deployment.config.unlistedFee());
        assertEq(deployment.sdex.balanceOf(borrower), INITIAL_SDEX_BALANCE - deployment.config.unlistedFee());
    }

    function test_CreateProposal_FungibleERC1155_UnlistedFee()
        external
        proposalContractHasTag
        whenValidProposalData
        whenCallerIsProposer
        whenValidCollateral
        whenFeeAmountGtZero
    {
        _createFungibleERC1155Proposal();

        assertEq(t1155.balanceOf(address(deployment.simpleLoan), COLLATERAL_ID), COLLATERAL_AMOUNT);
        assertEq(t1155.balanceOf(borrower, COLLATERAL_ID), 0);

        assertEq(deployment.sdex.balanceOf(address(deployment.sink)), deployment.config.unlistedFee());
        assertEq(deployment.sdex.balanceOf(borrower), INITIAL_SDEX_BALANCE - deployment.config.unlistedFee());
    }

    function test_CreateProposal_NonFungibleERC1155_UnlistedFee()
        external
        proposalContractHasTag
        whenValidProposalData
        whenCallerIsProposer
        whenValidCollateral
        whenFeeAmountGtZero
    {
        _createNonFungibleERC1155Proposal();

        assertEq(t1155.balanceOf(address(deployment.simpleLoan), COLLATERAL_ID), 1);
        assertEq(t1155.balanceOf(borrower, COLLATERAL_ID), 0);

        assertEq(deployment.sdex.balanceOf(address(deployment.sink)), deployment.config.unlistedFee());
        assertEq(deployment.sdex.balanceOf(borrower), INITIAL_SDEX_BALANCE - deployment.config.unlistedFee());
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
        deployment.config.setListedFee(1e17);
        deployment.config.setVariableFactor(2e20);
        deployment.config.setListedToken(address(credit), 1e16);
        vm.stopPrank();

        // Create proposal
        _createERC20Proposal();

        assertEq(t20.balanceOf(address(deployment.simpleLoan)), COLLATERAL_AMOUNT);
        assertEq(t20.balanceOf(borrower), 0);

        uint256 lf = deployment.config.listedFee();
        uint256 vf = deployment.config.variableFactor();
        uint256 tf = deployment.config.tokenFactors(address(credit));

        uint256 feeAmount = lf + (((vf * tf) / 1e18) * proposal.availableCreditLimit) / 1e18;

        assertEq(deployment.sdex.balanceOf(address(deployment.sink)), feeAmount);
        assertEq(deployment.sdex.balanceOf(borrower), INITIAL_SDEX_BALANCE - feeAmount);
    }
}
