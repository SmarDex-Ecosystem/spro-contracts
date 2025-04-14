// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";

import { T20 } from "test/helper/T20.sol";

import { ISproTypes } from "src/interfaces/ISproTypes.sol";

contract Properties_PROP is Test {
    function invariant_PROP_01(ISproTypes.Proposal memory proposal, uint256 previous) internal view {
        uint256 collateralBalanceBorrower = T20(proposal.collateralAddress).balanceOf(proposal.proposer);
        assert(collateralBalanceBorrower == previous - proposal.collateralAmount);
    }

    function invariant_PROP_02(address sdex, ISproTypes.Proposal memory proposal, uint256 previous, uint256 fee)
        internal
        view
    {
        uint256 sdexBalanceBorrower = T20(sdex).balanceOf(proposal.proposer);
        assert(sdexBalanceBorrower == previous - fee);
    }

    function invariant_PROP_03(ISproTypes.Proposal memory proposal, uint256 previous) internal view {
        uint256 creditBalanceBorrower = T20(proposal.creditAddress).balanceOf(proposal.proposer);
        assert(creditBalanceBorrower == previous);
    }

    function invariant_PROP_04(address protocol, ISproTypes.Proposal memory proposal, uint256 previous) internal view {
        uint256 collateralBalanceProtocol = T20(proposal.collateralAddress).balanceOf(protocol);
        assert(collateralBalanceProtocol == previous + proposal.collateralAmount);
    }

    function invariant_PROP_05(address protocol, ISproTypes.Proposal memory proposal, uint256 previous) internal view {
        uint256 creditBalanceProtocol = T20(proposal.creditAddress).balanceOf(protocol);
        assert(creditBalanceProtocol == previous);
    }

    function invariant_PROP_06(uint256 _proposalNonce, uint256 numberOfProposal) internal pure {
        assert(_proposalNonce == numberOfProposal);
    }

    function invariant_PROP_07(address sdex, uint256 _fee, uint256 previous) internal view {
        uint256 sdexBalanceDeadAddress = T20(sdex).balanceOf(address(0xdead));
        assert(sdexBalanceDeadAddress == previous + _fee);
    }
}
