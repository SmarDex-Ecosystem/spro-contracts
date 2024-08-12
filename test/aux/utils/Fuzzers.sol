// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import {Utils} from "test/aux/utils/Utils.sol";
import {MultiToken} from "MultiToken/MultiToken.sol";
import {SDSimpleLoanSimpleProposal} from "pwn/loan/terms/simple/proposal/SDSimpleLoanSimpleProposal.sol";

abstract contract Fuzzers is Utils {
    struct Vars {
        uint256 collateralAmount;
        uint256 creditAmount;
        uint256 availableCreditLimit;
        uint256 fixedInterestAmount;
        uint24 accruingInterestAPR;
        uint32 duration;
        uint40 expiration;
        uint256 allowedAcceptorPK;
        address allowedAcceptor;
        uint256 proposerPK;
        address proposer;
        bool isOffer;
    }

    function fuzzProposal(
        SDSimpleLoanSimpleProposal.Proposal memory p,
        uint256 minAvailableCreditLimit,
        bool isBelowThreshold
    ) internal view returns (SDSimpleLoanSimpleProposal.Proposal memory) {
        _fuzzCollateralCategory(p);
        _fuzzCredit(p, minAvailableCreditLimit, isBelowThreshold);

        p.fixedInterestAmount = bound(p.fixedInterestAmount, 0, (1_000 * p.creditAmount) / 1e4);
        p.accruingInterestAPR = uint24(bound(p.accruingInterestAPR, 0, 16e6)); // @note from SDSimpleLoan.MAX_ACCRUING_INTEREST_APR
        p.duration = uint32(bound(p.duration, 11 minutes, type(uint32).max) - 1);
        p.expiration = uint40(bound(p.expiration, getBlockTimestamp() + 10 minutes, type(uint40).max));
        p.isOffer = p.availableCreditLimit % 2 == 0;

        // Values not fuzzed, and don't require state from test contract
        p.checkCollateralStateFingerprint = false;
        p.collateralStateFingerprint = bytes32(0);
        p.refinancingLoanId = 0;
        p.nonceSpace = 0;

        return p;
    }

    // Helpers

    function _fuzzCollateralCategory(SDSimpleLoanSimpleProposal.Proposal memory p) internal pure {
        if (p.collateralCategory == MultiToken.Category.ERC20) {
            p.collateralAmount = bound(p.collateralAmount, 1e18, type(uint128).max);
        } else if (p.collateralCategory == MultiToken.Category.ERC721) {
            p.collateralAmount = 0;
            p.collateralId = bound(p.collateralId, 0, type(uint16).max);
        } else if (p.collateralCategory == MultiToken.Category.ERC1155) {
            p.collateralId = bound(p.collateralId, 0, type(uint16).max);
            p.collateralAmount = bound(p.collateralAmount, 1e2, type(uint128).max);
        }
    }

    function _fuzzCredit(SDSimpleLoanSimpleProposal.Proposal memory p, uint256 minAvailable, bool isBelowThreshold)
        internal
        pure
    {
        p.availableCreditLimit = bound(p.availableCreditLimit, minAvailable, type(uint128).max);

        if (p.availableCreditLimit == 0) {
            p.creditAmount = bound(p.creditAmount, 1, type(uint128).max);
        } else {
            uint256 minCreditAmount = (500 * p.availableCreditLimit) / 1e4;
            if (isBelowThreshold) {
                p.creditAmount = bound(p.creditAmount, minCreditAmount, ((9500 * p.availableCreditLimit) / 1e4) - 1);
            } else {
                p.creditAmount = bound(p.creditAmount, minCreditAmount, p.availableCreditLimit - 1);
            }
        }
    }
}
