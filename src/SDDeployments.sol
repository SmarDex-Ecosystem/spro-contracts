// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import {stdJson} from "forge-std/src/StdJson.sol";
import {CommonBase} from "forge-std/src/Base.sol";

import {MultiTokenCategoryRegistry} from "MultiToken/MultiTokenCategoryRegistry.sol";

import {Strings} from "openzeppelin/utils/Strings.sol";

import {SDConfig} from "pwn/config/SDConfig.sol";
import {PWNHub} from "pwn/hub/PWNHub.sol";
import {PWNHubTags} from "pwn/hub/PWNHubTags.sol";
import {IPWNDeployer} from "pwn/interfaces/IPWNDeployer.sol";
import {SDSimpleLoan} from "pwn/loan/terms/simple/loan/SDSimpleLoan.sol";
import {SDSimpleLoanSimpleProposal} from "pwn/loan/terms/simple/proposal/SDSimpleLoanSimpleProposal.sol";
import {PWNLOAN} from "pwn/loan/token/PWNLOAN.sol";
import {PWNRevokedNonce} from "pwn/nonce/PWNRevokedNonce.sol";
import {T20} from "test/helper/T20.sol";
import {SDSink} from "pwn/SDSink.sol";

abstract contract SDDeployments is CommonBase {
    using stdJson for string;
    using Strings for uint256;

    string public deploymentsSubpath;

    uint256[] deployedChains;
    Deployment deployment;

    // Properties need to be in alphabetical order
    struct Deployment {
        MultiTokenCategoryRegistry categoryRegistry;
        SDConfig config;
        SDConfig configSingleton;
        IPWNDeployer deployer;
        PWNHub hub;
        PWNLOAN loanToken;
        address proxyAdmin;
        address protocolAdmin;
        PWNRevokedNonce revokedNonce;
        T20 sdex;
        SDSimpleLoan simpleLoan;
        SDSimpleLoanSimpleProposal simpleLoanSimpleProposal;
        SDSink sink;
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
