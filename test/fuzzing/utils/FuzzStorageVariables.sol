// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { Test } from "forge-std/Test.sol";

import { Spro } from "src/spro/Spro.sol";
import { ISproTypes } from "src/interfaces/ISproTypes.sol";

import { T20 } from "test/helper/T20.sol";

contract FuzzStorageVariables is Test {
    T20 sdex;
    T20 token1;
    T20 token2;
    Spro spro;
    uint256 numberOfProposals;

    // Spro initialization
    address payable constant PERMIT2 = payable(address(0x000000000022D473030F116dDEE9F6B43aC78BA3));
    uint256 public constant FEE = 20e18;
    uint16 public constant PARTIAL_POSITION_BPS = 500;

    // Spro storage variables
    ISproTypes.Proposal[] internal proposals;
    ISproTypes.Loan[] internal loans;

    mapping(uint8 => State) state;

    struct State {
        mapping(address => ActorStates) actorStates;
        address borrower;
        address lender;
    }

    struct ActorStates {
        uint256 collateralBalance;
        uint256 creditBalance;
        uint256 sdexBalance;
    }

    function _setStates(uint8 index, address borrower, address lender) internal {
        state[index].borrower = borrower;
        state[index].lender = lender;
        state[index].actorStates[borrower].collateralBalance = T20(token1).balanceOf(borrower);
        state[index].actorStates[borrower].creditBalance = T20(token2).balanceOf(borrower);
        state[index].actorStates[borrower].sdexBalance = T20(sdex).balanceOf(borrower);
        state[index].actorStates[lender].collateralBalance = T20(token1).balanceOf(lender);
        state[index].actorStates[lender].creditBalance = T20(token2).balanceOf(lender);
        state[index].actorStates[lender].sdexBalance = T20(sdex).balanceOf(lender);
        state[index].actorStates[address(spro)].collateralBalance = T20(token1).balanceOf(address(spro));
        state[index].actorStates[address(spro)].creditBalance = T20(token2).balanceOf(address(spro));
        state[index].actorStates[address(spro)].sdexBalance = T20(sdex).balanceOf(address(spro));
        state[index].actorStates[address(0xdead)].sdexBalance = T20(sdex).balanceOf(address(0xdead));
    }
}
