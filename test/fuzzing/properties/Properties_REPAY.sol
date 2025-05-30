// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { FuzzStorageVariables } from "../utils/FuzzStorageVariables.sol";

import { Spro } from "src/spro/Spro.sol";

contract Properties_REPAY is FuzzStorageVariables {
    function invariant_REPAY_01(Spro.LoanWithId memory loanWithId) internal view {
        assert(block.timestamp < loanWithId.loan.loanExpiration);
    }

    function invariant_REPAY_02(Spro.LoanWithId memory loanWithId) internal view {
        if (
            state[0].loanStatus[loanWithId.loanId] == LoanStatus.REPAYABLE
                && state[1].loanStatus[loanWithId.loanId] == LoanStatus.PAID_BACK
        ) {
            if (actors.lender != address(spro)) {
                assert(
                    state[1].actorStates[address(spro)][credit]
                        == state[0].actorStates[address(spro)][credit] + loanWithId.loan.principalAmount
                            + loanWithId.loan.fixedInterestAmount
                );
            }
        }
    }

    function invariant_REPAY_03(uint256 collateralAmount, address borrower) internal view {
        assert(
            state[1].actorStates[borrower][collateral] == state[0].actorStates[borrower][collateral] + collateralAmount
        );
    }

    function invariant_REPAY_04(Spro.LoanWithId memory loanWithId) internal view {
        if (
            state[0].loanStatus[loanWithId.loanId] == LoanStatus.REPAYABLE
                && state[1].loanStatus[loanWithId.loanId] == LoanStatus.PAID_BACK || actors.payer != actors.lender
        ) {
            if (actors.payer != address(spro)) {
                assert(
                    state[1].actorStates[actors.payer][credit]
                        == state[0].actorStates[actors.payer][credit] - loanWithId.loan.principalAmount
                            - loanWithId.loan.fixedInterestAmount
                );
            }
        }
        if (
            actors.payer == actors.lender && state[0].loanStatus[loanWithId.loanId] == LoanStatus.REPAYABLE
                && state[1].loanStatus[loanWithId.loanId] == LoanStatus.NONE
        ) {
            assert(state[1].actorStates[actors.payer][credit] == state[0].actorStates[actors.payer][credit]);
        }
    }
}
