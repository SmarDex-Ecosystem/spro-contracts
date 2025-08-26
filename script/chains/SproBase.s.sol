// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Spro } from "src/spro/Spro.sol";
import { SproLoan } from "src/spro/SproLoan.sol";
import { DeploySpro } from "../Spro.s.sol";

contract Deploy is DeploySpro {
    address constant SDEX = 0xFd4330b0312fdEEC6d4225075b82E00493FF2e3f;
    address constant OWNER_WALLET = 0x1F0214B6E2f7825C222B833dADD88B651628B085;
    uint256 constant BASE_CHAIN_ID = 8453;

    function run() external returns (Spro spro_, SproLoan sproLoan_) {
        require(block.chainid == BASE_CHAIN_ID, "SproBase script: Must be deployed on Base network");

        (spro_, sproLoan_) = run(SDEX, OWNER_WALLET);
    }
}
