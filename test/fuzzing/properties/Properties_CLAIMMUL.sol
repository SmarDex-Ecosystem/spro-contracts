// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { FuzzStorageVariables } from "../utils/FuzzStorageVariables.sol";

import { Spro } from "src/spro/Spro.sol";

contract Properties_CLAIMMUL is FuzzStorageVariables {
    function invariant_CLAIMMUL_01(uint256 collateralAmount) internal view {
        assert(
            state[1].actorStates[address(spro)].collateralBalance
                == state[0].actorStates[address(spro)].collateralBalance + collateralAmount
        );
    }
}
