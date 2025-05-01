// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { FuzzStorageVariables } from "../utils/FuzzStorageVariables.sol";

import { Spro } from "src/spro/Spro.sol";

contract Properties_ENDLOAN is FuzzStorageVariables {
    function invariant_ENDLOAN_01(address lender, uint256 loanId) internal view {
        if (state[0].loanStatus[loanId] == LoanStatus.REPAYABLE || state[0].loanStatus[loanId] == LoanStatus.PAID_BACK)
        {
            assert(state[1].actorStates[lender].collateralBalance == state[0].actorStates[lender].collateralBalance);
        }
    }

    function invariant_ENDLOAN_02(address payer, address lender, uint256 loanId) internal view {
        if (
            (
                payer != lender && state[0].loanStatus[loanId] == LoanStatus.REPAYABLE
                    && state[1].loanStatus[loanId] == LoanStatus.PAID_BACK
            )
                || (
                    state[0].loanStatus[loanId] == LoanStatus.NOT_REPAYABLE
                        && state[1].loanStatus[loanId] == LoanStatus.NONE
                )
        ) {
            assert(state[1].actorStates[lender].creditBalance == state[0].actorStates[lender].creditBalance);
        }
    }

    function invariant_ENDLOAN_03(uint256 loanId) internal view {
        if (
            (state[0].loanStatus[loanId] == LoanStatus.REPAYABLE && state[1].loanStatus[loanId] == LoanStatus.NONE)
                || (
                    state[0].loanStatus[loanId] == LoanStatus.NOT_REPAYABLE
                        && state[1].loanStatus[loanId] == LoanStatus.NONE
                )
        ) {
            assert(
                state[1].actorStates[address(spro)].creditBalance == state[0].actorStates[address(spro)].creditBalance
            );
        }
    }

    function invariant_ENDLOAN_04(Spro.LoanWithId memory loanWithId, address lender) internal view {
        if (
            state[0].loanStatus[loanWithId.loanId] == LoanStatus.REPAYABLE
                && state[0].loanStatus[loanWithId.loanId] == LoanStatus.NONE
        ) {
            assert(
                state[1].actorStates[lender].creditBalance
                    == state[0].actorStates[lender].creditBalance + loanWithId.loan.principalAmount
                        + loanWithId.loan.fixedInterestAmount
            );
        }
    }

    function invariant_ENDLOAN_05(Spro.LoanWithId memory loanWithId) internal view {
        if (
            (state[0].loanStatus[loanWithId.loanId] == LoanStatus.REPAYABLE)
                || (
                    state[0].loanStatus[loanWithId.loanId] == LoanStatus.NOT_REPAYABLE
                        && state[1].loanStatus[loanWithId.loanId] == LoanStatus.NONE
                )
        ) {
            assert(
                state[1].actorStates[address(spro)].collateralBalance
                    == state[0].actorStates[address(spro)].collateralBalance - loanWithId.loan.collateralAmount
            );
        }
    }
}
