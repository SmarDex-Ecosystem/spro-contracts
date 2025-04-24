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
        spro = new SproHandler(address(sdex), PERMIT2, FEE, PARTIAL_POSITION_BPS);
        mintTokens();
    }

    function mintTokens() internal {
        for (uint8 i = 0; i < USERS.length; i++) {
            address user = USERS[i];
            token1.mintAndApprove(user, 10_000 ether, address(spro), type(uint256).max);
            token2.mintAndApprove(user, 10_000 ether, address(spro), type(uint256).max);
            sdex.mintAndApprove(user, 10_000 ether, address(spro), type(uint256).max);
            vm.deal(user, 30_000 ether);
        }
    }
}

contract SproHandler is Spro {
    constructor(address _sdex, address _permit2, uint256 _fee, uint16 _partialPositionBps)
        Spro(_sdex, _permit2, _fee, _partialPositionBps)
    { }

    function i_isLoanRepayable(LoanStatus status, uint40 loanExpiration) external view returns (bool canBeRepaid_) {
        canBeRepaid_ = _isLoanRepayable(status, loanExpiration);
    }
}
