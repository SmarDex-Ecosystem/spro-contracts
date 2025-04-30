// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { FuzzStorageVariables } from "../utils/FuzzStorageVariables.sol";

import { Spro } from "src/spro/Spro.sol";

contract Properties_ENDLOAN is FuzzStorageVariables {
    function invariant_ENDLOAN_01(address lender) internal view {
        assert(state[1].actorStates[lender].collateralBalance == state[0].actorStates[lender].collateralBalance);
    }

    function invariant_ENDLOAN_02(address lender) internal view {
        if (state[0].loanStatus == LoanStatus.REPAYABLE && state[11].loanStatus == LoanStatus.PAID_BACK) {
            assert(state[1].actorStates[lender].creditBalance == state[0].actorStates[lender].creditBalance);
        }
    }

    function invariant_ENDLOAN_03() internal view {
        if (state[0].loanStatus == LoanStatus.REPAYABLE && state[0].loanStatus == LoanStatus.NONE) {
            assert(
                state[1].actorStates[address(spro)].creditBalance == state[0].actorStates[address(spro)].creditBalance
            );
        }
    }

    function invariant_ENDLOAN_04(Spro.LoanWithId memory loanWithId, address lender) internal view {
        if (state[0].loanStatus == LoanStatus.REPAYABLE && state[0].loanStatus == LoanStatus.NONE) {
            assert(
                state[1].actorStates[lender].creditBalance
                    == state[0].actorStates[lender].creditBalance + loanWithId.loan.principalAmount
                        + loanWithId.loan.fixedInterestAmount
            );
        }
    }

    function invariant_ENDLOAN_05(Spro.LoanWithId memory loanWithId) internal view {
        if (state[0].loanStatus == LoanStatus.REPAYABLE) {
            assert(
                state[1].actorStates[address(spro)].collateralBalance
                    == state[0].actorStates[address(spro)].collateralBalance - loanWithId.loan.collateralAmount
            );
        }
    }
}
