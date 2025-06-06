// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { FuzzStorageVariables } from "../utils/FuzzStorageVariables.sol";

import { Spro } from "src/spro/Spro.sol";
import { ISproTypes } from "src/interfaces/ISproTypes.sol";

contract Properties_PROP is FuzzStorageVariables {
    function invariant_PROP_01(ISproTypes.Proposal memory proposal) internal view {
        assert(
            state[1].actorStates[actors.borrower][collateral]
                == state[0].actorStates[actors.borrower][collateral] - proposal.collateralAmount
        );
    }

    function invariant_PROP_02() internal view {
        assert(
            state[1].actorStates[actors.borrower][address(sdex)]
                == state[0].actorStates[actors.borrower][address(sdex)] - spro._fee()
        );
    }

    function invariant_PROP_03() internal view {
        assert(state[1].actorStates[actors.borrower][credit] == state[0].actorStates[actors.borrower][credit]);
    }

    function invariant_PROP_04(ISproTypes.Proposal memory proposal) internal view {
        assert(
            state[1].actorStates[address(spro)][collateral]
                == state[0].actorStates[address(spro)][collateral] + proposal.collateralAmount
        );
    }

    function invariant_PROP_05() internal view {
        assert(state[1].actorStates[address(spro)][credit] == state[0].actorStates[address(spro)][credit]);
    }

    function invariant_PROP_06() internal view {
        assert(spro._proposalNonce() == numberOfProposals);
    }

    function invariant_PROP_07() internal view {
        assert(
            state[1].actorStates[address(0xdead)][address(sdex)]
                == state[0].actorStates[address(0xdead)][address(sdex)] + spro._fee()
        );
    }
}
