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
        uint256 token2Balance = token2.balanceOf(borrower);
        uint256 availableCreditLimit = bound(seed2, 1, token2Balance == 0 ? 1 : token2Balance);
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

    function _createLoanPreconditions(uint256 seed, ISproTypes.Proposal memory proposal)
        internal
        returns (uint256 creditAmount)
    {
        uint256 remaining = proposal.availableCreditLimit - spro._creditUsed(keccak256(abi.encode(proposal)));
        creditAmount = bound(seed, proposal.minAmount, remaining);
        _ensureSufficientBalance(actors.lender, creditAmount);
    }

    function _repayLoanPreconditions(Spro.LoanWithId memory loanWithId, bool blocked) internal {
        if (blocked && actors.lender != address(spro)) {
            token2.blockTransfers(true, actors.lender);
        }
        uint256 repaymentAmount = loanWithId.loan.principalAmount + loanWithId.loan.fixedInterestAmount;
        _ensureSufficientBalance(actors.payer, repaymentAmount);
    }

    function _repayMultipleLoansPreconditions(Spro.LoanWithId[] memory loanWithId, bool blocked, address userBlocked)
        internal
        returns (uint256 totalRepaymentAmount)
    {
        uint256 firstRepayable = _findFirstRepayableLoanIndex(loanWithId);
        if (firstRepayable == loanWithId.length) {
            return 0;
        }

        (uint256[] memory validLoanIds, Spro.LoanWithId[] memory validLoanWithId, uint256 totalAmount) =
            _filterRepayableLoansWithSameCreditAddress(loanWithId, firstRepayable);

        _ensureSufficientBalance(actors.payer, totalAmount);
        _storeRepayableLoans(validLoanIds, validLoanWithId);

        if (blocked) {
            token2.blockTransfers(true, userBlocked);
        }

        return totalAmount;
    }

    function _findFirstRepayableLoanIndex(Spro.LoanWithId[] memory loanWithId) internal view returns (uint256 index) {
        while (
            !spro.i_isLoanRepayable(spro.getLoan(loanWithId[index].loanId).status, loanWithId[index].loan.loanExpiration)
        ) {
            index++;
            if (index == loanWithId.length) {
                break;
            }
        }
    }

    function _filterRepayableLoansWithSameCreditAddress(Spro.LoanWithId[] memory loanWithId, uint256 start)
        internal
        view
        returns (uint256[] memory loanIds, Spro.LoanWithId[] memory loans, uint256 totalAmount)
    {
        address creditAddress = loanWithId[start].loan.creditAddress;
        uint256 count;

        loanIds = new uint256[](loanWithId.length);
        loans = new Spro.LoanWithId[](loanWithId.length);

        for (uint256 i = start; i < loanWithId.length; i++) {
            if (
                loanWithId[i].loan.creditAddress == creditAddress
                    && spro.i_isLoanRepayable(spro.getLoan(loanWithId[i].loanId).status, loanWithId[i].loan.loanExpiration)
            ) {
                loanIds[count] = loanWithId[i].loanId;
                loans[count] = loanWithId[i];
                totalAmount += loanWithId[i].loan.principalAmount + loanWithId[i].loan.fixedInterestAmount;
                count++;
            }
        }
        assembly {
            mstore(loanIds, count)
            mstore(loans, count)
        }
    }

    function _storeRepayableLoans(uint256[] memory loanIds, Spro.LoanWithId[] memory loans) internal {
        for (uint256 i = 0; i < loanIds.length; i++) {
            repayableLoanIds.push(loanIds[i]);
            repayableLoans.push(loans[i]);
        }
    }

    function _claimMultipleLoansPreconditions(Spro.LoanWithId[] memory loanWithId) internal returns (bool) {
        uint256 firstClaimable = _findFirstClaimableLoanIndex(loanWithId);
        if (firstClaimable == loanWithId.length) {
            return false;
        }

        (uint256[] memory validLoanIds, Spro.LoanWithId[] memory validLoanWithId) =
            _filterClaimableLoansWithSameLender(loanWithId, firstClaimable);

        _storeClaimableLoans(validLoanIds, validLoanWithId);

        return true;
    }

    function _findFirstClaimableLoanIndex(Spro.LoanWithId[] memory loanWithId) internal view returns (uint256 index) {
        while (
            spro.i_isLoanRepayable(spro.getLoan(loanWithId[index].loanId).status, loanWithId[index].loan.loanExpiration)
        ) {
            index++;
            if (index == loanWithId.length) {
                break;
            }
        }
    }

    function _filterClaimableLoansWithSameLender(Spro.LoanWithId[] memory loanWithId, uint256 start)
        internal
        returns (uint256[] memory loanIds, Spro.LoanWithId[] memory loans)
    {
        uint256 count;
        loanIds = new uint256[](loanWithId.length);
        loans = new Spro.LoanWithId[](loanWithId.length);
        actors.lender = loanToken.ownerOf(loanWithId[start].loanId);

        for (uint256 i = start; i < loanWithId.length; i++) {
            if (
                !spro.i_isLoanRepayable(spro.getLoan(loanWithId[i].loanId).status, loanWithId[i].loan.loanExpiration)
                    && loanToken.ownerOf(loanWithId[i].loanId) == actors.lender
                    || spro.getLoan(loanWithId[i].loanId).status != ISproTypes.LoanStatus.PAID_BACK
                        && loanToken.ownerOf(loanWithId[i].loanId) == actors.lender
            ) {
                loanIds[count] = loanWithId[i].loanId;
                loans[count] = loanWithId[i];
                count++;
            }
        }

        assembly {
            mstore(loanIds, count)
            mstore(loans, count)
        }
    }

    function _storeClaimableLoans(uint256[] memory loanIds, Spro.LoanWithId[] memory loans) internal {
        for (uint256 i = 0; i < loanIds.length; i++) {
            claimableLoanIds.push(loanIds[i]);
            claimableLoans.push(loans[i]);
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                    Utils                                   */
    /* -------------------------------------------------------------------------- */

    function _ensureSufficientBalance(address payer, uint256 requiredAmount) internal {
        uint256 currentBalance = token2.balanceOf(payer);
        if (requiredAmount > currentBalance) {
            token2.mint(payer, requiredAmount - currentBalance);
        }
    }
}
