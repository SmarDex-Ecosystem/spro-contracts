// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { IAllowanceTransfer } from "permit2/src/interfaces/IAllowanceTransfer.sol";

import { SproLoan } from "src/spro/SproLoan.sol";
import { ISproStorage } from "src/interfaces/ISproStorage.sol";
import { ISproTypes } from "src/interfaces/ISproTypes.sol";

contract SproStorage is ISproStorage {
    /// @dev The address that will receive all fees.
    address internal constant DEAD_ADDRESS = address(0xdead);

    /// @inheritdoc ISproStorage
    uint256 public constant BPS_DIVISOR = 10_000;

    /// @inheritdoc ISproStorage
    uint256 public constant MAX_SDEX_FEE = 1_000_000e18; // 1,000,000 SDEX

    /// @inheritdoc ISproStorage
    uint32 public constant MIN_LOAN_DURATION = 10 minutes;

    /// @inheritdoc ISproStorage
    address public immutable SDEX;

    /// @inheritdoc ISproStorage
    IAllowanceTransfer public immutable PERMIT2;

    /// @inheritdoc ISproStorage
    uint256 public _proposalNonce;

    /// @inheritdoc ISproStorage
    uint16 public _partialPositionBps;

    /// @inheritdoc ISproStorage
    uint256 public _fee;

    /// @inheritdoc ISproStorage
    SproLoan public immutable _loanToken;

    /// @inheritdoc ISproStorage
    mapping(bytes32 => uint256) public _withdrawableCollateral;

    /// @inheritdoc ISproStorage
    mapping(bytes32 => bool) public _proposalsMade;

    /// @inheritdoc ISproStorage
    mapping(bytes32 => uint256) public _creditUsed;

    /// @notice Mapping of all loan data by loan id.
    mapping(uint256 => ISproTypes.Loan) internal _loans;
}
