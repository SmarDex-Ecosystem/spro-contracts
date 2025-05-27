// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { Test } from "forge-std/Test.sol";

import { LibPRNG } from "solady/src/utils/LibPRNG.sol";

contract FuzzActors is Test {
    address internal DEPLOYER;

    address internal constant USER1 = address(0x10000);
    address internal constant USER2 = address(0x20000);
    address internal constant USER3 = address(0x30000);

    address[] internal USERS = [USER1, USER2, USER3];

    function getRandomUsers(uint256 input, uint256 length) internal view returns (address[] memory actors) {
        require(length <= USERS.length, "Requested length exceeds USERS length");
        LibPRNG.PRNG memory rng = LibPRNG.PRNG(input);

        address[] memory shuffleUsers = USERS;
        LibPRNG.shuffle(rng, shuffleUsers);

        actors = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            actors[i] = shuffleUsers[i];
        }

        return actors;
    }

    function getAnotherUser(address user) internal view returns (address) {
        for (uint256 i = 0; i < USERS.length; i++) {
            if (USERS[i] != user) {
                return USERS[i];
            }
        }
        revert("No other user found");
    }

    function getRandomUserOrProtocol(uint256 seedUser, address protocol) internal view returns (address) {
        uint256 total = USERS.length + 1;
        uint256 index = seedUser % total;

        if (index < USERS.length) {
            return USERS[index];
        } else {
            return protocol;
        }
    }
}
