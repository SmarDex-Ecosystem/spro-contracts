// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { FuzzStorageVariables } from "../utils/FuzzStorageVariables.sol";

import { Spro } from "src/spro/Spro.sol";

contract Properties_CANCEL is FuzzStorageVariables {
    function invariant_CANCEL_01(bytes32 proposalHash) internal view {
        uint256 withdrawableCollateralAmount = spro._withdrawableCollateral(proposalHash);

        assert(
            state[1].actorStates[actors.borrower][collateral]
                == state[0].actorStates[actors.borrower][collateral] + withdrawableCollateralAmount
        );
    }

    function invariant_CANCEL_02(bytes32 proposalHash) internal view {
        uint256 withdrawableCollateralAmount = spro._withdrawableCollateral(proposalHash);
        assert(
            state[1].actorStates[address(spro)][collateral]
                == state[0].actorStates[address(spro)][collateral] - withdrawableCollateralAmount
        );
    }
}
