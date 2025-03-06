// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title ISproVault
 * @notice Base contract for transferring and managing collateral and loan assets in Spro protocol.
 * @dev Loan contracts inherits Spro Vault to act as a Vault for its loan type.
 */
interface ISproVault {
    /// @notice Thrown when the Vault receives an invalid amount of an asset.
    error InvalidAmountTransfer();

    /**
     * @notice Emitted when asset transfer happens from an `origin` address to a `beneficiary` address.
     * @param asset The address of the asset.
     * @param origin The address of the origin.
     * @param beneficiary The address of the beneficiary.
     * @param amount The amount of the asset.
     */
    event VaultPushFrom(address asset, address indexed origin, address indexed beneficiary, uint256 amount);

    /**
     * @notice Emitted when asset is withdrawn from a pool to an `owner` address.
     * @param asset The address of the asset.
     * @param poolAdapter The address of the pool adapter.
     * @param pool The address of the pool.
     * @param owner The address of the owner.
     * @param amount The amount of the asset.
     */
    event PoolWithdraw(
        address asset, address indexed poolAdapter, address indexed pool, address indexed owner, uint256 amount
    );

    /**
     * @notice Emitted when asset is supplied to a pool from a vault.
     * @param asset The address of the asset.
     * @param poolAdapter The address of the pool adapter.
     * @param pool The address of the pool.
     * @param owner The address of the owner.
     * @param amount The amount of the asset.
     */
    event PoolSupply(
        address asset, address indexed poolAdapter, address indexed pool, address indexed owner, uint256 amount
    );
}
