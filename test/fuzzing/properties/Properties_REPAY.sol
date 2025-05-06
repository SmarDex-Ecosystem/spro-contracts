// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { FuzzStorageVariables } from "../utils/FuzzStorageVariables.sol";

import { Spro } from "src/spro/Spro.sol";

contract Properties_REPAY is FuzzStorageVariables {
    function invariant_REPAY_01(Spro.LoanWithId memory loanWithId) internal view {
        assert(block.timestamp < loanWithId.loan.loanExpiration);
    }

    function invariant_REPAY_02(Spro.LoanWithId memory loanWithId, uint256 stateIndex) internal view {
        if (
            state[0].loanStatus[stateIndex] == LoanStatus.REPAYABLE
                && state[1].loanStatus[stateIndex] == LoanStatus.PAID_BACK
        ) {
            assert(
                state[1].actorStates[address(spro)].creditBalance
                    == state[0].actorStates[address(spro)].creditBalance + loanWithId.loan.principalAmount
                        + loanWithId.loan.fixedInterestAmount
            );
        }
    }

    function invariant_REPAY_03(Spro.LoanWithId memory loanWithId, address borrower) internal view {
        assert(
            state[1].actorStates[borrower].collateralBalance
                == state[0].actorStates[borrower].collateralBalance + loanWithId.loan.collateralAmount
        );
    }

    function invariant_REPAY_04(Spro.LoanWithId memory loanWithId, uint256 stateIndex, address payer, address lender)
        internal
        view
    {
        if (
            (
                state[0].loanStatus[stateIndex] == LoanStatus.REPAYABLE
                    && state[1].loanStatus[stateIndex] == LoanStatus.PAID_BACK
            ) || (payer != lender)
        ) {
            assert(
                state[1].actorStates[payer].creditBalance
                    == state[0].actorStates[payer].creditBalance - loanWithId.loan.principalAmount
                        - loanWithId.loan.fixedInterestAmount
            );
        }
        if (
            payer == lender && state[0].loanStatus[stateIndex] == LoanStatus.REPAYABLE
                && state[1].loanStatus[stateIndex] == LoanStatus.NONE
        ) {
            assert(state[1].actorStates[payer].creditBalance == state[0].actorStates[payer].creditBalance);
        }
    }
}
