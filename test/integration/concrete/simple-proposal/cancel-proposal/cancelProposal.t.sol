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

contract CancelProposal_SDSimpleLoanSimpleProposal_Integration_Concrete_Test is SDBaseIntegrationTest {
    function test_RevertWhen_DataCannotBeDecoded() external {
        bytes memory badData = abi.encode("cannot be decoded");

        vm.expectRevert();
        deployment.simpleLoanSimpleProposal.cancelProposal(badData);

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
        deployment.simpleLoanSimpleProposal.cancelProposal(baseProposalData);
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

    function test_CancelProposal() external whenProposalDataDecodes loanContractIsCaller loanContractHasActiveLoanTag {
        _createERC20Proposal();

        vm.prank(proposal.loanContract);
        (address proposer, address collateral, uint256 collateralAmount) =
            deployment.simpleLoanSimpleProposal.cancelProposal(abi.encode(proposal));

        assertEq(proposer, borrower);
        assertEq(collateral, address(t20));
        assertEq(collateralAmount, COLLATERAL_AMOUNT);

        // Assert that the withdrawable collateral was set
        bytes32 proposalHash = deployment.simpleLoanSimpleProposal.getProposalHash(proposal);
        bytes32 slot = keccak256(abi.encode(proposalHash, SLOT_WITHDRAWABLE_COLLATERAL));
        bytes32 wc = vm.load(address(deployment.simpleLoanSimpleProposal), slot);
        assertEq(uint8(uint256(wc << 80 >> 248)), 0);
        assertEq(
            address(uint160(uint256(wc << 88 >> 96))), address(0), "withdrawableCollateral: collateral address not set"
        );
        assertEq(
            uint256(vm.load(address(deployment.simpleLoanSimpleProposal), bytes32(uint256(slot) + 1))),
            0,
            "withdrawableCollateral: collateral id not set"
        );
        assertEq(
            uint256(vm.load(address(deployment.simpleLoanSimpleProposal), bytes32(uint256(slot) + 2))),
            0,
            "withdrawableCollateral: collateral amount not set"
        );

        assertEq(
            deployment.revokedNonce.isNonceUsable(borrower, proposal.nonceSpace, proposal.nonce),
            false,
            "nonce should not be usable"
        );
    }
}
