// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { FuzzStorageVariables } from "../utils/FuzzStorageVariables.sol";

import { Spro } from "src/spro/Spro.sol";
import { ISproTypes } from "src/interfaces/ISproTypes.sol";

contract Properties_CANCEL is FuzzStorageVariables {
    function invariant_CANCEL_01(ISproTypes.Proposal memory proposal, address borrower) internal view {
        bytes32 proposalHash = keccak256(abi.encode(proposal));
        uint256 withdrawableCollateralAmount = spro._withdrawableCollateral(proposalHash);

        assert(
            state[1].actorStates[borrower].collateralBalance
                == state[0].actorStates[borrower].collateralBalance + withdrawableCollateralAmount
        );
    }

    function invariant_CANCEL_02(ISproTypes.Proposal memory proposal) internal view {
        bytes32 proposalHash = keccak256(abi.encode(proposal));
        uint256 withdrawableCollateralAmount = spro._withdrawableCollateral(proposalHash);
        assert(
            state[1].actorStates[address(spro)].collateralBalance
                == state[0].actorStates[address(spro)].collateralBalance - withdrawableCollateralAmount
        );
    }
}
