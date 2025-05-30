// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { FuzzStorageVariables } from "../utils/FuzzStorageVariables.sol";

import { Spro } from "src/spro/Spro.sol";

contract Properties_ENDLOAN is FuzzStorageVariables {
    function invariant_ENDLOAN_01(uint256 loanId) internal view {
        if (state[0].loanStatus[loanId] == LoanStatus.REPAYABLE || state[0].loanStatus[loanId] == LoanStatus.PAID_BACK)
        {
            assert(state[1].actorStates[actors.lender][collateral] == state[0].actorStates[actors.lender][collateral]);
        }
    }

    function invariant_ENDLOAN_02(uint256 loanId) internal view {
        if (
            actors.payer != actors.lender && state[0].loanStatus[loanId] == LoanStatus.REPAYABLE
                && state[1].loanStatus[loanId] == LoanStatus.PAID_BACK
                || state[0].loanStatus[loanId] == LoanStatus.NOT_REPAYABLE && state[1].loanStatus[loanId] == LoanStatus.NONE
        ) {
            assert(state[1].actorStates[actors.lender][credit] == state[0].actorStates[actors.lender][credit]);
        }
    }

    function invariant_ENDLOAN_03(uint256 loanId) internal view {
        if (
            state[0].loanStatus[loanId] == LoanStatus.REPAYABLE && state[1].loanStatus[loanId] == LoanStatus.NONE
                || state[0].loanStatus[loanId] == LoanStatus.NOT_REPAYABLE && state[1].loanStatus[loanId] == LoanStatus.NONE
        ) {
            if (actors.lender != address(spro)) {
                assert(state[1].actorStates[address(spro)][credit] == state[0].actorStates[address(spro)][credit]);
            }
        }
    }

    function invariant_ENDLOAN_04(Spro.LoanWithId memory loanWithId) internal view {
        if (
            actors.payer != actors.lender && state[0].loanStatus[loanWithId.loanId] == LoanStatus.REPAYABLE
                && state[1].loanStatus[loanWithId.loanId] == LoanStatus.NONE
                || state[0].loanStatus[loanWithId.loanId] == LoanStatus.PAID_BACK
                    && state[1].loanStatus[loanWithId.loanId] == LoanStatus.NONE
        ) {
            assert(
                state[1].actorStates[actors.lender][credit]
                    == state[0].actorStates[actors.lender][credit] + loanWithId.loan.principalAmount
                        + loanWithId.loan.fixedInterestAmount
            );
        }
    }

    function invariant_ENDLOAN_05(Spro.LoanWithId memory loanWithId) internal view {
        if (
            state[0].loanStatus[loanWithId.loanId] == LoanStatus.REPAYABLE
                || state[0].loanStatus[loanWithId.loanId] == LoanStatus.NOT_REPAYABLE
                    && state[1].loanStatus[loanWithId.loanId] == LoanStatus.NONE
        ) {
            assert(
                state[1].actorStates[address(spro)][collateral]
                    == state[0].actorStates[address(spro)][collateral] - loanWithId.loan.collateralAmount
            );
        }
    }
}
