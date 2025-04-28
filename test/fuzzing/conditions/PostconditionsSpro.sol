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
        address[] memory actors
    ) internal {
        if (success) {
            _after(actors);
            proposals.push(proposal);
            numberOfProposals++;
            invariant_PROP_01(proposal, actors[0]);
            invariant_PROP_02(actors[0]);
            invariant_PROP_03(actors[0]);
            invariant_PROP_04(proposal);
            invariant_PROP_05();
            invariant_PROP_06();
            invariant_PROP_07();
        } else {
            invariant_ERR(returnData);
        }
    }

    function _cancelProposalPostconditions(
        bool success,
        bytes memory returnData,
        ISproTypes.Proposal memory proposal,
        address[] memory actors
    ) internal {
        if (success) {
            _after(actors);
            for (uint256 i = 0; i < proposals.length; i++) {
                if (keccak256(abi.encode(proposal)) == keccak256(abi.encode(proposals[i]))) {
                    proposals[i] = proposals[proposals.length - 1];
                    proposals.pop();
                    break;
                }
            }
            bytes32 proposalHash = keccak256(abi.encode(proposal));
            invariant_CANCEL_01(proposalHash, actors[0]);
            invariant_CANCEL_02(proposalHash);
        } else {
            invariant_ERR(returnData);
        }
    }

    function _createLoanPostconditions(
        bool success,
        bytes memory returnData,
        uint256 creditAmount,
        ISproTypes.Proposal memory proposal,
        address[] memory actors
    ) internal {
        if (success) {
            _after(actors);
            uint256 loanId = abi.decode(returnData, (uint256));
            ISproTypes.Loan memory loan = spro.getLoan(loanId);
            loans.push(Spro.LoanWithId(loanId, loan));
            numberOfLoans++;
            invariant_LOAN_01(creditAmount, actors[1]);
            invariant_LOAN_02(actors[1]);
            invariant_LOAN_03(creditAmount, actors[0]);
            invariant_LOAN_04(actors[0]);
            invariant_LOAN_05(proposal);
            invariant_LOAN_06(creditAmount, proposal);
            invariant_LOAN_07(proposal);
            invariant_LOAN_08(proposal, loan);
        } else {
            invariant_ERR(returnData);
        }
    }

    function _repayLoanPostconditions(
        bool success,
        bytes memory returnData,
        Spro.LoanWithId memory loanWithId,
        LoanStatus statusBefore,
        address[] memory actors
    ) internal {
        if (success) {
            _after(actors);
            for (uint256 i = 0; i < loans.length; i++) {
                if (loans[i].loanId == loanWithId.loanId) {
                    loans[i] = loans[loans.length - 1];
                    loans.pop();
                    break;
                }
            }
            LoanStatus statusAfter = getStatus(loanWithId.loanId);
            invariant_REPAY_01(loanWithId);
            invariant_REPAY_02(loanWithId, statusBefore, statusAfter);
            invariant_REPAY_03(loanWithId, actors[1]);
            invariant_REPAY_04(loanWithId, actors[1]);
            invariant_ENDLOAN_01(actors[0], statusBefore);
            invariant_ENDLOAN_02(actors[0], statusBefore, statusAfter);
            invariant_ENDLOAN_03(statusBefore, statusAfter);
            invariant_ENDLOAN_04(loanWithId, actors[0], statusBefore, statusAfter);
            invariant_ENDLOAN_05(loanWithId, statusBefore, statusAfter);
        } else {
            invariant_ERR(returnData);
        }
        token2.blockTransfers(false, address(0));
    }

    function _claimLoanPostconditions(
        bool success,
        bytes memory returnData,
        Spro.LoanWithId memory loanWithId,
        LoanStatus statusBefore,
        address[] memory actors
    ) internal {
        if (success) {
            _after(actors);
            for (uint256 i = 0; i < loans.length; i++) {
                if (loans[i].loanId == loanWithId.loanId) {
                    loans[i] = loans[loans.length - 1];
                    loans.pop();
                    break;
                }
            }
            LoanStatus statusAfter = getStatus(loanWithId.loanId);
            invariant_CLAIM_01(statusBefore, statusAfter);
            invariant_CLAIM_02(loanWithId, statusBefore, statusAfter);
            invariant_CLAIM_03(loanWithId, statusBefore, statusAfter, actors[0]);
            invariant_ENDLOAN_01(actors[0], statusBefore);
            invariant_ENDLOAN_02(actors[0], statusBefore, statusAfter);
            invariant_ENDLOAN_03(statusBefore, statusAfter);
            invariant_ENDLOAN_04(loanWithId, actors[0], statusBefore, statusAfter);
            invariant_ENDLOAN_05(loanWithId, statusBefore, statusAfter);
        } else {
            invariant_ERR(returnData);
        }
    }
}
