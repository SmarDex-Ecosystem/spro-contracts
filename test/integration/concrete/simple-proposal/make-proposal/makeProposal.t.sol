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

import { SDSimpleLoanSimpleProposal } from "spro/SDSimpleLoanSimpleProposal.sol";
import { AddressMissingHubTag } from "src/PWNErrors.sol";

contract MakeProposal_SDSimpleLoanSimpleProposal_Integration_Concrete_Test is SDBaseIntegrationTest {
    function test_RevertWhen_DataCannotBeDecoded() external {
        bytes memory badData = abi.encode("cannot be decoded");

        vm.expectRevert();
        deployment.simpleLoanSimpleProposal.makeProposal(badData);

        bytes memory baseProposalData = abi.encode(
            SDSimpleLoanSimpleProposal.ProposalBase({
                collateralAddress: address(t20),
                checkCollateralStateFingerprint: false,
                collateralStateFingerprint: bytes32(0),
                availableCreditLimit: CREDIT_LIMIT,
                startTimestamp: uint40(block.timestamp + 5 days),
                proposer: borrower,
                nonceSpace: 0,
                nonce: 0,
                loanContract: address(deployment.simpleLoan)
            })
        );

        vm.expectRevert();
        deployment.simpleLoanSimpleProposal.makeProposal(baseProposalData);
    }

    modifier whenProposalDataDecodes() {
        _;
    }

    modifier loanContractIsCaller() {
        _;
    }

    modifier loanContractHasActiveLoanTag() {
        _;
    }

    function test_makeProposal() external whenProposalDataDecodes loanContractIsCaller loanContractHasActiveLoanTag {
        bytes32 proposalHash = deployment.simpleLoanSimpleProposal.getProposalHash(proposal);

        // Emit event
        vm.expectEmit(true, true, true, false);
        emit SDSimpleLoanSimpleProposal.ProposalMade(proposalHash, proposal.proposer, proposal);

        vm.prank(proposal.loanContract);
        deployment.simpleLoanSimpleProposal.makeProposal(abi.encode(proposal));

        // Assert that the proposalMade mapping for this proposal was set
        uint256 proposalMadeBool = uint256(
            vm.load(
                address(deployment.simpleLoanSimpleProposal), keccak256(abi.encode(proposalHash, SLOT_PROPOSALS_MADE))
            )
        );
        assertEq(proposalMadeBool, 1, "proposalMade not set");
        assertEq(deployment.simpleLoanSimpleProposal.proposalsMade(proposalHash), true, "proposalMade not set");
    }
}
