// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { Spro, Permit } from "src/spro/Spro.sol";

contract SproHandler is Spro {
    constructor(
        address _sdex,
        address _owner,
        uint256 _fixFeeUnlisted,
        uint256 _fixFeeListed,
        uint256 _variableFactor,
        uint16 _percentage
    ) Spro(_sdex, _owner, _fixFeeUnlisted, _fixFeeListed, _variableFactor, _percentage) { }

    function exposed_checkPermit(address caller, address creditAddress, Permit memory permit) external pure {
        _checkPermit(caller, creditAddress, permit);
    }

    function exposed_checkLoanCanBeRepaid(uint8 status, uint40 defaultTimestamp) external view {
        _checkLoanCanBeRepaid(status, defaultTimestamp);
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
        _withdrawCreditFromPool(credit, creditAmount, loanTerms, lenderSpec);
    }

    function exposed_checkCompleteLoan(uint256 _creditAmount, uint256 _availableCreditLimit) external pure {
        _checkCompleteLoan(_creditAmount, _availableCreditLimit);
    }
}
