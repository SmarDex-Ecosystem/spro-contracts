// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { ISproTypes } from "./ISproTypes.sol";

/**
 * @title ISproEvents
 * @notice Events for the Spro Protocol
 */
interface ISproEvents is ISproTypes {
    /**
     * @notice Emitted when asset transfer happens from an `origin` address to a vault.
     */
    event VaultPull(address asset, address indexed origin, uint256 amount);

    /**
     * @notice Emitted when asset transfer happens from a vault to a `beneficiary` address.
     */
    event VaultPush(address asset, address indexed beneficiary, uint256 amount);

    /**
     * @notice Emitted when asset transfer happens from an `origin` address to a `beneficiary` address.
     */
    event VaultPushFrom(address asset, address indexed origin, address indexed beneficiary, uint256 amount);

    /**
     * @notice Emitted when asset is withdrawn from a pool to an `owner` address.
     */
    event PoolWithdraw(
        address asset, address indexed poolAdapter, address indexed pool, address indexed owner, uint256 amount
    );

    /**
     * @notice Emitted when asset is supplied to a pool from a vault.
     */
    event PoolSupply(
        address asset, address indexed poolAdapter, address indexed pool, address indexed owner, uint256 amount
    );

    /**
     * @notice Emitted when new listed fee is set.
     */
    event FixFeeListedUpdated(uint256 oldFee, uint256 newFee);

    /**
     * @notice Emitted when new unlisted fee is set.
     */
    event FixFeeUnlistedUpdated(uint256 oldFee, uint256 newFee);

    /**
     * @notice Emitted when new variable factor is set.
     */
    event VariableFactorUpdated(uint256 oldFactor, uint256 newFactor);

    /**
     * @notice Emitted when a listed token factor is set.
     */
    event ListedTokenUpdated(address token, uint256 factor);

    /**
     * @notice Emitted when new LOAN token metadata uri is set.
     */
    event LOANMetadataUriUpdated(address indexed loanContract, string newUri);

    /**
     * @notice Emitted when new default LOAN token metadata uri is set.
     */
    event DefaultLOANMetadataUriUpdated(string newUri);

    /**
     * @notice Emitted when a new loan in created.
     */
    event LOANCreated(
        uint256 indexed loanId,
        bytes32 indexed proposalHash,
        address indexed proposalContract,
        Terms terms,
        LenderSpec lenderSpec,
        bytes extra
    );

    /**
     * @notice Emitted when a loan is paid back.
     */
    event LOANPaidBack(uint256 indexed loanId);

    /**
     * @notice Emitted when a repaid or defaulted loan is claimed.
     */
    event LOANClaimed(uint256 indexed loanId, bool indexed defaulted);

    /**
     * @notice Emitted when a proposal is made via an on-chain transaction.
     */
    event ProposalMade(bytes32 indexed proposalHash, address indexed proposer, Proposal proposal);
}
