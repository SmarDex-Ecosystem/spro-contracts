// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { FuzzSetup } from "./FuzzSetup.sol";
import { PostconditionsSpro } from "./conditions/PostconditionsSpro.sol";
import { PreconditionsSpro } from "./conditions/PreconditionsSpro.sol";

import { T20 } from "test/helper/T20.sol";

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
        bool tokenOne,
        uint40 startTimestamp,
        uint40 loanExpiration
    ) public {
        actors.borrower = getRandomUsers(seed1, 1)[0];
        sdex.mint(actors.borrower, spro._fee());

        ISproTypes.Proposal memory proposal =
            _createProposalPreconditions(seed1, seed2, seed3, tokenOne, actors.borrower, startTimestamp, loanExpiration);

        _before(USERS);

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
        uint256 withdrawableCollateralAmount = spro._withdrawableCollateral(keccak256(abi.encode(proposal)));
        credit = proposal.creditAddress;
        collateral = proposal.collateralAddress;

        _before(USERS);

        (bool success, bytes memory returnData) = _cancelProposalCall(actors.borrower, proposal);

        _cancelProposalPostconditions(success, returnData, proposal, USERS, withdrawableCollateralAmount);
    }

    function fuzz_createLoan(uint256 seed) public {
        if (proposals.length == 0) {
            return;
        }

        ISproTypes.Proposal memory proposal = getRandomProposal(seed);
        actors.borrower = proposal.proposer;
        actors.lender = getAnotherUser(proposal.proposer);

        uint256 creditAmount = _createLoanPreconditions(seed, proposal);
        if (creditAmount == 0) {
            return;
        }
        if (block.timestamp < proposal.startTimestamp) {
            uint256 warp = bound(seed, block.timestamp, proposal.startTimestamp - 1);
            vm.warp(warp);
        }

        _before(USERS);

        (bool success, bytes memory returnData) = _createLoanCall(actors.lender, proposal, creditAmount);

        _createLoanPostconditions(success, returnData, creditAmount, proposal, USERS);
    }

    function fuzz_repayLoan(uint256 seedRandomLoan, uint256 seedPayer, bool blocked, bool expired) public {
        if (loans.length == 0) {
            return;
        }

        Spro.LoanWithId memory loanWithId = getRandomLoan(seedRandomLoan);
        actors.lender = loanToken.ownerOf(loanWithId.loanId);
        actors.payer = getRandomUsers(seedPayer, 1)[0];
        actors.borrower = loanWithId.loan.borrower;
        if (expired) {
            vm.warp(loanWithId.loan.loanExpiration);
        }

        _repayLoanPreconditions(loanWithId, blocked);

        _before(USERS);

        (bool success, bytes memory returnData) = _repayLoanCall(actors.payer, loanWithId.loanId);

        _repayLoanPostconditions(success, returnData, loanWithId, USERS);
    }

    function fuzz_repayMultipleLoans(
        uint256 seedNumLoansToRepay,
        uint256 seedUserBlocked,
        uint256 seedPayer,
        bool blocked,
        bool expired
    ) public {
        if (loans.length == 0) {
            return;
        }

        actors.payer = getRandomUsers(seedPayer, 1)[0];
        seedNumLoansToRepay = bound(seedNumLoansToRepay, 1, loans.length);
        // The first argument will be hashed, so it's not important to use a specific seed.
        Spro.LoanWithId[] memory loanWithIds = getRandomLoans(seedUserBlocked, seedNumLoansToRepay);
        address userBlocked = getRandomUsers(seedUserBlocked, 1)[0];
        if (expired) {
            vm.warp(loanWithIds[0].loan.loanExpiration);
        }
        uint256 totalRepaymentAmount = _repayMultipleLoansPreconditions(loanWithIds, blocked, userBlocked);
        if (totalRepaymentAmount == 0) {
            return;
        }

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
        credit = loanWithId.loan.creditAddress;
        collateral = loanWithId.loan.collateralAddress;
        if (expired) {
            vm.warp(loanWithId.loan.loanExpiration);
        }

        _before(USERS);

        (bool success, bytes memory returnData) = _claimLoanCall(actors.payer, loanWithId.loanId);

        _claimLoanPostconditions(success, returnData, loanWithId, USERS);
    }

    function fuzz_claimMultipleLoans(uint256 seed, uint256 size, bool expired) public {
        if (loans.length == 0) {
            return;
        }

        size = bound(size, 1, loans.length);
        Spro.LoanWithId[] memory loanWithIds = getRandomLoans(seed, size);
        bool claimable = _claimMultipleLoansPreconditions(loanWithIds);
        if (!claimable) {
            return;
        }

        if (expired) {
            vm.warp(claimableLoans[0].loan.loanExpiration);
        }
        _before(USERS);

        (bool success, bytes memory returnData) = _claimMultipleLoansCall(actors.lender);

        _claimMultipleLoansPostconditions(success, returnData, USERS);
    }

    function fuzz_transferNFT(uint256 seedLoan, uint256 seedUser) public {
        if (loans.length == 0) {
            return;
        }

        Spro.LoanWithId memory loanWithId = getRandomLoan(seedLoan);
        actors.lender = loanToken.ownerOf(loanWithId.loanId);
        address to = getRandomUserOrProtocol(seedUser, address(spro));

        (bool success, bytes memory returnData) = _transferNFTCall(actors.lender, to, loanWithId.loanId);

        _transferNFTPostconditions(success, returnData, loanWithId.loanId, to);
    }

    function fuzz_mintTokenForProtocol(uint256 seedAmount, bool tokenOne) public {
        T20 token = tokenOne ? token1 : token2;
        seedAmount = bound(seedAmount, 0, 1e36);
        token.mint(address(spro), seedAmount);
        tokenMintedToProtocol[address(token)] += seedAmount;
    }
}
