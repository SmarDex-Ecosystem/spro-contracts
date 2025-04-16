// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { FuzzSetup } from "./FuzzSetup.sol";
import { PostconditionsSpro } from "./PostconditionsSpro.sol";
import { PreconditionsSpro } from "./PreconditionsSpro.sol";

import { ISproTypes } from "src/interfaces/ISproTypes.sol";

contract SproFuzz is FuzzSetup, PostconditionsSpro, PreconditionsSpro {
    constructor() payable {
        setup(address(this));
    }

    function fuzz_createProposal(uint8 seed, uint40 startTimestamp, uint40 loanExpiration) public {
        (address borrower, address lender) = getRandomUsers(seed);
        _setStates(0, borrower, lender);

        ISproTypes.Proposal memory proposal =
            _createProposalPreconditions(seed, borrower, startTimestamp, loanExpiration);

        vm.prank(borrower);
        (bool success, bytes memory returnData) = _createProposal(
            proposal.collateralAddress,
            proposal.collateralAmount,
            proposal.creditAddress,
            proposal.availableCreditLimit,
            proposal.fixedInterestAmount,
            proposal.startTimestamp,
            proposal.loanExpiration
        );

        _createProposalPostconditions(success, returnData, proposal);
    }
}
