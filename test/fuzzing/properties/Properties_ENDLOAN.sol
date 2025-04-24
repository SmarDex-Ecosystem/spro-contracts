// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { FuzzStorageVariables } from "../utils/FuzzStorageVariables.sol";

import { Spro } from "src/spro/Spro.sol";

contract Properties_ENDLOAN is FuzzStorageVariables {
    function invariant_ENDLOAN_01(address lender) internal view {
        assert(state[1].actorStates[lender].collateralBalance == state[0].actorStates[lender].collateralBalance);
    }

    function invariant_ENDLOAN_02(address lender, LoanStatus statusBefore, LoanStatus statusAfter) internal view {
        if (statusBefore == LoanStatus.REPAYABLE && statusAfter == LoanStatus.PAID_BACK) {
            assert(state[1].actorStates[lender].creditBalance == state[0].actorStates[lender].creditBalance);
        }
    }
}
