// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { IERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IPoolAdapter } from "src/interfaces/IPoolAdapter.sol";
import { ISproErrors } from "src/interfaces/ISproErrors.sol";
import { ISproEvents } from "src/interfaces/ISproEvents.sol";

/**
 * @title Spro Vault
 * @notice Base contract for transferring and managing collateral and loan assets in Spro protocol.
 * @dev Loan contracts inherits Spro Vault to act as a Vault for its loan type.
 */
contract SproVault is ISproErrors, ISproEvents {
    using SafeERC20 for IERC20Metadata;
    /* ------------------------------------------------------------ */
    /*                      TRANSFER FUNCTIONS                      */
    /* ------------------------------------------------------------ */

    /**
     * @notice Function pulling an asset into a vault.
     * @dev The function assumes a prior token approval to a vault address.
     * @param asset Address of an asset to be pulled.
     * @param amount Amount of an asset to be pulled.
     * @param origin Borrower address that is transferring collateral to Vault or repaying a loan.
     */
    function _pull(address asset, uint256 amount, address origin) internal {
        IERC20Metadata(asset).safeTransferFrom(origin, address(this), amount);

        emit VaultPull(asset, origin, amount);
    }

    /**
     * @notice Function pushing an asset from a vault to a recipient.
     * @param asset Address of an asset to be pushed.
     * @param amount Amount of an asset to be pushed.
     * @param beneficiary An address of a recipient of an asset.
     */
    function _push(address asset, uint256 amount, address beneficiary) internal {
        IERC20Metadata(asset).safeTransfer(beneficiary, amount);
        emit VaultPush(asset, beneficiary, amount);
    }

    /**
     * @notice Function pushing an asset from an origin address to a beneficiary address.
     * @dev The function assumes a prior token approval to a vault address.
     * @param asset Address of an asset to be pushed.
     * @param amount Amount of an asset to be pushed.
     * @param origin An address of a lender who is providing a loan asset.
     * @param beneficiary An address of the recipient of an asset.
     */
    function _pushFrom(address asset, uint256 amount, address origin, address beneficiary) internal {
        IERC20Metadata(asset).safeTransferFrom(origin, beneficiary, amount);

        emit VaultPushFrom(asset, origin, beneficiary, amount);
    }

    /**
     * @notice Function withdrawing an asset from a Compound pool to the owner.
     * @dev The function assumes a prior check for a valid pool address.
     * @param asset Address of an asset to be withdrawn.
     * @param amount Amount of an asset to be withdrawn.
     * @param poolAdapter An address of a pool adapter.
     * @param pool An address of a pool.
     * @param owner An address on which behalf the assets are withdrawn.
     */
    function _withdrawFromPool(address asset, uint256 amount, IPoolAdapter poolAdapter, address pool, address owner)
        internal
    {
        uint256 originalBalance = IERC20Metadata(asset).balanceOf(owner);

        poolAdapter.withdraw(pool, owner, asset, amount);
        if (IERC20Metadata(asset).balanceOf(owner) != originalBalance + amount) {
            revert InvalidAmountTransfer();
        }

        emit PoolWithdraw(asset, address(poolAdapter), pool, owner, amount);
    }

    /**
     * @notice Function supplying an asset to a pool from a vault via a pool adapter.
     * @dev The function assumes a prior check for a valid pool address.
     *      Assuming pool will revert supply transaction if it fails.
     * @param asset Address of an asset to be supplied.
     * @param amount Amount of an asset to be supplied.
     * @param poolAdapter An address of a pool adapter.
     * @param pool An address of a pool.
     * @param owner An address on which behalf the asset is supplied.
     */
    function _supplyToPool(address asset, uint256 amount, IPoolAdapter poolAdapter, address pool, address owner)
        internal
    {
        uint256 originalBalance = IERC20Metadata(asset).balanceOf(address(this));

        IERC20Metadata(asset).safeTransfer(address(poolAdapter), amount);
        poolAdapter.supply(pool, owner, asset, amount);

        if (IERC20Metadata(asset).balanceOf(address(this)) != originalBalance - amount) {
            revert InvalidAmountTransfer();
        }

        // Note: Assuming pool will revert supply transaction if it fails.

        emit PoolSupply(asset, address(poolAdapter), pool, owner, amount);
    }

    /* ------------------------------------------------------------ */
    /*                            PERMIT                            */
    /* ------------------------------------------------------------ */

    /**
     * @notice Try to execute a permit for an ERC20 token.
     * @dev If the permit execution fails, the function will not revert.
     * @param permit The permit data.
     */
    function _tryPermit(Permit memory permit) internal {
        if (permit.asset != address(0)) {
            try IERC20Permit(permit.asset).permit({
                owner: permit.owner,
                spender: address(this),
                value: permit.amount,
                deadline: permit.deadline,
                v: permit.v,
                r: permit.r,
                s: permit.s
            }) { } catch {
                // Note: Permit execution can be frontrun, so we don't revert on failure.
            }
        }
    }
}
