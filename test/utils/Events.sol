// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import {
    SDDeploymentTest,
    SDConfig,
    IPWNDeployer,
    PWNHub,
    PWNHubTags,
    SDSimpleLoan,
    SDSimpleLoanSimpleProposal,
    PWNLOAN,
    PWNRevokedNonce
} from "test/SDDeploymentTest.t.sol";

abstract contract Events {
    event ProposalMade(
        bytes32 indexed proposalHash, address indexed proposer, SDSimpleLoanSimpleProposal.Proposal proposal
    );

    event LOANCreated(
        uint256 indexed loanId,
        bytes32 indexed proposalHash,
        address indexed proposalContract,
        SDSimpleLoan.Terms terms,
        SDSimpleLoan.LenderSpec lenderSpec,
        bytes extra
    );

    event LOANPaidBack(uint256 indexed loanId);

    event LOANClaimed(uint256 indexed loanId, bool indexed defaulted);
}
