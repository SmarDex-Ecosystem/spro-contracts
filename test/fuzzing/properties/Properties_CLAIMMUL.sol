// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { FuzzStorageVariables } from "../utils/FuzzStorageVariables.sol";

import { Spro } from "src/spro/Spro.sol";

contract Properties_CLAIMMUL is FuzzStorageVariables {
    function invariant_CLAIMMUL_01() internal view {
        assert(
            state[1].actorStates[address(spro)][collateral]
                == state[0].actorStates[address(spro)][collateral] - amountSentByProtocol[collateral]
        );
    }

    function invariant_CLAIMMUL_02() internal view {
        assert(
            state[1].actorStates[address(spro)][credit]
                == state[0].actorStates[address(spro)][credit] - amountSentByProtocol[credit]
        );
    }

    function invariant_CLAIMMUL_03() internal view {
        assert(
            state[1].actorStates[actors.lender][collateral]
                == state[0].actorStates[actors.lender][collateral] + amountSentByProtocol[collateral]
        );
    }

    function invariant_CLAIMMUL_04() internal view {
        assert(
            state[1].actorStates[actors.lender][credit]
                == state[0].actorStates[actors.lender][credit] + amountSentByProtocol[credit]
        );
    }
}
