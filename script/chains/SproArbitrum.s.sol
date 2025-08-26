// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Script } from "forge-std/Script.sol";
import { Spro } from "src/spro/Spro.sol";
import { SproLoan } from "src/spro/SproLoan.sol";
import { DeploySpro } from "../Spro.s.sol";

contract Deploy is Script, DeploySpro {
    address constant SDEX_MAINNET = 0xabD587f2607542723b17f14d00d99b987C29b074;
    address constant OWNER_WALLET = 0x1F0214B6E2f7825C222B833dADD88B651628B085;
    uint256 constant ARBITRUM_CHAIN_ID = 42_161;

    function run() external returns (Spro spro_, SproLoan sproLoan_) {
        require(block.chainid == ARBITRUM_CHAIN_ID, "SproArbitrum: Must be deployed on Arbitrum network");

        (spro_, sproLoan_) = run(SDEX_MAINNET, OWNER_WALLET);
    }
}
