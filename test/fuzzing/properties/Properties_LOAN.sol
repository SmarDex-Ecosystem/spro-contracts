// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { FuzzStorageVariables } from "../utils/FuzzStorageVariables.sol";

import { Spro } from "src/spro/Spro.sol";
import { ISproTypes } from "src/interfaces/ISproTypes.sol";

contract Properties_LOAN is FuzzStorageVariables {
    function invariant_LOAN_01(uint256 creditAmount) internal view {
        assert(
            state[1].actorStates[actors.lender].creditBalance
                == state[0].actorStates[actors.lender].creditBalance - creditAmount
        );
    }

    function invariant_LOAN_02() internal view {
        assert(
            state[1].actorStates[actors.lender].collateralBalance
                == state[0].actorStates[actors.lender].collateralBalance
        );
    }

    function invariant_LOAN_03(uint256 creditAmount) internal view {
        assert(
            state[1].actorStates[actors.borrower].creditBalance
                == state[0].actorStates[actors.borrower].creditBalance + creditAmount
        );
    }

    function invariant_LOAN_04() internal view {
        assert(
            state[1].actorStates[actors.borrower].collateralBalance
                == state[0].actorStates[actors.borrower].collateralBalance
        );
    }

    function invariant_LOAN_05(ISproTypes.Proposal memory proposal) internal view {
        assert(proposal.startTimestamp > block.timestamp);
    }

    function invariant_LOAN_06(uint256 creditAmount, ISproTypes.Proposal memory proposal) internal pure {
        assert(creditAmount >= proposal.minAmount);
    }

    function invariant_LOAN_07(ISproTypes.Proposal memory proposal) internal view {
        uint256 remaining = proposal.availableCreditLimit - spro._creditUsed(keccak256(abi.encode(proposal)));
        assert(remaining == 0 || remaining >= proposal.minAmount);
    }

    function invariant_LOAN_08(ISproTypes.Proposal memory proposal) internal view {
        assert(proposal.collateralAmount >= loans[loans.length - 1].loan.collateralAmount);
    }
}
