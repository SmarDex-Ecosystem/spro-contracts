// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { FuzzSetup } from "./FuzzSetup.sol";

contract SproFuzz is FuzzSetup {
    constructor() payable {
        setup(address(this));
    }

    function assertPartialPositionBps(uint16 bps) public {
        require(bps > 0 && bps <= spro.BPS_DIVISOR() / 2, "Invalid BPS");
        spro.setPartialPositionPercentage(bps);
        require(spro._partialPositionBps() == bps, "Invalid BPS");
        assert(spro._partialPositionBps() == bps);
    }
}
