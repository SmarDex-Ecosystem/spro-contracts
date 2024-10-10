// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import { SproLOAN } from "src/spro/SproLOAN.sol";
import { SproRevokedNonce } from "src/spro/SproRevokedNonce.sol";

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

    /// @notice SproRevokedNonce contract address.
    function revokedNonce() external view returns (SproRevokedNonce);

    /// @notice Get percentage of a proposal's available credit limit used in partial lending.
    function partialPositionPercentage() external view returns (uint16);

    /**
     * @notice Get protocol fixed fee for unlisted credit tokens.
     * @dev Amount of SDEX tokens (units 1e18).
     */
    function fixFeeUnlisted() external view returns (uint256);

    /**
     * @notice Get protocol fixed fee for listed credit tokens.
     * @dev Amount of SDEX tokens (units 1e18).
     */
    function fixFeeListed() external view returns (uint256);

    /**
     * @notice Get variable factor for calculating variable fee component for listed credit tokens.
     * @dev Units 1e18. Eg. factor of 40_000 == 4e22
     */
    function variableFactor() external view returns (uint256);

    /// @notice Get token factor for a listed credit token.
    function tokenFactors(address token) external view returns (uint256);

    /**
     * @notice Get loan metadata URI for a loan contract address.
     * @dev LOAN token minted by a loan contract will return metadata uri stored in this mapping.
     *      If there is no metadata uri for a loan contract, default metadata uri will be used stored under address(0).
     */
    function _loanMetadataUri(address loanContract) external view returns (string memory);

    /// @notice Get registered pool adapter for a pool address.
    function _poolAdapterRegistry(address poolAddress) external view returns (address);

    /* -------------------------------------------------------------------------- */
    /*                                    LOAN                                    */
    /* -------------------------------------------------------------------------- */

    /// @notice Get the DOMAIN_SEPARATOR_LOAN signature verification.
    function DOMAIN_SEPARATOR_LOAN() external view returns (bytes32);

    /// @notice Get SproLOAN contract.
    function loanToken() external view returns (SproLOAN);

    /* -------------------------------------------------------------------------- */
    /*                                  PROPOSAL                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Get the DOMAIN_SEPARATOR_PROPOSAL signature verification.
    function DOMAIN_SEPARATOR_PROPOSAL() external view returns (bytes32);

    /// @notice Get withdrawable collateral tokens for a given proposal hash.
    function withdrawableCollateral(bytes32 proposalHash) external view returns (uint256);

    /// @notice Check if a proposal is made for a given proposal hash.
    function proposalsMade(bytes32 proposalHash) external view returns (bool);

    /// @notice Get the credit used by a proposal for a given proposal hash.
    function creditUsed(bytes32 proposalHash) external view returns (uint256);
}
