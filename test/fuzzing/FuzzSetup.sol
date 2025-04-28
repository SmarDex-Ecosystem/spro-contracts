// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import { Spro } from "src/spro/Spro.sol";

import { FunctionCalls } from "./utils/FunctionCalls.sol";
import { T20 } from "test/helper/T20.sol";

contract FuzzSetup is FunctionCalls {
    function setup(address deployerContract) internal {
        DEPLOYER = deployerContract;
        sdex = new T20("SDEX", "SDEX");
        token1 = new T20("token1", "token1");
        token2 = new T20("token2", "token2");
        spro = new Spro(address(sdex), PERMIT2, FEE, PARTIAL_POSITION_BPS);
        MAX_SDEX_FEE = spro.MAX_SDEX_FEE();
        BPS_DIVISOR = spro.BPS_DIVISOR();
        mintTokens();
    }

    function mintTokens() internal {
        for (uint8 i = 0; i < USERS.length; i++) {
            address user = USERS[i];
            token1.mintAndApprove(user, 10_000 ether, address(spro), type(uint256).max);
            token2.mintAndApprove(user, 10_000 ether, address(spro), type(uint256).max);
            sdex.mintAndApprove(user, 0, address(spro), type(uint256).max);
            vm.deal(user, 30_000 ether);
        }
    }
}
