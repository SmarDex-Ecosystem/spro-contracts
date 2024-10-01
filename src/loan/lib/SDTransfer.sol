// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import {MultiToken} from "MultiToken/MultiToken.sol";

library SDTransfer {
    using MultiToken for MultiToken.Asset;

    /**
     * @notice Thrown when an asset transfer is incomplete.
     */
    error IncompleteTransfer();

    function checkTransfer(
        MultiToken.Asset memory asset,
        uint256 originalBalance,
        address checkedAddress,
        bool checkIncreasingBalance
    ) internal view {
        uint256 expectedBalance = checkIncreasingBalance
            ? originalBalance + asset.getTransferAmount()
            : originalBalance - asset.getTransferAmount();

        if (expectedBalance != asset.balanceOf(checkedAddress)) {
            revert IncompleteTransfer();
        }
    }
}
