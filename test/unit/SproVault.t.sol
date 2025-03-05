// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";

import { T20 } from "test/helper/T20.sol";

import { SproVault } from "src/spro/SproVault.sol";
import { ISproVault } from "src/interfaces/ISproVault.sol";
import { Spro } from "src/spro/Spro.sol";

contract SproVaultHarness is SproVault {
    function push(address asset, uint256 amount, address beneficiary) external {
        _push(asset, amount, beneficiary);
    }

    function pushFrom(address asset, uint256 amount, address origin, address beneficiary) external {
        _pushFrom(asset, amount, origin, beneficiary);
    }
}

abstract contract SproVaultTest is Test {
    SproVaultHarness vault;
    address token = makeAddr("token");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    T20 t20;

    constructor() {
        vm.etch(token, bytes("data"));
    }

    function setUp() public virtual {
        vault = new SproVaultHarness();
        t20 = new T20();
    }
}

/* ------------------------------------------------------------ */
/*  PUSH                                                     */
/* ------------------------------------------------------------ */

contract SproVault_Push_Test is SproVaultTest {
    function test_pushEmitEvent() external {
        vm.expectEmit(true, true, true, true);
        emit ISproVault.VaultPushFrom(token, address(vault), alice, 99_999_999);
        vault.push(token, 99_999_999, alice);
    }
}

/* ------------------------------------------------------------ */
/*  PUSH FROM                                                */
/* ------------------------------------------------------------ */

contract SproVault_PushFrom_Test is SproVaultTest {
    function test_pushFromEmitEvent() external {
        vm.expectEmit(true, true, true, true);
        emit ISproVault.VaultPushFrom(token, alice, bob, 42);
        vault.pushFrom(token, 42, alice, bob);
    }
}
