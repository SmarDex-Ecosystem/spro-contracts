// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";
import { T20 } from "test/helper/T20.sol";

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { SDDeployments, Spro, IPWNDeployer, SproLOAN, SproRevokedNonce } from "src/SDDeployments.sol";

abstract contract SDDeploymentTest is SDDeployments, Test {
    uint256 public constant UNLISTED_FEE = 50e18;
    uint256 public constant LISTED_FEE = 20e18;
    uint256 public constant VARIABLE_FACTOR = 1e13;
    uint16 public constant PARTIAL_POSITION_PERCENTAGE = 500;

    function setUp() public virtual {
        // _loadDeployedAddresses();
        _protocolNotDeployedOnSelectedChain(); // @note keep this until block.chainid == 31337 removed from
            // sdLatest.json, or deployments JSON pointed elsewhere

        // Labels
        vm.label(deployment.proxyAdmin, "proxyAdmin");
        vm.label(deployment.protocolAdmin, "protocolAdmin");
        vm.label(address(deployment.sdex), "sdex");
        vm.label(address(deployment.config), "config");
        vm.label(address(deployment.revokedNonce), "revokedNonce");
        vm.label(address(deployment.loanToken), "loanToken");
    }

    function _protocolNotDeployedOnSelectedChain() internal override {
        deployment.proxyAdmin = makeAddr("proxyAdmin");
        deployment.protocolAdmin = makeAddr("protocolAdmin");

        // Deploy SDEX token
        deployment.sdex = new T20();

        vm.startPrank(deployment.protocolAdmin);

        // Deploy protocol
        deployment.config = new Spro(
            address(deployment.sdex),
            deployment.protocolAdmin,
            UNLISTED_FEE,
            LISTED_FEE,
            VARIABLE_FACTOR,
            PARTIAL_POSITION_PERCENTAGE
        );
        vm.stopPrank();
        deployment.revokedNonce = deployment.config.revokedNonce();
        deployment.loanToken = deployment.config.loanToken();
    }
}
