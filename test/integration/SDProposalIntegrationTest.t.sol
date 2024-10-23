// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { SDBaseIntegrationTest } from "test/integration/SDBaseIntegrationTest.t.sol";

import { ISproErrors } from "src/interfaces/ISproErrors.sol";

contract SDProposalIntegrationTest is SDBaseIntegrationTest {
    function test_RevertWhen_AvailableCreditLimitZero() public {
        proposal.availableCreditLimit = 0;

        vm.expectRevert(abi.encodeWithSelector(ISproErrors.AvailableCreditLimitZero.selector));
        vm.prank(borrower);
        deployment.config.createProposal(proposal, "");
    }
}
