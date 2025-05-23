// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Properties_PROP.sol";
import "./Properties_CANCEL.sol";
import "./Properties_ERR.sol";
import "./Properties_LOAN.sol";
import "./Properties_REPAY.sol";
import "./Properties_REPAYMUL.sol";
import "./Properties_ENDLOAN.sol";
import "./Properties_CLAIM.sol";

contract Properties is
    Properties_PROP,
    Properties_CANCEL,
    Properties_LOAN,
    Properties_REPAY,
    Properties_REPAYMUL,
    Properties_ENDLOAN,
    Properties_CLAIM,
    Properties_ERR
{ }
