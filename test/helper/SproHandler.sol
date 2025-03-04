// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Spro } from "src/spro/Spro.sol";

contract SproHandler is Spro {
    constructor(address _sdex, address _permit2, uint256 _fee, uint16 _percentage)
        Spro(_sdex, _permit2, _fee, _percentage)
    { }

    function exposed_checkLoanCreditAddress(address loanCreditAddress, address expectedCreditAddress) external pure {
        _checkLoanCreditAddress(loanCreditAddress, expectedCreditAddress);
    }
}
