// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Script } from "forge-std/Script.sol";
import { Spro } from "src/spro/Spro.sol";
import { SproLoan } from "src/spro/SproLoan.sol";
import { DeploySpro } from "../Spro.s.sol";

contract Deploy is Script, DeploySpro {
    address constant SDEX_MAINNET = 0x5DE8ab7E27f6E7A1fFf3E5B337584Aa43961BEeF;
    address constant OWNER_WALLET = 0x1F0214B6E2f7825C222B833dADD88B651628B085;
    uint256 constant MAINNET_CHAIN_ID = 1;

    function run() external returns (Spro spro_, SproLoan sproLoan_) {
        require(block.chainid == MAINNET_CHAIN_ID, "SproMainnet: Must be deployed on Mainnet network");

        (spro_, sproLoan_) = run(SDEX_MAINNET, OWNER_WALLET);
    }
}
