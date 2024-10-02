// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";
import { T20 } from "test/helper/T20.sol";

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {
    SDDeployments,
    SDConfig,
    IPWNDeployer,
    PWNHub,
    PWNHubTags,
    SDSimpleLoan,
    SDSimpleLoanSimpleProposal,
    PWNLOAN,
    PWNRevokedNonce
} from "pwn/SDDeployments.sol";

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
        vm.label(address(deployment.configSingleton), "configSingleton");
        vm.label(address(deployment.config), "config");
        vm.label(address(deployment.hub), "hub");
        vm.label(address(deployment.revokedNonce), "revokedNonce");
        vm.label(address(deployment.loanToken), "loanToken");
        vm.label(address(deployment.simpleLoan), "simpleLoan");
        vm.label(address(deployment.simpleLoanSimpleProposal), "simpleLoanSimpleProposal");
    }

    function _protocolNotDeployedOnSelectedChain() internal override {
        deployment.proxyAdmin = makeAddr("proxyAdmin");
        deployment.protocolAdmin = makeAddr("protocolAdmin");

        // Deploy SDEX token
        deployment.sdex = new T20();

        // Deploy protocol
        deployment.configSingleton = new SDConfig(address(deployment.sdex));
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(deployment.configSingleton),
            deployment.proxyAdmin,
            abi.encodeWithSignature(
                "initialize(address,uint256,uint256,uint256,uint16)",
                deployment.protocolAdmin,
                UNLISTED_FEE,
                LISTED_FEE,
                VARIABLE_FACTOR,
                PARTIAL_POSITION_PERCENTAGE
            )
        );
        deployment.config = SDConfig(address(proxy));

        vm.prank(deployment.protocolAdmin);
        deployment.hub = new PWNHub();

        deployment.revokedNonce = new PWNRevokedNonce(address(deployment.hub), PWNHubTags.NONCE_MANAGER);

        deployment.loanToken = new PWNLOAN(address(deployment.hub));
        deployment.simpleLoan = new SDSimpleLoan(
            address(deployment.hub),
            address(deployment.loanToken),
            address(deployment.config),
            address(deployment.revokedNonce)
        );

        deployment.simpleLoanSimpleProposal = new SDSimpleLoanSimpleProposal(
            address(deployment.hub), address(deployment.revokedNonce), address(deployment.config)
        );

        // Set hub tags
        address[] memory addrs = new address[](10);
        addrs[0] = address(deployment.simpleLoan);
        addrs[1] = address(deployment.simpleLoan);

        addrs[2] = address(deployment.simpleLoanSimpleProposal);
        addrs[3] = address(deployment.simpleLoanSimpleProposal);

        bytes32[] memory tags = new bytes32[](10);
        tags[0] = PWNHubTags.ACTIVE_LOAN;
        tags[1] = PWNHubTags.NONCE_MANAGER;

        tags[2] = PWNHubTags.LOAN_PROPOSAL;
        tags[3] = PWNHubTags.NONCE_MANAGER;

        vm.prank(deployment.protocolAdmin);
        deployment.hub.setTags(addrs, tags, true);
    }
}
