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
     * @param asset The address of the asset.
     * @param origin The address of the origin.
     * @param amount The amount of the asset.
     */
    event VaultPull(address asset, address indexed origin, uint256 amount);

    /**
     * @notice Emitted when asset transfer happens from a vault to a `beneficiary` address.
     * @param asset The address of the asset.
     * @param beneficiary The address of the beneficiary.
     * @param amount The amount of the asset.
     */
    event VaultPush(address asset, address indexed beneficiary, uint256 amount);

    /**
     * @notice Emitted when asset transfer happens from an `origin` address to a `beneficiary` address.
     * @param asset The address of the asset.
     * @param origin The address of the origin.
     * @param beneficiary The address of the beneficiary.
     * @param amount The amount of the asset.
     */
    event VaultPushFrom(address asset, address indexed origin, address indexed beneficiary, uint256 amount);

    /**
     * @notice Emitted when asset is withdrawn from a pool to an `owner` address.
     * @param asset The address of the asset.
     * @param poolAdapter The address of the pool adapter.
     * @param pool The address of the pool.
     * @param owner The address of the owner.
     * @param amount The amount of the asset.
     */
    event PoolWithdraw(
        address asset, address indexed poolAdapter, address indexed pool, address indexed owner, uint256 amount
    );

    /**
     * @notice Emitted when asset is supplied to a pool from a vault.
     * @param asset The address of the asset.
     * @param poolAdapter The address of the pool adapter.
     * @param pool The address of the pool.
     * @param owner The address of the owner.
     * @param amount The amount of the asset.
     */
    event PoolSupply(
        address asset, address indexed poolAdapter, address indexed pool, address indexed owner, uint256 amount
    );

    /**
     * @notice Emitted when new listed fee is set.
     * @param oldFee The old fee.
     * @param newFee The new fee.
     */
    event FixFeeListedUpdated(uint256 oldFee, uint256 newFee);

    /**
     * @notice Emitted when new unlisted fee is set.
     * @param oldFee The old fee.
     * @param newFee The new fee.
     */
    event FixFeeUnlistedUpdated(uint256 oldFee, uint256 newFee);

    /**
     * @notice Emitted when new variable factor is set.
     * @param oldFactor The old factor.
     * @param newFactor The new factor.
     */
    event VariableFactorUpdated(uint256 oldFactor, uint256 newFactor);

    /**
     * @notice Emitted when a listed token factor is set.
     * @param token The address of the token.
     * @param factor The new factor.
     */
    event ListedTokenUpdated(address token, uint256 factor);

    /**
     * @notice Emitted when new LOAN token metadata uri is set.
     * @param loanContract The address of the loan contract.
     * @param newUri The new uri.
     */
    event LOANMetadataUriUpdated(address indexed loanContract, string newUri);

    /**
     * @notice Emitted when new default LOAN token metadata uri is set.
     * @param newUri The new default uri.
     */
    event DefaultLOANMetadataUriUpdated(string newUri);

    /**
     * @notice Emitted when a new loan in created.
     * @param loanId The id of the loan.
     * @param proposalHash The hash of the proposal.
     * @param terms The terms of the loan.
     * @param lenderSpec The lender spec of the loan.
     * @param extra The extra data of the loan.
     */
    event LOANCreated(
        uint256 indexed loanId, bytes32 indexed proposalHash, Terms terms, LenderSpec lenderSpec, bytes extra
    );

    /**
     * @notice Emitted when a loan is paid back.
     * @param loanId The id of the loan.
     */
    event LOANPaidBack(uint256 indexed loanId);

    /**
     * @notice Emitted when a repaid or defaulted loan is claimed.
     * @param loanId The id of the loan.
     * @param defaulted True if the loan is defaulted.
     */
    event LOANClaimed(uint256 indexed loanId, bool indexed defaulted);

    /**
     * @notice Emitted when a proposal is made.
     * @param proposalHash The hash of the proposal.
     * @param proposer The address of the proposer.
     * @param proposal The proposal.
     */
    event ProposalMade(bytes32 indexed proposalHash, address indexed proposer, Proposal proposal);
}
