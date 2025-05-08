// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import { Script } from "forge-std/Script.sol";
import { stdJson } from "forge-std/StdJson.sol";

contract ScriptUtils is Script {
    using stdJson for string;

    function _writeDeploymentAddress(address addr, string memory key) internal {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deployments/sdLatest.json");
        string memory ds = vm.toString(addr);
        vm.writeJson(ds, path, string.concat(".chains.", vm.toString(block.chainid), key));
    }
}
