// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { Spro } from "src/spro/Spro.sol";

contract SproHandler is Spro {
    constructor(address _sdex, address _permit2, uint256 _fee, uint16 _percentage, address _owner)
        Spro(_sdex, _permit2, _fee, _percentage, _owner)
    { }

    function i_isLoanRepayable(LoanStatus status, uint40 loanExpiration) external view returns (bool canBeRepaid_) {
        canBeRepaid_ = _isLoanRepayable(status, loanExpiration);
    }
}
