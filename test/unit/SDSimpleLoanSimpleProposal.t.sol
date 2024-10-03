// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";
import { PWNHubTags } from "pwn/hub/PWNHubTags.sol";
import {
    SDSimpleLoanSimpleProposal,
    SDSimpleLoanProposal,
    SDSimpleLoan
} from "pwn/loan/terms/simple/proposal/SDSimpleLoanSimpleProposal.sol";

contract SDSimpleLoanSimpleProposalHarness is SDSimpleLoanSimpleProposal {
    constructor(address _hub, address _revokedNonce, address _config)
        SDSimpleLoanSimpleProposal(_hub, _revokedNonce, _config)
    { }

    function exposed_checkCompleteLoan(uint256 _creditAmount, uint256 _availableCreditLimit) external pure {
        _checkCompleteLoan(_creditAmount, _availableCreditLimit);
    }
}

contract SDSimpleLoanSimpleProposalTest is Test {
    address public hub = makeAddr("hub");
    address public config = makeAddr("config");
    address public revokedNonce = makeAddr("revokedNonce");

    SDSimpleLoanSimpleProposalHarness harness;

    function setUp() public {
        harness = new SDSimpleLoanSimpleProposalHarness(hub, config, revokedNonce);
    }

    function testFuzz_encodeProposalData(address addr) external view {
        SDSimpleLoanSimpleProposal.Proposal memory proposal = SDSimpleLoanSimpleProposal.Proposal({
            collateralAddress: addr,
            collateralAmount: 1e20,
            checkCollateralStateFingerprint: false,
            collateralStateFingerprint: bytes32(0),
            creditAddress: addr,
            availableCreditLimit: 20e22,
            fixedInterestAmount: 1e14,
            accruingInterestAPR: 0,
            startTimestamp: uint40(block.timestamp),
            defaultTimestamp: uint40(block.timestamp) + 5 days,
            proposer: addr,
            proposerSpecHash: keccak256(abi.encode(addr)),
            nonceSpace: 0,
            nonce: 0,
            loanContract: addr
        });
        bytes memory x = abi.encode(proposal);
        assertEq(harness.encodeProposalData(proposal), x);
    }

    function testFuzz_shouldFail_partialLoan(uint256 a, uint256 l) external {
        vm.assume(a != l);

        vm.expectRevert(abi.encodeWithSelector(SDSimpleLoanSimpleProposal.OnlyCompleteLendingForNFTs.selector, a, l));
        harness.exposed_checkCompleteLoan(a, l);
    }
}
