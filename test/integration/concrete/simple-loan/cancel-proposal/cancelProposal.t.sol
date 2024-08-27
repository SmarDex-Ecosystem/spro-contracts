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
import {SDSimpleLoanProposal} from "pwn/loan/terms/simple/proposal/SDSimpleLoanProposal.sol";
import {Expired, AddressMissingHubTag} from "pwn/PWNErrors.sol";

contract CancelProposal_SDSimpleLoan_Integration_Concrete_Test is SDBaseIntegrationTest {
    function test_RevertWhen_NoProposalLoanTag() external {
        _createERC20Proposal();

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
        deployment.simpleLoan.cancelProposal(proposalSpec);
    }

    modifier proposalContractHasTag() {
        _;
    }

    function test_RevertWhen_CallerNotProposer() external proposalContractHasTag {
        _createERC20Proposal();
        SDSimpleLoan.ProposalSpec memory proposalSpec = _buildProposalSpec(proposal);
        vm.expectRevert(SDSimpleLoan.CallerNotProposer.selector);
        deployment.simpleLoan.cancelProposal(proposalSpec);
    }

    modifier whenCallerIsProposer() {
        _;
    }

    modifier whenERC721Collateral() {
        _;
    }

    modifier whenCollateralLoanedAgainst() {
        _;
    }

    function test_RevertWhen_WithdrawableCollateralInvalid_ERC721()
        external
        proposalContractHasTag
        whenCallerIsProposer
        whenERC721Collateral
        whenCollateralLoanedAgainst
    {
        _createERC721Proposal();
        SDSimpleLoan.ProposalSpec memory proposalSpec = _buildProposalSpec(proposal);
        _createLoan(proposalSpec, "");

        vm.prank(borrower);
        vm.expectRevert(
            abi.encodeWithSelector(
                SDSimpleLoan.InvalidMultiTokenAsset.selector,
                uint8(proposal.collateralCategory),
                proposal.collateralAddress,
                proposal.collateralId,
                type(uint256).max
            )
        );
        deployment.simpleLoan.cancelProposal(proposalSpec);
    }

    modifier whenNonFungibleERC1155Collateral() {
        _;
    }

    function test_RevertWhen_WithdrawableCollateralInvalid_ERC1155()
        external
        proposalContractHasTag
        whenCallerIsProposer
        whenNonFungibleERC1155Collateral
        whenCollateralLoanedAgainst
    {
        _createNonFungibleERC1155Proposal();
        SDSimpleLoan.ProposalSpec memory proposalSpec = _buildProposalSpec(proposal);
        _createLoan(proposalSpec, "");

        vm.prank(borrower);
        vm.expectRevert(
            abi.encodeWithSelector(
                SDSimpleLoan.InvalidMultiTokenAsset.selector,
                uint8(proposal.collateralCategory),
                proposal.collateralAddress,
                proposal.collateralId,
                0
            )
        );
        deployment.simpleLoan.cancelProposal(proposalSpec);
    }
}
