// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { ISproTypes } from "src/interfaces/ISproTypes.sol";

contract FuzzStructs {
    struct createProposalParams {
        uint256 numberOfProposals;
    }

    struct CancelProposalParams {
        uint256 numberOfProposals;
    }

    struct CreateLoanParams {
        ISproTypes.Proposal proposal;
        ISproTypes.Loan[] correspondingLoans;
    }

    struct RepayLoanParams {
        ISproTypes.Proposal proposal;
        ISproTypes.Loan loan;
        ISproTypes.LoanStatus statusBefore;
    }

    struct ClaimLoanParams {
        ISproTypes.Proposal proposal;
        ISproTypes.Loan loan;
        ISproTypes.LoanStatus statusBefore;
    }
}
