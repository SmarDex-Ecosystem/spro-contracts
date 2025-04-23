// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.26;

import { Test } from "forge-std/Test.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { FixedPointMathLib } from "solady/src/utils/FixedPointMathLib.sol";

import { Properties } from "../properties/Properties.sol";

import { ISproTypes } from "src/interfaces/ISproTypes.sol";
import { Spro } from "src/spro/Spro.sol";

contract PreconditionsSpro is Test, Properties {
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
            minAmount: Math.mulDiv(availableCreditLimit, spro._partialPositionBps(), spro.BPS_DIVISOR())
        });
    }

    function _createLoanPreconditions(uint256 seed, ISproTypes.Proposal memory proposal, address lender)
        internal
        view
        returns (uint256 creditAmount)
    {
        proposal = getRandomProposal(seed);
        if (seed == proposal.availableCreditLimit - spro._creditUsed(keccak256(abi.encode(proposal)))) {
            creditAmount = seed;
        } else {
            uint256 maxCreditAmount = FixedPointMathLib.min(
                proposal.availableCreditLimit - spro._creditUsed(keccak256(abi.encode(proposal))) - proposal.minAmount,
                token2.balanceOf(lender)
            );
            creditAmount = bound(seed, proposal.minAmount, maxCreditAmount);
        }
    }
}
