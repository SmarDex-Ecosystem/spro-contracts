// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { FuzzSetup } from "./FuzzSetup.sol";

contract SproFuzz is FuzzSetup {
    constructor() payable {
        setup(address(this));
    }

    function assertPartialPositionBps(uint16 bps) public {
        uint256 bpsBefore = spro._partialPositionBps();
        try spro.setPartialPositionPercentage(bps) {
            assert(spro._partialPositionBps() == bps);
        } catch {
            if (bps == 0 || uint256(bps) > spro.BPS_DIVISOR() / 2) {
                assert(spro._partialPositionBps() == bpsBefore);
            } else {
                assert(true == false);
            }
        }
    }
}
