// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { Test } from "forge-std/Test.sol";

import { Spro } from "src/spro/Spro.sol";
import { SproLoan } from "src/spro/SproLoan.sol";
import { ISproTypes } from "src/interfaces/ISproTypes.sol";

import { T20 } from "test/helper/T20.sol";
import { SproHandler } from "../FuzzSetup.sol";

contract FuzzStorageVariables is Test {
    T20 sdex;
    T20 token1;
    T20 token2;
    SproHandler spro;
    uint256 numberOfProposals;
    uint256 numberOfLoans;

    // Spro initialization
    address payable constant PERMIT2 = payable(address(0x000000000022D473030F116dDEE9F6B43aC78BA3));
    uint256 public constant FEE = 20e18;
    uint16 public constant PARTIAL_POSITION_BPS = 500;

    // Spro storage variables
    ISproTypes.Proposal[] internal proposals;
    Spro.LoanWithId[] internal loans;

    mapping(uint8 => State) state;

    struct State {
        mapping(address => ActorStates) actorStates;
        address borrower;
        address lender;
    }

    struct ActorStates {
        uint256 collateralBalance;
        uint256 creditBalance;
        uint256 sdexBalance;
    }

    enum LoanStatus {
        PAID_BACK,
        REPAYABLE,
        NOT_REPAYABLE,
        BURNED
    }

    function getRandomProposal(uint256 input) internal view returns (ISproTypes.Proposal memory) {
        uint256 randomIndex = input % proposals.length;
        return proposals[randomIndex];
    }

    function getRandomLoan(uint256 input) internal view returns (Spro.LoanWithId memory) {
        uint256 randomIndex = input % loans.length;
        return loans[randomIndex];
    }

    function getStatus(uint256 loanId) internal view returns (LoanStatus status) {
        if (spro._loanToken().ownerOf(loanId) == address(0)) {
            return LoanStatus.BURNED;
        }
        Spro.LoanStatus loanStatus = spro.getLoan(loanId).status;
        if (loanStatus == ISproTypes.LoanStatus.PAID_BACK) {
            return LoanStatus.PAID_BACK;
        }
        if (spro.i_isLoanRepayable(loanStatus, uint40(block.timestamp))) {
            return LoanStatus.REPAYABLE;
        } else {
            return LoanStatus.NOT_REPAYABLE;
        }
    }

    function _setStates(uint8 index, address[] memory actors) internal {
        for (uint256 i = 0; i < actors.length; i++) {
            _setActorState(index, actors[i]);
        }
        _setActorState(index, address(spro));
        _setActorState(index, address(0xdead));
    }

    function _setActorState(uint8 index, address actor) internal {
        state[index].actorStates[actor].collateralBalance = T20(token1).balanceOf(actor);
        state[index].actorStates[actor].creditBalance = T20(token2).balanceOf(actor);
        state[index].actorStates[actor].sdexBalance = T20(sdex).balanceOf(actor);
    }

    function _before(address[] memory actors) internal {
        fullReset();
        _setStates(0, actors);
    }

    function _after(address[] memory actors) internal {
        _setStates(1, actors);
    }

    function fullReset() internal {
        delete state[0];
        delete state[1];
    }
}
