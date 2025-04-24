// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { FuzzStorageVariables } from "../utils/FuzzStorageVariables.sol";

import { Spro } from "src/spro/Spro.sol";
import { ISproTypes } from "src/interfaces/ISproTypes.sol";

contract Properties_REPAY is FuzzStorageVariables {
    function invariant_REPAY_01(Spro.LoanWithId memory loanWithId) internal view {
        assert(
            block.timestamp >= loanWithId.loan.startTimestamp
                && block.timestamp <= loanWithId.loan.startTimestamp + loanWithId.loan.loanExpiration
        );
    }
}
