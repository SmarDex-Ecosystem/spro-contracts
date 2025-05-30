// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { FuzzStorageVariables } from "../utils/FuzzStorageVariables.sol";

import { Spro } from "src/spro/Spro.sol";

contract Properties_GLOB is FuzzStorageVariables {
    function invariant_GLOB_01() internal view {
        assert(
            state[1].actorStates[address(spro)][credit]
                == creditFromLoansPaidBack[credit] + collateralFromProposals[credit] + token2MintedToProtocol
                    + token2ReceivedByProtocol
        );
    }

    function invariant_GLOB_02() internal view {
        assert(
            state[1].actorStates[address(spro)][collateral]
                == collateralFromProposals[collateral] + creditFromLoansPaidBack[collateral] + token1MintedToProtocol
        );
    }
}
