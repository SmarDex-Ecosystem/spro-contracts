// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.26;

import { Properties } from "./properties/Properties.sol";

import { ISproTypes } from "src/interfaces/ISproTypes.sol";

contract PostconditionsSpro is Properties {
    function _createProposalPostconditions(bool success, bytes memory returnData, ISproTypes.Proposal memory proposal)
        internal
    {
        if (success) {
            proposals.push(proposal);
            numberOfProposals++;
            _setStates(1, state[0].borrower, state[0].lender);
            invariant_PROP_01(proposal);
            invariant_PROP_02();
            invariant_PROP_03();
            invariant_PROP_04(proposal);
            invariant_PROP_05();
            invariant_PROP_06(numberOfProposals);
            invariant_PROP_07();
        } else {
            invariant_ERR(returnData);
        }
    }
}
