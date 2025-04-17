// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract FuzzActors {
    address internal DEPLOYER;

    address internal constant USER1 = address(0x10000);
    address internal constant USER2 = address(0x20000);
    address internal constant USER3 = address(0x30000);

    address[] internal USERS = [USER1, USER2, USER3];

    function getRandomUsers(uint256 input) internal view returns (address[] memory actors) {
        uint256 randomIndex1 = input % USERS.length;
        uint256 randomIndex2;
        if (input == 0) {
            randomIndex2 = (input + 1) % USERS.length;
        } else {
            randomIndex2 = (input - 1) % USERS.length;
        }

        while (randomIndex1 == randomIndex2) {
            randomIndex2 = (randomIndex2 - 1) % USERS.length;
        }

        actors = new address[](2);
        actors[0] = USERS[randomIndex1];
        actors[1] = USERS[randomIndex2];
    }

    function getAnotherUser(address user) internal view returns (address) {
        for (uint256 i = 0; i < USERS.length; i++) {
            if (USERS[i] != user) {
                return USERS[i];
            }
        }
        revert("No other user found");
    }
}
