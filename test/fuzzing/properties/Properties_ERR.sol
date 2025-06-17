// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.26;

import { ISproErrors } from "src/interfaces/ISproErrors.sol";

/**
 * @notice Invariants to detect unexpected or invalid error states
 * @dev Ensures that no unwhitelisted errors surface during execution
 */
contract Properties_ERR {
    event AssertFail(string);

    function invariant_ERR(bytes memory returnData) internal {
        bytes4 returnedError;
        assembly {
            returnedError := mload(add(returnData, 0x20))
        }

        bytes4[] memory allowedErrors = new bytes4[](5);

        // Create loan errors [0-1]
        allowedErrors[0] = ISproErrors.Expired.selector;
        allowedErrors[1] = ISproErrors.CreditAmountRemainingBelowMinimum.selector;

        // Create repay loan errors [2]
        allowedErrors[2] = ISproErrors.LoanCannotBeRepaid.selector;

        // Claim loan errors [3]
        allowedErrors[3] = ISproErrors.LoanRunning.selector;

        // EVM errors returns nothing
        allowedErrors[4] = bytes4(abi.encode(""));

        errAllow(returnedError, allowedErrors, "ERR_01: Non-whitelisted error should never appear in a call");
    }

    function errAllow(bytes4 errorSelector, bytes4[] memory allowedErrors, string memory message) internal {
        bool allowed = false;
        for (uint256 i = 0; i < allowedErrors.length; i++) {
            if (errorSelector == allowedErrors[i]) {
                allowed = true;
                break;
            }
        }
        if (!allowed) {
            emit AssertFail(message);
            assert(false);
        }
    }
}
