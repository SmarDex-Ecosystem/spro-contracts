// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.26;

import { Properties } from "../properties/Properties.sol";

import { ISproTypes } from "src/interfaces/ISproTypes.sol";

contract PostconditionsSpro is Properties {
    function _createProposalPostconditions(
        bool success,
        bytes memory returnData,
        ISproTypes.Proposal memory proposal,
        address[] memory actors
    ) internal {
        if (success) {
            _after(actors);
            proposals.push(proposal);
            numberOfProposals++;
            invariant_PROP_01(proposal, actors[0]);
            invariant_PROP_02(actors[0]);
            invariant_PROP_03(actors[0]);
            invariant_PROP_04(proposal);
            invariant_PROP_05();
            invariant_PROP_06();
            invariant_PROP_07();
        } else {
            invariant_ERR(returnData);
        }
    }
}
