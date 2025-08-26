// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Spro } from "src/spro/Spro.sol";
import { SproLoan } from "src/spro/SproLoan.sol";
import { DeploySpro } from "../Spro.s.sol";

contract DeployMainnet is DeploySpro {
    address constant SDEX_MAINNET = 0x5DE8ab7E27f6E7A1fFf3E5B337584Aa43961BEeF;
    address constant OWNER_WALLET = 0x1E3e1128F6bC2264a19D7a065982696d356879c5;
    uint256 constant MAINNET_CHAIN_ID = 1;

    function run() external returns (Spro spro_, SproLoan sproLoan_) {
        require(block.chainid == MAINNET_CHAIN_ID, "SproMainnet script: Must be deployed on Mainnet network");

        (spro_, sproLoan_) = run(SDEX_MAINNET, OWNER_WALLET);
    }
}
