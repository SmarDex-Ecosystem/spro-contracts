// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { Test } from "forge-std/Test.sol";

import { LibPRNG } from "solady/src/utils/LibPRNG.sol";

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
    SproLoan loanToken;
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
    mapping(uint256 => address) lastOwnerOfLoan;
    address collateral;
    address credit;

    // Repayable loans
    Spro.LoanWithId[] internal repayableLoans;
    uint256[] internal repayableLoanIds;
    uint256 creditAmountForProtocol;
    uint256 totalRepaymentAmount;
    address[] borrowers;
    uint256[] borrowersCollateral;
    // Claimable loans
    Spro.LoanWithId[] internal claimableLoans;
    uint256[] internal claimableLoanIds;
    uint256 collateralAmountSentByProtocol;
    mapping(address => uint256) amountSentByProtocol;

    // Actors addresses
    Actors actors;
    // Credit in the protocol
    mapping(address => uint256) creditFromLoansPaidBack;
    // Collateral in the protocol
    mapping(address => uint256) collateralFromProposals;
    // Minted to the protocol
    mapping(address => uint256) tokenMintedToProtocol;
    mapping(address => uint256) tokenReceivedByProtocol;

    mapping(uint8 => State) state;

    struct Actors {
        address borrower;
        address lender;
        address payer;
    }

    struct State {
        mapping(address => mapping(address => uint256)) actorStates;
        address borrower;
        address lender;
        mapping(uint256 => LoanStatus) loanStatus;
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
        require(length <= loans.length, "Requested length exceeds loan length");
        LibPRNG.PRNG memory rng = LibPRNG.PRNG(input);

        uint256[] memory shuffleIndexes = new uint256[](loans.length);
        for (uint256 i = 0; i < loans.length; i++) {
            shuffleIndexes[i] = i;
        }
        LibPRNG.shuffle(rng, shuffleIndexes);
        randomLoans = new Spro.LoanWithId[](length);
        for (uint256 i = 0; i < length; i++) {
            randomLoans[i] = loans[shuffleIndexes[i]];
        }
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

    function _setStates(uint8 index, address[] memory users) internal {
        for (uint256 i = 0; i < users.length; i++) {
            _setActorState(index, users[i]);
        }
        _setActorState(index, address(spro));
        _setActorState(index, address(0xdead));
    }

    function _setActorState(uint8 index, address actor) internal {
        state[index].actorStates[actor][address(token1)] = token1.balanceOf(actor);
        state[index].actorStates[actor][address(token2)] = token2.balanceOf(actor);
        state[index].actorStates[actor][address(sdex)] = sdex.balanceOf(actor);
    }

    function _before(address[] memory users) internal {
        _setStates(0, users);
        _stateLoan(0);
        _setLastOwnerOfLoans();
    }

    function _after(address[] memory users) internal {
        _setStates(1, users);
        _newLoan();
        _stateLoan(1);
        // Token in the protocol
        _processCreditFromPaidBackLoans();
        // Process repayable loans
        _processRepayableLoans();
        // Process claimable loans
        _processClaimableLoans();
    }

    function _clean() internal {
        token2.blockTransfers(false, address(0));
        token1.blockTransfers(false, address(0));
        _removeLoansWithStatusNone();
        _fullReset();
    }

    function _fullReset() internal {
        delete state[0];
        delete state[1];

        delete collateral;
        delete credit;

        // Reset repayable loans variables
        delete repayableLoans;
        delete repayableLoanIds;
        delete creditAmountForProtocol;
        delete totalRepaymentAmount;
        delete borrowers;
        delete borrowersCollateral;
        // Reset claimable loans variable
        delete claimableLoans;
        delete claimableLoanIds;
        delete amountSentByProtocol[address(token1)];
        delete amountSentByProtocol[address(token2)];

        // Reset address variables
        delete actors;
        // Reset balance variables
        delete creditFromLoansPaidBack[address(token1)];
        delete creditFromLoansPaidBack[address(token2)];
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
                lastOwnerOfLoan[loanId] = loanToken.ownerOf(loanId);
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

    function _setLastOwnerOfLoans() internal {
        for (uint256 i = 0; i < loans.length; i++) {
            if (getStatus(loans[i].loanId) != LoanStatus.NONE) {
                lastOwnerOfLoan[loans[i].loanId] = loanToken.ownerOf(loans[i].loanId);
            } else {
                lastOwnerOfLoan[loans[i].loanId] = address(0);
            }
        }
    }

    function _processRepayableLoans() internal {
        for (uint256 i = 0; i < repayableLoans.length; i++) {
            Spro.LoanWithId memory loanWithId = repayableLoans[i];

            bool wasRepaid = state[0].loanStatus[loanWithId.loanId] == LoanStatus.REPAYABLE
                && state[1].loanStatus[loanWithId.loanId] == LoanStatus.PAID_BACK;
            uint256 repaymentAmount = loanWithId.loan.principalAmount + loanWithId.loan.fixedInterestAmount;
            if (lastOwnerOfLoan[loanWithId.loanId] == address(spro)) {
                creditAmountForProtocol += repaymentAmount;
            }
            if (wasRepaid) {
                creditAmountForProtocol += repaymentAmount;
            }
            if (wasRepaid || actors.payer != lastOwnerOfLoan[loanWithId.loanId]) {
                totalRepaymentAmount += repaymentAmount;
            }

            bool found = false;
            for (uint256 j = 0; j < borrowers.length; j++) {
                if (borrowers[j] == loanWithId.loan.borrower) {
                    borrowersCollateral[j] += loanWithId.loan.collateralAmount;
                    found = true;
                    break;
                }
            }
            if (!found) {
                borrowers.push(loanWithId.loan.borrower);
                borrowersCollateral.push(loanWithId.loan.collateralAmount);
            }
        }
    }

    function _processClaimableLoans() internal {
        if (actors.lender != address(spro)) {
            for (uint256 i = 0; i < claimableLoans.length; i++) {
                Spro.LoanWithId memory loanWithId = claimableLoans[i];
                if (
                    state[0].loanStatus[loanWithId.loanId] == LoanStatus.NOT_REPAYABLE
                        && state[1].loanStatus[loanWithId.loanId] == LoanStatus.NONE
                ) {
                    amountSentByProtocol[loanWithId.loan.collateralAddress] += loanWithId.loan.collateralAmount;
                }
                if (
                    state[0].loanStatus[loanWithId.loanId] == LoanStatus.PAID_BACK
                        && state[1].loanStatus[loanWithId.loanId] == LoanStatus.NONE
                ) {
                    amountSentByProtocol[loanWithId.loan.creditAddress] +=
                        loanWithId.loan.principalAmount + loanWithId.loan.fixedInterestAmount;
                }
            }
        }
    }

    function _processCreditFromPaidBackLoans() internal {
        for (uint256 i = 0; i < loans.length; i++) {
            LoanStatus status = state[1].loanStatus[loans[i].loanId];
            if (status == LoanStatus.PAID_BACK) {
                creditFromLoansPaidBack[loans[i].loan.creditAddress] +=
                    loans[i].loan.principalAmount + loans[i].loan.fixedInterestAmount;
            }
        }
    }
}
