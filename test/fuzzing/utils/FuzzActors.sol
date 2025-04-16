// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract FuzzActors {
    address internal DEPLOYER;

    address internal constant USER1 = address(0x10000);
    address internal constant USER2 = address(0x20000);
    address internal constant USER3 = address(0x30000);

    address[] internal USERS = [USER1, USER2, USER3];

    function getRandomUsers(uint8 input) internal view returns (address, address) {
        uint16 safeInput = uint16(input);
        uint256 randomIndex1 = safeInput % USERS.length;
        uint256 randomIndex2 = (safeInput + 1) % USERS.length;

        while (randomIndex1 == randomIndex2) {
            randomIndex2 = (randomIndex2 + 1) % USERS.length;
        }

        return (USERS[randomIndex1], USERS[randomIndex2]);
    }
}
