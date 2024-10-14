// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";
import { T20 } from "test/helper/T20.sol";

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { Spro } from "src/spro/Spro.sol";
import { SproLOAN } from "src/spro/SproLOAN.sol";
import { SproRevokedNonce } from "src/spro/SproRevokedNonce.sol";

abstract contract SDDeploymentTest is Test {
    uint256 public constant UNLISTED_FEE = 50e18;
    uint256 public constant LISTED_FEE = 20e18;
    uint256 public constant VARIABLE_FACTOR = 1e13;
    uint16 public constant PARTIAL_POSITION_PERCENTAGE = 500;

    string public deploymentsSubpath;

    uint256[] deployedChains;
    Deployment deployment;

    // Properties need to be in alphabetical order
    struct Deployment {
        Spro config;
        SproLOAN loanToken;
        address proxyAdmin;
        address protocolAdmin;
        SproRevokedNonce revokedNonce;
        T20 sdex;
    }

    function setUp() public virtual {
        deployment.proxyAdmin = makeAddr("proxyAdmin");
        deployment.protocolAdmin = address(this);

        // Deploy SDEX token
        deployment.sdex = new T20();

        vm.startPrank(deployment.protocolAdmin);

        // Deploy protocol
        deployment.config =
            new Spro(address(deployment.sdex), UNLISTED_FEE, LISTED_FEE, VARIABLE_FACTOR, PARTIAL_POSITION_PERCENTAGE);
        vm.stopPrank();
        deployment.revokedNonce = deployment.config.revokedNonce();
        deployment.loanToken = deployment.config.loanToken();

        // Labels
        vm.label(deployment.proxyAdmin, "proxyAdmin");
        vm.label(deployment.protocolAdmin, "protocolAdmin");
        vm.label(address(deployment.sdex), "sdex");
        vm.label(address(deployment.config), "config");
        vm.label(address(deployment.revokedNonce), "revokedNonce");
        vm.label(address(deployment.loanToken), "loanToken");
    }
}
