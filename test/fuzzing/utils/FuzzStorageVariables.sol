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
    ISproTypes.Proposal[] internal Proposals;
    ISproTypes.Loan[] internal Loans;

    function getRandomProposal(uint256 input) internal view returns (ISproTypes.Proposal memory) {
        uint256 randomIndex = input % Proposals.length;
        return Proposals[randomIndex];
    }
}
