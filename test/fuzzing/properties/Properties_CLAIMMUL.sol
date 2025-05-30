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

    function invariant_CLAIMMUL_02() internal {
        emit log_uint(99_999_999_999_999_999_999_999_999_999_999_999_999);
        emit log_uint(state[1].actorStates[address(spro)][credit]);
        emit log_uint(state[0].actorStates[address(spro)][credit]);
        emit log_uint(amountSentByProtocol[credit]);
        assert(
            state[1].actorStates[address(spro)][credit]
                == state[0].actorStates[address(spro)][credit] - amountSentByProtocol[credit]
        );
    }

    function invariant_CLAIMMUL_03() internal view {
        if (actors.lender != address(spro)) {
            assert(
                state[1].actorStates[actors.lender][collateral]
                    == state[0].actorStates[actors.lender][collateral] + amountSentByProtocol[collateral]
            );
        } else {
            assert(state[1].actorStates[actors.lender][collateral] == state[0].actorStates[actors.lender][collateral]);
        }
    }
}
