// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

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
        actors.borrower = getRandomUsers(seed1, 1)[0];
        sdex.mint(actors.borrower, spro._fee());
        _before(USERS);

        ISproTypes.Proposal memory proposal =
            _createProposalPreconditions(seed1, seed2, seed3, actors.borrower, startTimestamp, loanExpiration);

        (bool success, bytes memory returnData) = _createProposalCall(
            actors.borrower,
            proposal.collateralAddress,
            proposal.collateralAmount,
            proposal.creditAddress,
            proposal.availableCreditLimit,
            proposal.fixedInterestAmount,
            proposal.startTimestamp,
            proposal.loanExpiration
        );

        _createProposalPostconditions(success, returnData, proposal, USERS);
    }

    function fuzz_cancelProposal(uint256 seed) public {
        if (proposals.length == 0) {
            return;
        }
        ISproTypes.Proposal memory proposal = getRandomProposal(seed);
        actors.borrower = proposal.proposer;
        _before(USERS);

        (bool success, bytes memory returnData) = _cancelProposalCall(actors.borrower, proposal);

        _cancelProposalPostconditions(success, returnData, proposal, USERS);
    }

    function fuzz_createLoan(uint256 seed) public {
        if (proposals.length == 0) {
            return;
        }

        ISproTypes.Proposal memory proposal = getRandomProposal(seed);
        uint256 creditAmount = _createLoanPreconditions(seed, proposal);
        if (creditAmount == 0) {
            return;
        }

        actors.borrower = proposal.proposer;
        actors.lender = getAnotherUser(proposal.proposer);
        _before(USERS);

        (bool success, bytes memory returnData) = _createLoanCall(actors.lender, proposal, creditAmount);

        _createLoanPostconditions(success, returnData, creditAmount, proposal, USERS);
    }

    function fuzz_repayLoan(uint256 seedRandomLoan, uint256 seedPayer, bool blocked) public {
        if (loans.length == 0) {
            return;
        }

        Spro.LoanWithId memory loanWithId = getRandomLoan(seedRandomLoan);
        _repayLoanPreconditions(loanWithId, blocked);

        actors.lender = loanToken.ownerOf(loanWithId.loanId);
        actors.payer = getRandomUsers(seedPayer, 1)[0];
        actors.borrower = loanWithId.loan.borrower;
        _before(USERS);

        (bool success, bytes memory returnData) = _repayLoanCall(actors.payer, loanWithId.loanId);

        _repayLoanPostconditions(success, returnData, loanWithId, USERS);
    }

    function fuzz_repayMultipleLoans(
        uint256 seedNumLoansToRepay,
        uint256 seedUserBlocked,
        uint256 seedPayer,
        bool blocked
    ) public {
        if (loans.length == 0) {
            return;
        }

        seedNumLoansToRepay = bound(seedNumLoansToRepay, 1, loans.length);
        // The first argument will be hashed, so it's not important to use a specific seed.
        Spro.LoanWithId[] memory loanWithIds = getRandomLoans(seedUserBlocked, seedNumLoansToRepay);
        address userBlocked = getRandomUsers(seedUserBlocked, 1)[0];
        uint256 totalRepaymentAmount = _repayMultipleLoansPreconditions(loanWithIds, actors.payer, blocked, userBlocked);
        if (totalRepaymentAmount == 0) {
            return;
        }

        actors.payer = getRandomUsers(seedPayer, 1)[0];
        _before(USERS);

        (bool success, bytes memory returnData) = _repayMultipleLoansCall(actors.payer);

        _repayMultipleLoansPostconditions(success, returnData, USERS);
    }

    function fuzz_claimLoan(uint256 seed, bool expired) public {
        if (loans.length == 0) {
            return;
        }

        Spro.LoanWithId memory loanWithId = getRandomLoan(seed);
        actors.lender = loanToken.ownerOf(loanWithId.loanId);
        actors.payer = actors.lender;
        actors.borrower = loanWithId.loan.borrower;
        if (expired) {
            vm.warp(loanWithId.loan.loanExpiration);
        }
        _before(USERS);

        (bool success, bytes memory returnData) = _claimLoanCall(actors.payer, loanWithId.loanId);

        _claimLoanPostconditions(success, returnData, loanWithId, USERS);
    }

    function fuzz_transferNFT(uint256 seed) public {
        if (loans.length == 0) {
            return;
        }

        Spro.LoanWithId memory loanWithId = getRandomLoan(seed);
        actors.lender = loanToken.ownerOf(loanWithId.loanId);
        address to = getAnotherUser(actors.lender);

        (bool success, bytes memory returnData) = _transferNFTCall(actors.lender, to, loanWithId.loanId);

        _transferNFTPostconditions(success, returnData, loanWithId.loanId, to);
    }
}
