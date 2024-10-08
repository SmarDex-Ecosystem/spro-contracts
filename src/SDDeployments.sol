// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { stdJson } from "forge-std/StdJson.sol";
import { CommonBase } from "forge-std/Base.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { Spro } from "src/spro/Spro.sol";
import { IPWNDeployer } from "src/interfaces/IPWNDeployer.sol";
import { SproLOAN } from "src/spro/SproLOAN.sol";
import { PWNRevokedNonce } from "src/spro/PWNRevokedNonce.sol";
import { T20 } from "test/helper/T20.sol";

abstract contract SDDeployments is CommonBase {
    using stdJson for string;
    using Strings for uint256;

    string public deploymentsSubpath;

    uint256[] deployedChains;
    Deployment deployment;

    // Properties need to be in alphabetical order
    struct Deployment {
        Spro config;
        IPWNDeployer deployer;
        SproLOAN loanToken;
        address proxyAdmin;
        address protocolAdmin;
        PWNRevokedNonce revokedNonce;
        T20 sdex;
    }

    function _loadDeployedAddresses() internal {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, deploymentsSubpath, "/deployments/sdLatest.json");
        string memory json = vm.readFile(path);
        bytes memory rawDeployedChains = json.parseRaw(".deployedChains");
        deployedChains = abi.decode(rawDeployedChains, (uint256[]));

        if (_contains(deployedChains, block.chainid)) {
            bytes memory rawDeployment = json.parseRaw(string.concat(".chains.", block.chainid.toString()));
            deployment = abi.decode(rawDeployment, (Deployment));
        } else {
            _protocolNotDeployedOnSelectedChain();
        }
    }

    function _contains(uint256[] storage array, uint256 value) private view returns (bool) {
        for (uint256 i; i < array.length; ++i) {
            if (array[i] == value) return true;
        }

        return false;
    }

    function _protocolNotDeployedOnSelectedChain() internal virtual {
        // Override
    }
}
