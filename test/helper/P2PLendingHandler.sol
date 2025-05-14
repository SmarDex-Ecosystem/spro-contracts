// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { P2PLending } from "src/p2pLending/P2PLending.sol";

contract P2PLendingHandler is P2PLending {
    constructor(address _sdex, address _permit2, uint256 _fee, uint16 _percentage, address _owner)
        P2PLending(_sdex, _permit2, _fee, _percentage, _owner)
    { }

    function i_isLoanRepayable(LoanStatus status, uint40 loanExpiration) external view returns (bool canBeRepaid_) {
        canBeRepaid_ = _isLoanRepayable(status, loanExpiration);
    }
}
