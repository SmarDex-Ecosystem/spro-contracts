// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IAllowanceTransfer } from "permit2/src/interfaces/IAllowanceTransfer.sol";

import { SproLoan } from "src/spro/SproLoan.sol";

/**
 * @title ISproStorage
 * @notice Interface for the storage layer of the Spro protocol
 */
interface ISproStorage {
    /* -------------------------------------------------------------------------- */
    /*                                   CONFIG                                   */
    /* -------------------------------------------------------------------------- */

    /// @notice Get SDEX token address.
    function SDEX() external view returns (address);

    /// @notice Get Permit2 contract address.
    function PERMIT2() external view returns (IAllowanceTransfer);

    /// @notice Get percentage of a proposal's available credit limit used in partial lending (in basis points).
    function _partialPositionBps() external view returns (uint16);

    /**
     * @notice Get protocol fee value.
     * @dev Amount of SDEX tokens (units 1e18).
     */
    function _fee() external view returns (uint256);

    /// @notice Get registered pool adapter for a pool address.
    function _poolAdapterRegistry(address poolAddress) external view returns (address);

    /* -------------------------------------------------------------------------- */
    /*                                    LOAN                                    */
    /* -------------------------------------------------------------------------- */

    /// @notice Get SproLoan contract.
    function _loanToken() external view returns (SproLoan);

    /* -------------------------------------------------------------------------- */
    /*                                  PROPOSAL                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Get withdrawable collateral tokens for a given proposal hash.
    function _withdrawableCollateral(bytes32 proposalHash) external view returns (uint256);

    /// @notice Check if a proposal is made for a given proposal hash.
    function _proposalsMade(bytes32 proposalHash) external view returns (bool);

    /// @notice Get the credit used by a proposal for a given proposal hash.
    function _creditUsed(bytes32 proposalHash) external view returns (uint256);
}
