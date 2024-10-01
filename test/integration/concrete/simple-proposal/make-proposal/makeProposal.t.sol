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
import {AddressMissingHubTag} from "pwn/PWNErrors.sol";

contract MakeProposal_SDSimpleLoanSimpleProposal_Integration_Concrete_Test is SDBaseIntegrationTest {
    function test_RevertWhen_DataCannotBeDecoded() external {
        bytes memory badData = abi.encode("cannot be decoded");

        vm.expectRevert();
        deployment.simpleLoanSimpleProposal.makeProposal(badData);

        bytes memory baseProposalData = abi.encode(
            SDSimpleLoanProposal.ProposalBase({
                collateralAddress: address(t20),
                collateralId: 0,
                checkCollateralStateFingerprint: false,
                collateralStateFingerprint: bytes32(0),
                availableCreditLimit: CREDIT_LIMIT,
                expiration: uint40(block.timestamp + 5 days),
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

    function test_RevertWhen_CallerNotLoanContract() external whenProposalDataDecodes {
        vm.expectRevert(
            abi.encodeWithSelector(
                SDSimpleLoanProposal.CallerNotLoanContract.selector, address(this), proposal.loanContract
            )
        );
        deployment.simpleLoanSimpleProposal.makeProposal(abi.encode(proposal));
    }

    modifier loanContractIsCaller() {
        _;
    }

    function test_RevertWhen_LoanContractNotActiveLoanTag() external whenProposalDataDecodes loanContractIsCaller {
        vm.prank(deployment.hub.owner());
        deployment.hub.setTag(proposal.loanContract, PWNHubTags.ACTIVE_LOAN, false);

        vm.expectRevert(
            abi.encodeWithSelector(AddressMissingHubTag.selector, proposal.loanContract, PWNHubTags.ACTIVE_LOAN)
        );
        vm.prank(proposal.loanContract);
        deployment.simpleLoanSimpleProposal.makeProposal(abi.encode(proposal));
    }

    modifier loanContractHasActiveLoanTag() {
        _;
    }

    function test_makeProposal() external whenProposalDataDecodes loanContractIsCaller loanContractHasActiveLoanTag {
        bytes32 proposalHash = deployment.simpleLoanSimpleProposal.getProposalHash(proposal);

        // Emit event
        vm.expectEmit(true, true, true, false);
        emit ProposalMade(proposalHash, proposal.proposer, proposal);

        vm.prank(proposal.loanContract);
        deployment.simpleLoanSimpleProposal.makeProposal(abi.encode(proposal));

        // Assert that the proposalMade mapping for this proposal was set
        uint256 proposalMadeBool = uint256(
            vm.load(
                address(deployment.simpleLoanSimpleProposal), keccak256(abi.encode(proposalHash, SLOT_PROPOSALS_MADE))
            )
        );
        assertEq(proposalMadeBool, 1, "proposalMade not set");

        // Assert that the withdrawable collateral was set
        bytes32 slot = keccak256(abi.encode(proposalHash, SLOT_WITHDRAWABLE_COLLATERAL));
        bytes32 wc = vm.load(address(deployment.simpleLoanSimpleProposal), slot);
        assertEq(uint8(uint256(wc << 80 >> 248)), 0);
        assertEq(
            address(uint160(uint256(wc << 88 >> 96))),
            proposal.collateralAddress,
            "withdrawableCollateral: collateral address not set"
        );
        assertEq(
            uint256(vm.load(address(deployment.simpleLoanSimpleProposal), bytes32(uint256(slot) + 1))),
            proposal.collateralId,
            "withdrawableCollateral: collateral id not set"
        );
        assertEq(
            uint256(vm.load(address(deployment.simpleLoanSimpleProposal), bytes32(uint256(slot) + 2))),
            proposal.collateralAmount,
            "withdrawableCollateral: collateral amount not set"
        );
    }
}
