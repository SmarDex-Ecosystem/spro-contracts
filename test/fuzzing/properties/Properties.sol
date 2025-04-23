// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Properties_PROP.sol";
import "./Properties_CANCEL.sol";
import "./Properties_ERR.sol";

contract Properties is Properties_PROP, Properties_CANCEL, Properties_ERR { }
