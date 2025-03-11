// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IAllowanceTransfer } from "permit2/src/interfaces/IAllowanceTransfer.sol";

import { SproLoan } from "src/spro/SproLoan.sol";

interface ISproStorage {
    /// @notice Gets the dead address.
    function DEAD_ADDRESS() external view returns (address);

    /// @notice Gets the divisor for basis point (BPS) values.
    function BPS_DIVISOR() external view returns (uint256);

    /// @notice Gets the maximum SDEX fee allowed.
    function MAX_SDEX_FEE() external view returns (uint256);

    /// @notice Gets the minimum loan duration allowed.
    function MIN_LOAN_DURATION() external view returns (uint32);

    /// @notice Gets the SDEX token address.
    function SDEX() external view returns (address);

    /// @notice Gets the permit2 contract address.
    function PERMIT2() external view returns (IAllowanceTransfer);

    /// @notice Gets the minimum usage ratio for partial lending (in basis points).
    function _partialPositionBps() external view returns (uint16);

    /// @notice Gets the protocol fixed SDEX fee value.
    function _fee() external view returns (uint256);

    /// @notice Gets the {SproLoan} contract address.
    function _loanToken() external view returns (SproLoan);

    /// @notice Gets the withdrawable collateral amount for a given proposal hash.
    function _withdrawableCollateral(bytes32 proposalHash) external view returns (uint256);

    /// @notice Checks if a proposal has already been made.
    function _proposalsMade(bytes32 proposalHash) external view returns (bool);

    /// @notice Gets the credit already used for a given proposal hash.
    function _creditUsed(bytes32 proposalHash) external view returns (uint256);
}
