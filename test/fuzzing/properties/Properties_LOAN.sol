// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { FuzzStorageVariables } from "../utils/FuzzStorageVariables.sol";

import { Spro } from "src/spro/Spro.sol";
import { ISproTypes } from "src/interfaces/ISproTypes.sol";

contract Properties_LOAN is FuzzStorageVariables {
    function invariant_LOAN_01(uint256 creditAmount, address lender) internal view {
        assert(state[1].actorStates[lender].creditBalance == state[0].actorStates[lender].creditBalance - creditAmount);
    }

    function invariant_LOAN_02(address lender) internal view {
        assert(state[1].actorStates[lender].collateralBalance == state[0].actorStates[lender].collateralBalance);
    }

    function invariant_LOAN_03(uint256 creditAmount, address borrower) internal view {
        assert(
            state[1].actorStates[borrower].creditBalance == state[0].actorStates[borrower].creditBalance + creditAmount
        );
    }

    function invariant_LOAN_04(address borrower) internal view {
        assert(state[1].actorStates[borrower].collateralBalance == state[0].actorStates[borrower].collateralBalance);
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

    function invariant_LOAN_08(ISproTypes.Proposal memory proposal, bytes memory returnData) internal view {
        uint256 loanId = abi.decode(returnData, (uint256));
        ISproTypes.Loan memory loan = spro.getLoan(loanId);

        assert(proposal.collateralAmount >= loan.collateralAmount);
    }
}
