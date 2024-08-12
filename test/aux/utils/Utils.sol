// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import {Test} from "forge-std/src/Test.sol";

abstract contract Utils is Test {
    function getBlockTimestamp() internal view returns (uint40) {
        return uint40(block.timestamp);
    }
}
