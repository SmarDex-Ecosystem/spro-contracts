// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract FuzzActors {
    address internal DEPLOYER;

    address internal constant USER1 = address(0x10000);
    address internal constant USER2 = address(0x20000);
    address internal constant USER3 = address(0x30000);

    address[] internal USERS = [USER1, USER2, USER3];

    function getRandomUser(uint8 input) internal view returns (address) {
        uint256 randomIndex = input % USERS.length;
        return USERS[randomIndex];
    }
}
