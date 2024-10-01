// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { console2 } from "forge-std/Script.sol";
import { ScriptUtils } from "./lib/ScriptUtils.sol";

import { SDDeployer } from "pwn/deployment/SDDeployer.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

import { T20 } from "test/helper/T20.sol";

contract Deploy is ScriptUtils {
    /*//////////////////////////////////////////////////////////////////////////
                                  DEPLOYER
    //////////////////////////////////////////////////////////////////////////*/

    // local deployment:
    // forge script script/SDDeployer.s.sol:Deploy --sig "deployDeployer()" --rpc-url $LOCAL_URL --private-key
    // $PRIVATE_KEY --broadcast

    bytes32 internal constant DEPLOYER = keccak256("SDDeployer");

    function deployDeployer() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(pk);

        address deployer =
            Create2.deploy(0, DEPLOYER, abi.encodePacked(type(SDDeployer).creationCode, abi.encode(vm.addr(pk))));

        vm.stopBroadcast();

        console2.log("SDDeployer address", deployer);

        _writeDeploymentAddress(deployer, ".deployer");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  FOR LOCAL DEVELOPMENT ONLY - SDEX
    //////////////////////////////////////////////////////////////////////////*/

    bytes32 internal constant SDEX = keccak256("SDEX");

    // local deployment:
    // forge script script/SDDeployer.s.sol:Deploy --sig "deploySDEX()" --rpc-url $LOCAL_URL --private-key $PRIVATE_KEY
    // --broadcast

    function deploySDEX() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(pk);

        address sdex = Create2.deploy(0, SDEX, type(T20).creationCode);

        vm.stopBroadcast();

        console2.log("SDEX address", sdex);

        _writeDeploymentAddress(sdex, ".sdex");
    }
}
