// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { Test } from "forge-std/Test.sol";

import { Spro } from "src/spro/Spro.sol";
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

    // Loan variables
    mapping(uint256 => uint256) internal loanIdToStateIndex;

    // Repayable loans
    Spro.LoanWithId[] internal repayableLoans;
    uint256[] internal repayableLoanIds;
    uint256 creditAmountForProtocol;
    uint256 totalRepaymentAmount;
    address[] borrowers;
    uint256[] borrowersCollateral;

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

    function getRandomLoans(uint256 input, uint256 length)
        internal
        view
        returns (Spro.LoanWithId[] memory randomLoans)
    {
        require(length <= loans.length, "Requested length exceeds USERS length");

        Spro.LoanWithId[] memory shuffleLoans = loans;
        for (uint256 i = loans.length - 1; i > 0; i--) {
            uint256 j = uint256(keccak256(abi.encodePacked(input, i))) % (i + 1);
            (shuffleLoans[i], shuffleLoans[j]) = (shuffleLoans[j], shuffleLoans[i]);
        }

        randomLoans = new Spro.LoanWithId[](length);
        for (uint256 i = 0; i < length; i++) {
            randomLoans[i] = shuffleLoans[i];
        }

        return randomLoans;
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
        state[index].actorStates[actor].collateralBalance = token1.balanceOf(actor);
        state[index].actorStates[actor].creditBalance = token2.balanceOf(actor);
        state[index].actorStates[actor].sdexBalance = sdex.balanceOf(actor);
    }

    function _before(address[] memory actors) internal {
        _setStates(0, actors);
        _stateLoan(0);
    }

    function _after(address[] memory actors) internal {
        _setStates(1, actors);
        _newLoan();
        _stateLoan(1);
        // Process match state with loans
        _matchStateWithLoans();
        // Process repayable loans
        _processRepayableLoans(actors[actors.length - 1]);
    }

    function _clean() internal {
        token2.blockTransfers(false, address(0));
        _removeLoansWithStatusNone();
        _fullReset();
    }

    function _fullReset() internal {
        delete state[0];
        delete state[1];

        // Reset repayable loans variables
        delete repayableLoans;
        delete repayableLoanIds;
        delete creditAmountForProtocol;
        delete totalRepaymentAmount;
        delete borrowers;
        delete borrowersCollateral;
    }

    function _removeLoansWithStatusNone() internal {
        uint256 i = 0;
        while (i < loans.length) {
            if (LoanStatus.NONE == getStatus(loans[i].loanId)) {
                loans[i] = loans[loans.length - 1];
                loans.pop();
                numberOfLoans--;
            } else {
                i++;
            }
        }
    }

    function _newLoan() internal {
        if (numberOfLoans != loans.length) {
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
            state[index].loanStatus[i] = getStatus(loans[i].loanId);
        }
    }

    function _processRepayableLoans(address payer) internal {
        for (uint256 i = 0; i < repayableLoans.length; i++) {
            Spro.LoanWithId memory loanWithId = repayableLoans[i];
            uint256 stateIndex;
            for (uint256 j = 0; j < loans.length; j++) {
                if (loans[j].loanId == loanWithId.loanId) {
                    stateIndex = j;
                    break;
                }
            }

            bool wasRepaid = state[0].loanStatus[stateIndex] == LoanStatus.REPAYABLE
                && state[1].loanStatus[stateIndex] == LoanStatus.PAID_BACK;
            uint256 repaymentAmount = loanWithId.loan.principalAmount + loanWithId.loan.fixedInterestAmount;
            if (wasRepaid) {
                creditAmountForProtocol += repaymentAmount;
            }
            if (wasRepaid || payer != loanWithId.loan.lender) {
                totalRepaymentAmount += repaymentAmount;
            }

            address borrower = loanWithId.loan.borrower;
            bool found = false;
            for (uint256 j = 0; j < borrowers.length; j++) {
                if (borrowers[j] == borrower) {
                    borrowersCollateral[j] += loanWithId.loan.collateralAmount;
                    found = true;
                    break;
                }
            }
            if (!found) {
                borrowers.push(borrower);
                borrowersCollateral.push(loanWithId.loan.collateralAmount);
            }
        }
    }

    function _matchStateWithLoans() internal {
        for (uint256 i = 0; i < loans.length; i++) {
            loanIdToStateIndex[loans[i].loanId] = i;
        }
    }
}
