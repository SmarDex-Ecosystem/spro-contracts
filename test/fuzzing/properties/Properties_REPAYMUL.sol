// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { Spro } from "src/spro/Spro.sol";

import "./Properties_REPAY.sol";

contract Properties_REPAYMUL is Properties_REPAY {
    function invariant_REPAYMUL_01(Spro.LoanWithId memory loanWithId) internal view {
        invariant_REPAY_01(loanWithId);
    }

    function invariant_REPAYMUL_02(uint256 creditAmountForProtocol) internal view {
        assert(
            state[1].actorStates[address(spro)].creditBalance
                == state[0].actorStates[address(spro)].creditBalance + creditAmountForProtocol
        );
    }

    function invariant_REPAYMUL_03(uint256 collateralAmount, address borrower) internal view {
        invariant_REPAY_03(collateralAmount, borrower);
    }

    function invariant_REPAYMUL_04(address payer, uint256 totalRepaymentAmount) internal view {
        assert(
            state[1].actorStates[payer].creditBalance
                == state[0].actorStates[payer].creditBalance - totalRepaymentAmount
        );
    }
}
