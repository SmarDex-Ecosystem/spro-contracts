// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";

import { T20 } from "test/helper/T20.sol";

import { ISproTypes } from "src/interfaces/ISproTypes.sol";
import { Spro } from "src/spro/Spro.sol";

contract Properties_CANCEL is Test {
    function invariant_CANCEL_01(address spro, ISproTypes.Proposal memory proposal, uint256 previous) internal view {
        bytes32 proposalHash = keccak256(abi.encode(proposal));
        uint256 withdrawableCollateralAmount = Spro(spro)._withdrawableCollateral(proposalHash);
        uint256 collateralBalanceBorrower = T20(proposal.collateralAddress).balanceOf(proposal.proposer);
        assert(collateralBalanceBorrower == previous + withdrawableCollateralAmount);
    }

    function invariant_CANCEL_02(address spro, ISproTypes.Proposal memory proposal, uint256 previous) internal view {
        bytes32 proposalHash = keccak256(abi.encode(proposal));
        uint256 withdrawableCollateralAmount = Spro(spro)._withdrawableCollateral(proposalHash);
        uint256 collateralBalanceProtocol = T20(proposal.collateralAddress).balanceOf(spro);
        assert(collateralBalanceProtocol == previous - withdrawableCollateralAmount);
    }
}
