// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.26;

import { Properties } from "../properties/Properties.sol";

import { ISproTypes } from "src/interfaces/ISproTypes.sol";
import { Spro } from "src/spro/Spro.sol";

contract PostconditionsSpro is Properties {
    function _createProposalPostconditions(
        bool success,
        bytes memory returnData,
        ISproTypes.Proposal memory proposal,
        address[] memory users
    ) internal {
        if (success) {
            proposals.push(proposal);
            numberOfProposals++;
            collateralFromProposals[proposal.collateralAddress] += proposal.collateralAmount;
            _after(users);

            invariant_GLOB_01();
            invariant_GLOB_02();
            invariant_PROP_01(proposal);
            invariant_PROP_02();
            invariant_PROP_03();
            invariant_PROP_04(proposal);
            invariant_PROP_05();
            invariant_PROP_06();
            invariant_PROP_07();
        } else {
            invariant_ERR(returnData);
        }
        _clean();
    }

    function _cancelProposalPostconditions(
        bool success,
        bytes memory returnData,
        ISproTypes.Proposal memory proposal,
        address[] memory users,
        uint256 withdrawableCollateralAmount
    ) internal {
        if (success) {
            for (uint256 i = 0; i < proposals.length; i++) {
                if (keccak256(abi.encode(proposal)) == keccak256(abi.encode(proposals[i]))) {
                    proposals[i] = proposals[proposals.length - 1];
                    proposals.pop();
                    break;
                }
            }
            collateralFromProposals[proposal.collateralAddress] -= withdrawableCollateralAmount;
            _after(users);

            invariant_GLOB_01();
            invariant_GLOB_02();
            bytes32 proposalHash = keccak256(abi.encode(proposal));
            invariant_CANCEL_01(proposalHash);
            invariant_CANCEL_02(proposalHash);
        } else {
            invariant_ERR(returnData);
        }
        _clean();
    }

    function _createLoanPostconditions(
        bool success,
        bytes memory returnData,
        uint256 creditAmount,
        ISproTypes.Proposal memory proposal,
        address[] memory users
    ) internal {
        if (success) {
            numberOfLoans++;
            _after(users);

            invariant_GLOB_01();
            invariant_GLOB_02();
            invariant_LOAN_01(creditAmount);
            invariant_LOAN_02();
            invariant_LOAN_03(creditAmount);
            invariant_LOAN_04();
            invariant_LOAN_05(proposal);
            invariant_LOAN_06(creditAmount, proposal);
            invariant_LOAN_07(proposal);
            invariant_LOAN_08(proposal);
        } else {
            invariant_ERR(returnData);
        }
        _clean();
    }

    function _repayLoanPostconditions(
        bool success,
        bytes memory returnData,
        Spro.LoanWithId memory loanWithId,
        address[] memory users
    ) internal {
        if (success) {
            _after(users);
            _repayLoanProcessCollateral(loanWithId);

            invariant_GLOB_01();
            invariant_GLOB_02();
            invariant_REPAY_01(loanWithId);
            invariant_REPAY_02(loanWithId);
            invariant_REPAY_03(loanWithId.loan.collateralAmount, actors.borrower);
            invariant_REPAY_04(loanWithId);

            if (actors.lender != address(spro)) {
                invariant_ENDLOAN_03(loanWithId.loanId);
                invariant_ENDLOAN_05(loanWithId);
                // Check if the lender is not the borrower
                if (actors.lender != actors.borrower) {
                    invariant_ENDLOAN_01(loanWithId.loanId);
                    invariant_ENDLOAN_02(loanWithId.loanId);
                    invariant_ENDLOAN_04(loanWithId);
                }
            }
        } else {
            invariant_ERR(returnData);
        }
        _clean();
    }

    function _repayMultipleLoansPostconditions(bool success, bytes memory returnData, address[] memory users)
        internal
    {
        if (success) {
            _after(users);
            _repayMultipleLoanProcessCollateral();

            invariant_GLOB_01();
            invariant_GLOB_02();
            for (uint256 i = 0; i < repayableLoanIds.length; i++) {
                invariant_REPAYMUL_01(repayableLoans[i]);
            }
            invariant_REPAYMUL_02();
            for (uint256 i = 0; i < borrowers.length; i++) {
                invariant_REPAYMUL_03(borrowers[i], borrowersCollateral[i]);
            }
            invariant_REPAYMUL_04();
        } else {
            invariant_ERR(returnData);
        }
        _clean();
    }

    function _claimLoanPostconditions(
        bool success,
        bytes memory returnData,
        Spro.LoanWithId memory loanWithId,
        address[] memory users
    ) internal {
        if (success) {
            _after(users);
            _claimLoanProcessCollateral(loanWithId);

            invariant_GLOB_01();
            invariant_GLOB_02();
            invariant_CLAIM_01(loanWithId.loanId);
            invariant_CLAIM_02(loanWithId);
            invariant_CLAIM_03(loanWithId);

            if (actors.lender != address(spro)) {
                invariant_ENDLOAN_01(loanWithId.loanId);
                invariant_ENDLOAN_02(loanWithId.loanId);
                invariant_ENDLOAN_03(loanWithId.loanId);
                invariant_ENDLOAN_04(loanWithId);
                invariant_ENDLOAN_05(loanWithId);
            }
        } else {
            invariant_ERR(returnData);
        }
        _clean();
    }

    function _claimMultipleLoansPostconditions(bool success, bytes memory returnData, address[] memory users)
        internal
    {
        if (success) {
            _after(users);
            _claimMultipleLoanProcessCollateral();

            if (actors.lender != address(spro)) {
                invariant_CLAIMMUL_01();
                invariant_CLAIMMUL_02();
            }
            invariant_CLAIMMUL_03();
        } else {
            invariant_ERR(returnData);
        }
        _clean();
    }

    function _transferNFTPostconditions(bool success, bytes memory returnData, uint256 loanId, address to) internal {
        if (success) {
            _setActorState(1, address(spro));
            _processCreditFromPaidBackLoans();

            invariant_GLOB_01();
            invariant_GLOB_02();
            assert(loanToken.ownerOf(loanId) == to);
        } else {
            invariant_ERR(returnData);
        }
        _clean();
    }

    function _repayLoanProcessCollateral(Spro.LoanWithId memory loanWithId) internal {
        if (
            state[0].loanStatus[loanWithId.loanId] == LoanStatus.REPAYABLE
                && state[1].loanStatus[loanWithId.loanId] == LoanStatus.NONE
                && lastOwnerOfLoan[loanWithId.loanId] == address(spro)
        ) {
            tokenReceivedByProtocol[loanWithId.loan.creditAddress] +=
                loanWithId.loan.principalAmount + loanWithId.loan.fixedInterestAmount;
        }
        collateralFromProposals[loanWithId.loan.collateralAddress] -= loanWithId.loan.collateralAmount;
    }

    function _repayMultipleLoanProcessCollateral() internal {
        for (uint256 i = 0; i < repayableLoanIds.length; i++) {
            if (
                state[0].loanStatus[repayableLoanIds[i]] == LoanStatus.REPAYABLE
                    && state[1].loanStatus[repayableLoanIds[i]] == LoanStatus.NONE
                    && lastOwnerOfLoan[repayableLoanIds[i]] == address(spro)
            ) {
                tokenReceivedByProtocol[repayableLoans[i].loan.creditAddress] +=
                    repayableLoans[i].loan.principalAmount + repayableLoans[i].loan.fixedInterestAmount;
            }
            collateralFromProposals[repayableLoans[i].loan.collateralAddress] -= repayableLoans[i].loan.collateralAmount;
        }
    }

    function _claimLoanProcessCollateral(Spro.LoanWithId memory loanWithId) internal {
        if (
            state[0].loanStatus[loanWithId.loanId] == LoanStatus.PAID_BACK
                && state[1].loanStatus[loanWithId.loanId] == LoanStatus.NONE && actors.lender == address(spro)
        ) {
            tokenReceivedByProtocol[loanWithId.loan.creditAddress] +=
                loanWithId.loan.principalAmount + loanWithId.loan.fixedInterestAmount;
        }
        if (
            state[0].loanStatus[loanWithId.loanId] == LoanStatus.NOT_REPAYABLE
                && state[1].loanStatus[loanWithId.loanId] == LoanStatus.NONE
                && lastOwnerOfLoan[loanWithId.loanId] != address(spro)
        ) {
            collateralFromProposals[loanWithId.loan.collateralAddress] -= loanWithId.loan.collateralAmount;
        }
    }

    function _claimMultipleLoanProcessCollateral() internal {
        for (uint256 i = 0; i < claimableLoanIds.length; i++) {
            if (
                state[0].loanStatus[claimableLoanIds[i]] == LoanStatus.PAID_BACK
                    && state[1].loanStatus[claimableLoanIds[i]] == LoanStatus.NONE && actors.lender == address(spro)
            ) {
                tokenReceivedByProtocol[claimableLoans[i].loan.creditAddress] +=
                    claimableLoans[i].loan.principalAmount + claimableLoans[i].loan.fixedInterestAmount;
            }
            if (
                state[0].loanStatus[claimableLoanIds[i]] == LoanStatus.NOT_REPAYABLE
                    && state[1].loanStatus[claimableLoanIds[i]] == LoanStatus.NONE
                    && lastOwnerOfLoan[claimableLoanIds[i]] != address(spro)
            ) {
                collateralFromProposals[claimableLoans[i].loan.collateralAddress] -=
                    claimableLoans[i].loan.collateralAmount;
            }
        }
    }
}
