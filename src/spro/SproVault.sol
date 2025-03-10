// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { ISproVault } from "src/interfaces/ISproVault.sol";

contract SproVault is ISproVault {
    using SafeERC20 for IERC20Metadata;
    /* ------------------------------------------------------------ */
    /*                      TRANSFER FUNCTIONS                      */
    /* ------------------------------------------------------------ */

    /**
     * @notice Function pushing an asset from a vault to a recipient.
     * @param asset Address of an asset to be pushed.
     * @param amount Amount of an asset to be pushed.
     * @param beneficiary An address of a recipient of an asset.
     */
    function _push(address asset, uint256 amount, address beneficiary) internal {
        IERC20Metadata(asset).safeTransfer(beneficiary, amount);
        emit VaultPushFrom(asset, address(this), beneficiary, amount);
    }

    /**
     * @notice Function pushing an asset from an origin address to a beneficiary address.
     * @dev The function assumes a prior token approval to a vault address.
     * @param asset Address of an asset to be pushed.
     * @param amount Amount of an asset to be pushed.
     * @param origin An address of the sender of an asset.
     * @param beneficiary An address of the recipient of an asset.
     */
    function _pushFrom(address asset, uint256 amount, address origin, address beneficiary) internal {
        IERC20Metadata(asset).safeTransferFrom(origin, beneficiary, amount);
        emit VaultPushFrom(asset, origin, beneficiary, amount);
    }
}
