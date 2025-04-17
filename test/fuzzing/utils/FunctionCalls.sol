// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { FuzzActors } from "./FuzzActors.sol";
import { FuzzStorageVariables } from "../utils/FuzzStorageVariables.sol";

import { ISpro } from "src/interfaces/ISpro.sol";
import { ISproTypes } from "src/interfaces/ISproTypes.sol";

/**
 * @notice Helper contract containing low-level protocol function wrappers for fuzzing
 * @dev Emits call-specific events and handles direct encoded calls to the USDN protocol and its modules
 */
contract FunctionCalls is FuzzStorageVariables, FuzzActors {
    function _createProposal(
        address caller,
        address collateralAddress,
        uint256 collateralAmount,
        address creditAddress,
        uint256 availableCreditLimit,
        uint256 fixedInterestAmount,
        uint40 startTimestamp,
        uint40 loanExpiration
    ) internal returns (bool success, bytes memory returnData) {
        vm.prank(caller);
        (success, returnData) = address(spro).call(
            abi.encodeWithSelector(
                ISpro.createProposal.selector,
                collateralAddress,
                collateralAmount,
                creditAddress,
                availableCreditLimit,
                fixedInterestAmount,
                startTimestamp,
                loanExpiration,
                ""
            )
        );
    }

    function _cancelProposal(address caller, ISproTypes.Proposal memory proposal)
        internal
        returns (bool success, bytes memory returnData)
    {
        vm.prank(caller);
        (success, returnData) = address(spro).call(abi.encodeWithSelector(ISpro.cancelProposal.selector, proposal));
    }

    function _createLoan(address caller, ISproTypes.Proposal memory proposal, uint256 creditAmount)
        internal
        returns (bool success, bytes memory returnData)
    {
        vm.prank(caller);
        (success, returnData) =
            address(spro).call(abi.encodeWithSelector(ISpro.createLoan.selector, proposal, creditAmount, ""));
    }
}
