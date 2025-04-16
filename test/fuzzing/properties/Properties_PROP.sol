// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { FuzzStorageVariables } from "../utils/FuzzStorageVariables.sol";

import { Spro } from "src/spro/Spro.sol";
import { ISproTypes } from "src/interfaces/ISproTypes.sol";

contract Properties_PROP is FuzzStorageVariables {
    function invariant_PROP_01(ISproTypes.Proposal memory proposal) internal view {
        assert(
            state[1].actorStates[state[1].borrower].collateralBalance
                == state[0].actorStates[state[0].borrower].collateralBalance - proposal.collateralAmount
        );
    }

    function invariant_PROP_02() internal view {
        assert(
            state[1].actorStates[state[1].borrower].sdexBalance
                == state[0].actorStates[state[0].borrower].sdexBalance - spro._fee()
        );
    }

    function invariant_PROP_03() internal view {
        assert(
            state[1].actorStates[state[1].borrower].creditBalance
                == state[0].actorStates[state[0].borrower].creditBalance
        );
    }

    function invariant_PROP_04(ISproTypes.Proposal memory proposal) internal view {
        assert(
            state[1].actorStates[address(spro)].collateralBalance
                == state[0].actorStates[address(spro)].collateralBalance + proposal.collateralAmount
        );
    }

    function invariant_PROP_05() internal view {
        assert(state[1].actorStates[address(spro)].creditBalance == state[0].actorStates[address(spro)].creditBalance);
    }

    function invariant_PROP_06(uint256 numberOfProposal) internal view {
        assert(spro._proposalNonce() == numberOfProposal);
    }

    function invariant_PROP_07() internal view {
        assert(
            state[1].actorStates[address(0xdead)].sdexBalance
                == state[0].actorStates[address(0xdead)].sdexBalance + spro._fee()
        );
    }
}
