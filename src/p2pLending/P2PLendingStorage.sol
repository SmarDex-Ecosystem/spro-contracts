// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { IAllowanceTransfer } from "permit2/src/interfaces/IAllowanceTransfer.sol";

import { P2PLendingLoan } from "src/p2pLending/P2PLendingLoan.sol";
import { IP2PLendingStorage } from "src/interfaces/IP2PLendingStorage.sol";
import { IP2PLendingTypes } from "src/interfaces/IP2PLendingTypes.sol";

contract P2PLendingStorage is IP2PLendingStorage {
    /// @dev The address that will receive all fees.
    address internal constant DEAD_ADDRESS = address(0xdead);

    /// @inheritdoc IP2PLendingStorage
    uint256 public constant BPS_DIVISOR = 10_000;

    /// @inheritdoc IP2PLendingStorage
    uint256 public constant MAX_SDEX_FEE = 10_000_000e18; // 10,000,000 SDEX

    /// @inheritdoc IP2PLendingStorage
    uint32 public constant MIN_LOAN_DURATION = 10 minutes;

    /// @inheritdoc IP2PLendingStorage
    address public immutable SDEX;

    /// @inheritdoc IP2PLendingStorage
    IAllowanceTransfer public immutable PERMIT2;

    /// @inheritdoc IP2PLendingStorage
    uint256 public _proposalNonce;

    /// @inheritdoc IP2PLendingStorage
    uint16 public _partialPositionBps;

    /// @inheritdoc IP2PLendingStorage
    uint256 public _fee;

    /// @inheritdoc IP2PLendingStorage
    P2PLendingLoan public immutable _loanToken;

    /// @inheritdoc IP2PLendingStorage
    mapping(bytes32 => uint256) public _withdrawableCollateral;

    /// @inheritdoc IP2PLendingStorage
    mapping(bytes32 => bool) public _proposalsMade;

    /// @inheritdoc IP2PLendingStorage
    mapping(bytes32 => uint256) public _creditUsed;

    /// @notice Mapping of all loan data by loan id.
    mapping(uint256 => IP2PLendingTypes.Loan) internal _loans;
}
