// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { Test } from "forge-std/Test.sol";

contract FuzzActors is Test {
    address internal DEPLOYER;

    address internal constant USER1 = address(0x10000);
    address internal constant USER2 = address(0x20000);
    address internal constant USER3 = address(0x30000);

    address[] internal USERS = [USER1, USER2, USER3];

    function getRandomUsers(uint256 input) internal view returns (address[] memory actors) {
        actors = USERS;
        for (uint256 i = USERS.length - 1; i > 0; i--) {
            uint256 j = bound(input, 0, i - 1);
            (actors[i], actors[j]) = (actors[j], actors[i]);
        }

        return actors;
    }
}
