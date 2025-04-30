// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.26;

import { Test } from "forge-std/Test.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { Properties } from "../properties/Properties.sol";

import { ISproTypes } from "src/interfaces/ISproTypes.sol";
import { Spro } from "src/spro/Spro.sol";

contract PreconditionsSpro is Test, Properties {
    function _setFeePreconditions(uint256 seed) internal view returns (uint256 fee) {
        fee = bound(seed, 0, MAX_SDEX_FEE);
    }

    function _setPartialPositionPercentagePreconditions(uint256 seed)
        internal
        view
        returns (uint16 partialPositionBps)
    {
        partialPositionBps = uint16(bound(seed, 1, BPS_DIVISOR / 2));
    }

    function _createProposalPreconditions(
        uint256 seed1,
        uint256 seed2,
        uint256 seed3,
        address borrower,
        uint40 startTimestamp,
        uint40 loanExpiration
    ) internal view returns (ISproTypes.Proposal memory proposal) {
        uint256 collateralAmount = bound(seed1, 0, token1.balanceOf(borrower));
        uint256 availableCreditLimit = bound(seed2, 1, token2.balanceOf(borrower));
        uint256 fixedInterestAmount = bound(seed3, 0, availableCreditLimit);
        proposal = ISproTypes.Proposal({
            collateralAddress: address(token1),
            collateralAmount: collateralAmount,
            creditAddress: address(token2),
            availableCreditLimit: availableCreditLimit,
            fixedInterestAmount: fixedInterestAmount,
            startTimestamp: startTimestamp,
            loanExpiration: loanExpiration,
            proposer: borrower,
            nonce: spro._proposalNonce(),
            minAmount: Math.mulDiv(availableCreditLimit, spro._partialPositionBps(), BPS_DIVISOR)
        });
    }

    function _createLoanPreconditions(uint256 seed, ISproTypes.Proposal memory proposal, address lender)
        internal
        returns (uint256 creditAmount)
    {
        uint256 remaining = proposal.availableCreditLimit - spro._creditUsed(keccak256(abi.encode(proposal)));
        creditAmount = bound(seed, proposal.minAmount, remaining);
        if (creditAmount > token2.balanceOf(lender)) {
            token2.mint(lender, creditAmount - token2.balanceOf(lender));
        }
    }

    function _repayLoanPreconditions(Spro.LoanWithId memory loanWithId, address payer) internal {
        uint256 repaymentAmount = loanWithId.loan.principalAmount + loanWithId.loan.fixedInterestAmount;
        if (repaymentAmount > token2.balanceOf(payer)) {
            token2.mint(payer, repaymentAmount);
        }
    }

    function _repayMultipleLoansPreconditions(Spro.LoanWithId[] memory loanWithId, address[] memory actors)
        internal
        returns (LoanStatus[] memory statusBefore, uint256[] memory loanIds)
    {
        uint256 warpTimestamp;
        for (uint256 i = 0; i < loanWithId.length; i++) {
            if (loanWithId[i].loan.startTimestamp > warpTimestamp) {
                warpTimestamp = loanWithId[i].loan.startTimestamp;
            }
            statusBefore[i] = getStatus(loanWithId[i].loanId);
            loanIds[i] = loanWithId[i].loanId;
        }
        uint256 totalRepaymentAmount = spro.totalLoanRepaymentAmount(loanIds);
        if (totalRepaymentAmount > token2.balanceOf(actors[0])) {
            token2.mint(actors[0], totalRepaymentAmount);
        }
    }
}
