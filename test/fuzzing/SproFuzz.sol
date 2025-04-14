// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { T20 } from "test/helper/T20.sol";
import { FuzzSetup } from "./FuzzSetup.sol";
import "./properties/Properties.sol";

import { ISproTypes } from "src/interfaces/ISproTypes.sol";

contract SproFuzz is FuzzSetup, Properties {
    constructor() payable {
        setup(address(this));
    }

    function fuzz_createProposal(uint8 seed, uint40 startTimestamp, uint40 loanExpiration) public {
        address borrower = getRandomUser(seed);
        uint256 collateralAmount = bound(seed, 0, token1.balanceOf(borrower));
        uint256 availableCreditLimit = bound(seed, 1, token2.balanceOf(borrower));
        uint256 fixedInterestAmount = bound(seed, 0, availableCreditLimit);

        ISproTypes.Proposal memory proposal = ISproTypes.Proposal({
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
        uint256 collateralBalanceBorrower = T20(proposal.collateralAddress).balanceOf(proposal.proposer);
        uint256 sdexBalanceBorrower = T20(sdex).balanceOf(proposal.proposer);
        uint256 creditBalanceBorrower = T20(proposal.creditAddress).balanceOf(proposal.proposer);
        uint256 collateralBalanceProtocol = T20(proposal.collateralAddress).balanceOf(address(spro));
        uint256 creditBalanceProtocol = T20(proposal.creditAddress).balanceOf(address(spro));
        uint256 sdexBalanceProtocol = T20(sdex).balanceOf(address(0xdead));

        vm.prank(borrower);
        try spro.createProposal(
            proposal.collateralAddress,
            proposal.collateralAmount,
            proposal.creditAddress,
            proposal.availableCreditLimit,
            proposal.fixedInterestAmount,
            proposal.startTimestamp,
            proposal.loanExpiration,
            ""
        ) {
            Proposals.push(proposal);
            invariant_PROP_01(proposal, collateralBalanceBorrower);
            invariant_PROP_02(address(sdex), proposal, sdexBalanceBorrower, spro._fee());
            invariant_PROP_03(proposal, creditBalanceBorrower);
            invariant_PROP_04(address(spro), proposal, collateralBalanceProtocol);
            invariant_PROP_05(address(spro), proposal, creditBalanceProtocol);
            invariant_PROP_06(spro._proposalNonce(), Proposals.length);
            invariant_PROP_07(address(sdex), spro._fee(), sdexBalanceProtocol);
        } catch (bytes memory error) {
            invariant_ERR(error);
        }
    }
}
