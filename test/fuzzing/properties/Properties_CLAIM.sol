// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { FuzzStorageVariables } from "../utils/FuzzStorageVariables.sol";

import { Spro } from "src/spro/Spro.sol";

contract Properties_CLAIM is FuzzStorageVariables {
    function invariant_CLAIM_01(LoanStatus statusBefore, LoanStatus statusAfter) internal view {
        if (statusBefore == LoanStatus.PAID_BACK && statusAfter == LoanStatus.NONE) {
            assert(
                state[1].actorStates[address(spro)].collateralBalance
                    == state[0].actorStates[address(spro)].collateralBalance
            );
        }
    }

    function invariant_CLAIM_02(Spro.LoanWithId memory loanWithId, LoanStatus statusBefore, LoanStatus statusAfter)
        internal
        view
    {
        if (statusBefore == LoanStatus.PAID_BACK && statusAfter == LoanStatus.NONE) {
            assert(
                state[1].actorStates[address(spro)].creditBalance
                    == state[0].actorStates[address(spro)].creditBalance - loanWithId.loan.principalAmount
                        - loanWithId.loan.fixedInterestAmount
            );
        }
    }

    function invariant_CLAIM_03(
        Spro.LoanWithId memory loanWithId,
        LoanStatus statusBefore,
        LoanStatus statusAfter,
        address lender
    ) internal view {
        if (statusBefore == LoanStatus.NOT_REPAYABLE && statusAfter == LoanStatus.NONE) {
            assert(
                state[1].actorStates[lender].collateralBalance
                    == state[0].actorStates[lender].collateralBalance + loanWithId.loan.collateralAmount
            );
        }
    }
}
