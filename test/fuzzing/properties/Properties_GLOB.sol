// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { FuzzStorageVariables } from "../utils/FuzzStorageVariables.sol";

import { Spro } from "src/spro/Spro.sol";

contract Properties_GLOB is FuzzStorageVariables {
    function invariant_GLOB_01() internal view {
        assert(state[1].actorStates[address(spro)].creditBalance == creditFromLoansPaidBack + token2MintedToProtocol);
    }
}
