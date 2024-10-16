// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IAllowanceTransfer } from "permit2/src/interfaces/IAllowanceTransfer.sol";

import { SproForkBase } from "test/integration/utils/Fixtures.sol";

contract SDSimpleLoanIntegrationTest is SproForkBase {
    function setUp() public {
        setUp();

        deal(address(deployment.config.SDEX()), address(this), 10 ether);
        deployment.config.SDEX().approve(address(deployment.permit2), type(uint256).max);
    }

    function test_permit2CreateLoan() public {
        IAllowanceTransfer.PermitDetails[] memory details = new IAllowanceTransfer.PermitDetails[](1);
        details[0] =
            IAllowanceTransfer.PermitDetails(address(deployment.config.SDEX()), uint160(5 ether), type(uint48).max, 0);
        IAllowanceTransfer.PermitBatch memory permitBatch =
            IAllowanceTransfer.PermitBatch(details, address(deployment.config), type(uint256).max);
        bytes memory signature = getPermitBatchSignature(permitBatch, 1, deployment.permit2.DOMAIN_SEPARATOR());
    }
}
