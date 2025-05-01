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

    // Spro constants
    uint256 MAX_SDEX_FEE;
    uint256 BPS_DIVISOR;

    // Spro initialization
    address payable constant PERMIT2 = payable(address(0x000000000022D473030F116dDEE9F6B43aC78BA3));
    uint256 public constant FEE = 20e18;
    uint16 public constant PARTIAL_POSITION_BPS = 500;

    // Spro storage variables
    ISproTypes.Proposal[] internal proposals;
    Spro.LoanWithId[] internal loans;

    // Temporary variables
    mapping(uint8 => State) state;

    struct State {
        mapping(address => ActorStates) actorStates;
        address borrower;
        address lender;
        mapping(uint256 => LoanStatus) loanStatus;
    }

    struct ActorStates {
        uint256 collateralBalance;
        uint256 creditBalance;
        uint256 sdexBalance;
    }

    enum LoanStatus {
        NONE,
        PAID_BACK,
        REPAYABLE,
        NOT_REPAYABLE
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
        ISproTypes.Loan memory loan = spro.getLoan(loanId);
        if (loan.status == ISproTypes.LoanStatus.NONE) {
            return LoanStatus.NONE;
        }
        if (loan.status == ISproTypes.LoanStatus.PAID_BACK) {
            return LoanStatus.PAID_BACK;
        }
        if (spro.i_isLoanRepayable(loan.status, loan.loanExpiration)) {
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
        _removeLoansWithStatusNone();
        _stateLoan(0);
    }

    function _after(address[] memory actors) internal {
        _setStates(1, actors);
        _newLoan();
        _stateLoan(1);
    }

    function fullReset() internal {
        delete state[0];
        delete state[1];
    }

    function _removeLoansWithStatusNone() internal {
        uint256 i = 0;
        while (i < loans.length) {
            if (state[1].loanStatus[i] == LoanStatus.NONE) {
                loans[i] = loans[loans.length - 1];
                loans.pop();
                numberOfLoans--;
            } else {
                i++;
            }
        }
    }

    function _newLoan() internal {
        if (numberOfLoans == loans.length + 1) {
            uint256 loanId = spro._loanToken()._lastLoanId();
            ISproTypes.Loan memory loan = spro.getLoan(loanId);
            if (loan.status == ISproTypes.LoanStatus.NONE) {
                numberOfLoans--;
            } else {
                loans.push(Spro.LoanWithId(loanId, loan));
            }
        }
    }

    function _stateLoan(uint8 index) internal {
        if (loans.length == 0) {
            return;
        }
        for (uint256 i = 0; i < loans.length; i++) {
            state[index].loanStatus[loans[i].loanId] = getStatus(loans[i].loanId);
        }
    }
}
