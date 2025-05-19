// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { LibPRNG } from "solady/src/utils/LibPRNG.sol";

import { FuzzSetup } from "./FuzzSetup.sol";
import { PostconditionsSpro } from "./conditions/PostconditionsSpro.sol";
import { PreconditionsSpro } from "./conditions/PreconditionsSpro.sol";

import { ISproTypes } from "src/interfaces/ISproTypes.sol";
import { Spro } from "src/spro/Spro.sol";

contract SproFuzz is FuzzSetup, PostconditionsSpro, PreconditionsSpro {
    constructor() payable {
        setup(address(this));
    }

    function fuzz_setFee(uint256 seed) public {
        uint256 newFee = _setFeePreconditions(seed);
        _setFeeCall(address(this), newFee);
    }

    function fuzz_setPartialPositionPercentage(uint256 seed) public {
        uint16 newPartialPositionBps = _setPartialPositionPercentagePreconditions(seed);
        _setPartialPositionPercentageCall(address(this), newPartialPositionBps);
    }

    function fuzz_createProposal(
        uint256 seed1,
        uint256 seed2,
        uint256 seed3,
        uint40 startTimestamp,
        uint40 loanExpiration
    ) public {
        address[] memory actors = getRandomUsers(seed1, 1);
        sdex.mint(actors[0], spro._fee());
        _before(actors);

        ISproTypes.Proposal memory proposal =
            _createProposalPreconditions(seed1, seed2, seed3, actors[0], startTimestamp, loanExpiration);

        (bool success, bytes memory returnData) = _createProposalCall(
            actors[0],
            proposal.collateralAddress,
            proposal.collateralAmount,
            proposal.creditAddress,
            proposal.availableCreditLimit,
            proposal.fixedInterestAmount,
            proposal.startTimestamp,
            proposal.loanExpiration
        );

        _createProposalPostconditions(success, returnData, proposal, actors);
    }

    function fuzz_cancelProposal(uint256 seed) public {
        if (proposals.length == 0) {
            return;
        }
        ISproTypes.Proposal memory proposal = getRandomProposal(seed);
        address[] memory actors = new address[](1);
        actors[0] = proposal.proposer;
        _before(actors);

        (bool success, bytes memory returnData) = _cancelProposalCall(actors[0], proposal);

        _cancelProposalPostconditions(success, returnData, proposal, actors);
    }

    function fuzz_createLoan(uint256 seed) public {
        if (proposals.length == 0) {
            return;
        }

        ISproTypes.Proposal memory proposal = getRandomProposal(seed);
        address[] memory actors = new address[](2);
        actors[0] = proposal.proposer;
        actors[1] = getAnotherUser(actors[0]);
        uint256 creditAmount = _createLoanPreconditions(seed, proposal, actors[1]);
        if (creditAmount == 0) {
            return;
        }
        _before(actors);

        (bool success, bytes memory returnData) = _createLoanCall(actors[1], proposal, creditAmount);

        _createLoanPostconditions(success, returnData, creditAmount, proposal, actors);
    }

    function fuzz_repayLoan(uint256 seed, bool blocked) public {
        LibPRNG.PRNG memory rng = LibPRNG.PRNG(seed);
        if (loans.length == 0) {
            return;
        }

        Spro.LoanWithId memory loanWithId = getRandomLoan(seed);
        address payer = getRandomUsers(LibPRNG.next(rng), 1)[0];
        address[] memory actors = new address[](3);
        actors[0] = loanToken.ownerOf(loanWithId.loanId);
        actors[1] = payer;
        actors[2] = loanWithId.loan.borrower;
        if (blocked) {
            token2.blockTransfers(true, actors[0]);
        }
        _repayLoanPreconditions(loanWithId, actors[1]);
        _before(actors);

        (bool success, bytes memory returnData) = _repayLoanCall(actors[1], loanWithId.loanId);

        _repayLoanPostconditions(success, returnData, loanWithId, actors);
    }

    function fuzz_claimLoan(uint256 seed, bool expired) public {
        if (loans.length == 0) {
            return;
        }

        Spro.LoanWithId memory loanWithId = getRandomLoan(seed);
        address[] memory actors = new address[](2);
        actors[0] = loanToken.ownerOf(loanWithId.loanId);
        actors[1] = loanWithId.loan.borrower;
        if (expired) {
            vm.warp(loanWithId.loan.loanExpiration);
        }
        _before(actors);

        (bool success, bytes memory returnData) = _claimLoanCall(actors[0], loanWithId.loanId);

        _claimLoanPostconditions(success, returnData, loanWithId, actors);
    }

    function fuzz_transferNFT(uint256 seed) public {
        if (loans.length == 0) {
            return;
        }

        Spro.LoanWithId memory loanWithId = getRandomLoan(seed);
        address[] memory actors = new address[](2);
        actors[0] = loanToken.ownerOf(loanWithId.loanId);
        actors[1] = getAnotherUser(actors[0]);

        (bool success, bytes memory returnData) = _transferNFTCall(actors[0], actors[1], loanWithId.loanId);

        _transferNFTPostconditions(success, returnData, loanWithId.loanId, actors);
    }

    function fuzz_repayMultipleLoans(uint256 seed, uint256 seedNumLoansToRepay, bool blocked) public {
        LibPRNG.PRNG memory rng = LibPRNG.PRNG(seed);
        if (loans.length == 0) {
            return;
        }

        seedNumLoansToRepay = bound(seedNumLoansToRepay, 1, loans.length);
        Spro.LoanWithId[] memory loanWithIds = getRandomLoans(seed, seedNumLoansToRepay);

        address payer = getRandomUsers(LibPRNG.next(rng), 1)[0];

        uint256 totalRepaymentAmount = _repayMultipleLoansPreconditions(loanWithIds, payer);
        if (totalRepaymentAmount == 0) {
            return;
        }

        uint256 usersLength = USERS.length;
        if (blocked) {
            for (uint256 i = 0; i < usersLength; ++i) {
                token2.blockTransfers(true, USERS[i]);
            }
        }

        address[] memory actors = new address[](usersLength + 1);
        for (uint256 i = 0; i < usersLength; ++i) {
            actors[i] = USERS[i];
        }
        actors[usersLength] = payer;

        _before(actors);

        (bool success, bytes memory returnData) = _repayMultipleLoansCall(payer);

        _repayMultipleLoansPostconditions(success, returnData, actors);
    }
}
