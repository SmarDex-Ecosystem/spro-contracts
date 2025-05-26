// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { Spro } from "src/spro/Spro.sol";

import "./Properties_REPAY.sol";

contract Properties_REPAYMUL is Properties_REPAY {
    function invariant_REPAYMUL_01(Spro.LoanWithId memory loanWithId) internal view {
        invariant_REPAY_01(loanWithId);
    }

    function invariant_REPAYMUL_02() internal {
        // if (actors.lender != address(spro)) {
        emit log_uint(state[1].actorStates[address(spro)].creditBalance);
        emit log_uint(state[0].actorStates[address(spro)].creditBalance);
        emit log_uint(creditAmountForProtocol);
        assert(
            state[1].actorStates[address(spro)].creditBalance
                == state[0].actorStates[address(spro)].creditBalance + creditAmountForProtocol
        );
        // }
    }

    function invariant_REPAYMUL_03(address borrower, uint256 collateralAmount) internal view {
        invariant_REPAY_03(collateralAmount, borrower);
    }

    function invariant_REPAYMUL_04() internal view {
        assert(
            state[1].actorStates[actors.payer].creditBalance
                == state[0].actorStates[actors.payer].creditBalance - totalRepaymentAmount
        );
    }
}
