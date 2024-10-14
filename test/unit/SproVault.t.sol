// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";

import { DummyPoolAdapter } from "test/helper/DummyPoolAdapter.sol";
import { T20 } from "test/helper/T20.sol";

import { SproVault, IPoolAdapter } from "src/spro/SproVault.sol";
import { ISproEvents } from "src/interfaces/ISproEvents.sol";
import { ISproErrors } from "src/interfaces/ISproErrors.sol";
import { ISproTypes } from "src/interfaces/ISproTypes.sol";
import { ISproVault } from "src/interfaces/ISproVault.sol";
import { Spro } from "src/spro/Spro.sol";

contract SproVaultHarness is SproVault {
    function push(address asset, uint256 amount, address beneficiary) external {
        _push(asset, amount, beneficiary);
    }

    function pushFrom(address asset, uint256 amount, address origin, address beneficiary) external {
        _pushFrom(asset, amount, origin, beneficiary);
    }

    function withdrawFromPool(address asset, uint256 amount, IPoolAdapter poolAdapter, address pool, address owner)
        external
    {
        _withdrawFromPool(asset, amount, poolAdapter, pool, owner);
    }

    function supplyToPool(address asset, uint256 amount, IPoolAdapter poolAdapter, address pool, address owner)
        external
    {
        _supplyToPool(asset, amount, poolAdapter, pool, owner);
    }

    function exposed_tryPermit(ISproTypes.Permit calldata permit) external {
        _tryPermit(permit);
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

/* ------------------------------------------------------------ */
/*  WITHDRAW FROM POOL                                       */
/* ------------------------------------------------------------ */

contract SproVault_WithdrawFromPool_Test is SproVaultTest {
    IPoolAdapter poolAdapter = IPoolAdapter(new DummyPoolAdapter());
    address pool = makeAddr("pool");
    address asset;
    uint256 amount;

    function setUp() public override {
        super.setUp();

        asset = address(t20);
        amount = 42e18;

        t20.mint(pool, amount);
        vm.prank(pool);
        t20.approve(address(poolAdapter), amount);
    }

    function test_shouldCallWithdrawOnPoolAdapter() external {
        vm.expectCall(
            address(poolAdapter), abi.encodeWithSelector(IPoolAdapter.withdraw.selector, pool, alice, asset, amount)
        );

        vault.withdrawFromPool(asset, amount, poolAdapter, pool, alice);
    }

    function test_shouldFail_whenIncompleteTransaction() external {
        vm.mockCall(asset, abi.encodeWithSignature("balanceOf(address)", alice), abi.encode(amount));
        vm.expectRevert(abi.encodeWithSelector(ISproVault.InvalidAmountTransfer.selector));
        vault.withdrawFromPool(asset, amount, poolAdapter, pool, alice);
    }

    function test_shouldEmitEvent_PoolWithdraw() external {
        vm.expectEmit();
        emit ISproVault.PoolWithdraw(asset, address(poolAdapter), pool, alice, amount);

        vault.withdrawFromPool(asset, amount, poolAdapter, pool, alice);
    }
}

/* ------------------------------------------------------------ */
/*  SUPPLY TO POOL                                           */
/* ------------------------------------------------------------ */

contract SproVault_SupplyToPool_Test is SproVaultTest {
    IPoolAdapter poolAdapter = IPoolAdapter(new DummyPoolAdapter());
    address pool = makeAddr("pool");
    address asset;
    uint256 amount;

    function setUp() public override {
        super.setUp();

        asset = address(t20);
        amount = 42e18;

        t20.mint(address(vault), amount);
    }

    function test_shouldTransferAssetToPoolAdapter() external {
        vm.expectCall(asset, abi.encodeWithSignature("transfer(address,uint256)", address(poolAdapter), amount));

        vault.supplyToPool(asset, amount, poolAdapter, pool, alice);
    }

    function test_shouldCallSupplyOnPoolAdapter() external {
        vm.expectCall(
            address(poolAdapter), abi.encodeWithSelector(IPoolAdapter.supply.selector, pool, alice, asset, amount)
        );

        vault.supplyToPool(asset, amount, poolAdapter, pool, alice);
    }

    function test_shouldFail_whenIncompleteTransaction() external {
        vm.mockCall(asset, abi.encodeWithSignature("balanceOf(address)", address(vault)), abi.encode(amount));
        vm.expectRevert(abi.encodeWithSelector(ISproVault.InvalidAmountTransfer.selector));
        vault.supplyToPool(asset, amount, poolAdapter, pool, alice);
    }

    function test_shouldEmitEvent_PoolSupply() external {
        vm.expectEmit();
        emit ISproVault.PoolSupply(asset, address(poolAdapter), pool, alice, amount);

        vault.supplyToPool(asset, amount, poolAdapter, pool, alice);
    }
}

/* ------------------------------------------------------------ */
/*  TRY PERMIT                                               */
/* ------------------------------------------------------------ */

contract SproVault_TryPermit_Test is SproVaultTest {
    Spro.Permit permit;
    string permitSignature = "permit(address,address,uint256,uint256,uint8,bytes32,bytes32)";

    function setUp() public override {
        super.setUp();

        vm.mockCall(
            token,
            abi.encodeWithSignature("permit(address,address,uint256,uint256,uint8,bytes32,bytes32)"),
            abi.encode("")
        );

        permit = ISproTypes.Permit({
            asset: token,
            owner: alice,
            amount: 100,
            deadline: 1,
            v: 4,
            r: bytes32(uint256(2)),
            s: bytes32(uint256(3))
        });
    }

    function test_shouldCallPermit_whenPermitAssetNonZero() external {
        vm.expectCall(
            token,
            abi.encodeWithSignature(
                permitSignature,
                permit.owner,
                address(vault),
                permit.amount,
                permit.deadline,
                permit.v,
                permit.r,
                permit.s
            )
        );

        vault.exposed_tryPermit(permit);
    }

    function test_shouldNotCallPermit_whenPermitIsZero() external {
        vm.expectCall({ callee: token, data: abi.encodeWithSignature(permitSignature), count: 0 });

        permit.asset = address(0);
        vault.exposed_tryPermit(permit);
    }

    function test_shouldNotFail_whenPermitReverts() external {
        vm.mockCallRevert(token, abi.encodeWithSignature(permitSignature), abi.encode(""));

        vault.exposed_tryPermit(permit);
    }
}
