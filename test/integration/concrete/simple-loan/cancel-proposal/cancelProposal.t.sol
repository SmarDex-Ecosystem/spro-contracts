// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { SDBaseIntegrationTest, Spro } from "test/integration/SDBaseIntegrationTest.t.sol";

import { ISproErrors } from "src/interfaces/ISproErrors.sol";

contract CancelProposal_SDSimpleLoan_Integration_Concrete_Test is SDBaseIntegrationTest {
    modifier proposalContractHasTag() {
        _;
    }

    function test_RevertWhen_CallerNotProposer() external proposalContractHasTag {
        _createERC20Proposal();
        vm.expectRevert(ISproErrors.CallerNotProposer.selector);
        deployment.config.cancelProposal(proposal);
    }
}
