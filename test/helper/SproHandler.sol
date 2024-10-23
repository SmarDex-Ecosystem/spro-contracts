// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Spro } from "src/spro/Spro.sol";

contract SproHandler is Spro {
    constructor(address _sdex, address _permit2, uint256 _fee, uint16 _percentage)
        Spro(_sdex, _permit2, _fee, _percentage)
    { }

    function exposed_checkLoanCanBeRepaid(LoanStatus status, uint40 loanExpiration) external view {
        _checkLoanCanBeRepaid(status, loanExpiration);
    }

    function exposed_checkLoanCreditAddress(address loanCreditAddress, address expectedCreditAddress) external pure {
        _checkLoanCreditAddress(loanCreditAddress, expectedCreditAddress);
    }

    function exposed_withdrawCreditFromPool(
        address credit,
        uint256 creditAmount,
        Terms memory loanTerms,
        LenderSpec calldata lenderSpec
    ) external {
        _withdrawCreditFromPool(
            credit, creditAmount, loanTerms.lender, lenderSpec.poolAdapter, lenderSpec.sourceOfFunds
        );
    }

    function exposed_checkCompleteLoan(uint256 _creditAmount, uint256 _availableCreditLimit) external pure {
        _checkCompleteLoan(_creditAmount, _availableCreditLimit);
    }
}
