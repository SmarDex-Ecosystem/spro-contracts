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

import { Expired, AddressMissingHubTag } from "src/PWNErrors.sol";

contract CancelProposal_SDSimpleLoan_Integration_Concrete_Test is SDBaseIntegrationTest {
    function test_RevertWhen_NoProposalLoanTag() external {
        _createERC20Proposal();

        // Remove LOAN_PROPOSAL tag for proposal contract
        address[] memory addrs = new address[](1);
        addrs[0] = address(deployment.simpleLoanSimpleProposal);

        SDSimpleLoan.ProposalSpec memory proposalSpec = _buildProposalSpec(proposal);

        vm.prank(borrower);
        vm.expectRevert(
            abi.encodeWithSelector(AddressMissingHubTag.selector, address(deployment.simpleLoanSimpleProposal))
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
}
