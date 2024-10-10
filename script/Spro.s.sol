// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Script } from "forge-std/Script.sol";
import { Spro } from "src/spro/Spro.sol";
import { console } from "forge-std/Script.sol";

contract Deploy is Script {
    address constant SDEX_MAINNET = 0x5DE8ab7E27f6E7A1fFf3E5B337584Aa43961BEeF;
    uint256 internal constant FIX_FEE_UNLISTED = 50e18;
    uint256 internal constant FIX_FEE_LISTED = 30e18;
    uint256 internal constant VARIABLE_FACTOR = 1e16;
    uint16 internal constant PERCENTAGE = 500;

    function run() external {
        address deployerAddress = vm.envAddress("DEPLOYER_ADDRESS");
        vm.startBroadcast(deployerAddress);

        Spro spro = new Spro(SDEX_MAINNET, FIX_FEE_UNLISTED, FIX_FEE_LISTED, VARIABLE_FACTOR, PERCENTAGE);

        console.log("Spro address", address(spro));
        console.log("revokedNonce address", address(spro.revokedNonce()));
        console.log("loanToken address", address(spro.loanToken()));

        vm.stopBroadcast();
    }
}
