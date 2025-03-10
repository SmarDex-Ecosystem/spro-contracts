// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import { Test } from "forge-std/Test.sol";

import { T20 } from "test/helper/T20.sol";

import { SproVault } from "src/spro/SproVault.sol";
import { ISproVault } from "src/interfaces/ISproVault.sol";
import { Spro } from "src/spro/Spro.sol";

contract SproVaultHandler is SproVault {
    function push(address asset, uint256 amount, address beneficiary) external {
        _push(asset, amount, beneficiary);
    }

    function pushFrom(address asset, uint256 amount, address origin, address beneficiary) external {
        _pushFrom(asset, amount, origin, beneficiary);
    }
}

contract SproVaultTest is Test {
    SproVaultHandler vault;
    T20 token;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    uint256 INITIAL_BALANCE = 1000e18;

    function setUp() public {
        vault = new SproVaultHandler();
        token = new T20();
    }
}

/* -------------------------------------------------------------------------- */
/*                                    PUSH                                    */
/* -------------------------------------------------------------------------- */

contract TestSproVaultPush is SproVaultTest {
    function test_pushEmitEvent() external {
        token.mint(address(vault), INITIAL_BALANCE);
        vm.expectEmit(true, true, true, true);
        emit ISproVault.VaultPushFrom(address(token), address(vault), alice, INITIAL_BALANCE);
        vault.push(address(token), INITIAL_BALANCE, alice);
    }
}

/* -------------------------------------------------------------------------- */
/*                                  PUSH_FROM                                 */
/* -------------------------------------------------------------------------- */

contract TestSproVaultPushFrom is SproVaultTest {
    function test_pushFromEmitEvent() external {
        token.mint(address(alice), INITIAL_BALANCE);
        vm.prank(alice);
        token.approve(address(vault), INITIAL_BALANCE);
        vm.expectEmit(true, true, true, true);
        emit ISproVault.VaultPushFrom(address(token), alice, bob, INITIAL_BALANCE);
        vault.pushFrom(address(token), INITIAL_BALANCE, alice, bob);
    }
}
