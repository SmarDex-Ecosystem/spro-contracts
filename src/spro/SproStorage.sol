// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { SproLoan } from "src/spro/SproLoan.sol";
import { ISproStorage } from "src/interfaces/ISproStorage.sol";
import { ISproTypes } from "src/interfaces/ISproTypes.sol";

contract SproStorage is ISproStorage {
    /* -------------------------------------------------------------------------- */
    /*                                   CONFIG                                   */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ISproStorage
    address public immutable SDEX;

    /// @inheritdoc ISproStorage
    uint16 public partialPositionBps;

    /// @inheritdoc ISproStorage
    uint256 public fee;

    /// @inheritdoc ISproStorage
    mapping(address => string) public _loanMetadataUri;

    /// @inheritdoc ISproStorage
    mapping(address => address) public _poolAdapterRegistry;

    /* -------------------------------------------------------------------------- */
    /*                                    LOAN                                    */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ISproStorage
    SproLoan public immutable loanToken;

    /// @notice  Mapping of all Loan data by loan id.
    mapping(uint256 => ISproTypes.Loan) internal Loans;

    /* -------------------------------------------------------------------------- */
    /*                                  PROPOSAL                                  */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ISproStorage
    mapping(bytes32 => uint256) public withdrawableCollateral;

    /// @inheritdoc ISproStorage
    mapping(bytes32 => bool) public proposalsMade;

    /// @inheritdoc ISproStorage
    mapping(bytes32 => uint256) public creditUsed;
}
