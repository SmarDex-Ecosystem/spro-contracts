// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";
import { T20 } from "test/helper/T20.sol";

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { Spro } from "src/spro/Spro.sol";
import { SproLoan } from "src/spro/SproLoan.sol";

abstract contract SDDeploymentTest is Test {
    uint256 public constant FEE = 50e18;
    uint16 public constant PARTIAL_POSITION_PERCENTAGE = 500;

    string public deploymentsSubpath;

    uint256[] deployedChains;
    Deployment deployment;

    // Properties need to be in alphabetical order
    struct Deployment {
        Spro config;
        SproLoan loanToken;
        address proxyAdmin;
        address protocolAdmin;
        T20 sdex;
    }

    function setUp() public virtual {
        deployment.proxyAdmin = makeAddr("proxyAdmin");
        deployment.protocolAdmin = address(this);

        // Deploy SDEX token
        deployment.sdex = new T20();

        vm.startPrank(deployment.protocolAdmin);

        // Deploy protocol
        deployment.config = new Spro(address(deployment.sdex), FEE, PARTIAL_POSITION_PERCENTAGE);
        vm.stopPrank();
        deployment.loanToken = deployment.config.loanToken();

        // Labels
        vm.label(deployment.proxyAdmin, "proxyAdmin");
        vm.label(deployment.protocolAdmin, "protocolAdmin");
        vm.label(address(deployment.sdex), "sdex");
        vm.label(address(deployment.config), "config");
        vm.label(address(deployment.loanToken), "loanToken");
    }
}
