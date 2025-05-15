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
        if (loans.length == 0) {
            return;
        }

        Spro.LoanWithId memory loanWithId = getRandomLoan(seed);
        address[] memory payer = getRandomUsers(uint256(keccak256(abi.encode(seed))), 1);
        address[] memory actors = new address[](3);
        actors[0] = loanToken.ownerOf(loanWithId.loanId);
        actors[1] = payer[0];
        actors[2] = loanWithId.loan.borrower;
        if (blocked && actors[0] != address(spro)) {
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

    function fuzz_transferNFT(uint256 seed, bool toIsProtocol) public {
        if (loans.length == 0) {
            return;
        }

        Spro.LoanWithId memory loanWithId = getRandomLoan(seed);
        address[] memory actors = new address[](2);
        actors[0] = loanToken.ownerOf(loanWithId.loanId);
        if (toIsProtocol) {
            actors[1] = address(spro);
        } else {
            actors[1] = getAnotherUser(actors[0]);
        }

        bool success = _transferNFTCall(actors[0], actors[1], loanWithId.loanId);

        _transferNFTPostconditions(success, loanWithId.loanId, actors);
    }

    function fuzz_transferTokenToProtocol(uint256 seed1, uint256 seed2, bool tokenOne) public {
        address[] memory actors = getRandomUsers(seed1, 1);
        T20 token = tokenOne ? token1 : token2;
        if (token.balanceOf(actors[0]) == 0) {
            return;
        }
        seed2 = bound(seed2, 0, token.balanceOf(actors[0]));
        _before(actors);

        (bool success, bytes memory returnData) = _transferTokenCall(actors[0], address(token), address(spro), seed2);
        _transferTokenPostconditions(success, returnData, actors, address(token), seed2);
    }
}
