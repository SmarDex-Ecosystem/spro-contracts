// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title ISproErrors
 * @notice Errors for the Spro Protocol
 */
interface ISproErrors {
    /**
     * @notice Thrown when a proposal is expired.
     */
    error Expired(uint256 current, uint256 expiration);

    /**
     * @notice Thrown when the Vault receives an asset that is not transferred by the Vault itself.
     */
    error UnsupportedTransferFunction();

    /**
     * @notice Thrown when the Vault receives an invalid amount of an asset.
     */
    error InvalidAmountTransfer();

    /**
     * @notice Thrown when registering a computer which does not support the asset it is registered for.
     */
    error InvalidComputerContract(address computer, address asset);

    /**
     * @notice Thrown when trying to set a LOAN token metadata uri for zero address loan contract.
     */
    error ZeroLoanContract();

    /**
     * @notice Thrown when trying to set a percentage value higher than `PERCENTAGE`.
     */
    error ExcessivePercentageValue(uint16 percentage);

    /**
     * @notice Thrown when trying to set a percentage value equal to zero.
     */
    error ZeroPercentageValue();

    /**
     * @notice Thrown when a caller is not a stated proposer.
     */
    error CallerIsNotStatedProposer(address addr);

    /**
     * @notice Thrown when managed loan is running.
     */
    error LoanNotRunning();

    /**
     * @notice Thrown when manged loan is still running.
     */
    error LoanRunning();

    /**
     * @notice Thrown when managed loan is defaulted.
     */
    error LoanDefaulted(uint40);

    /**
     * @notice Thrown when loan doesn't exist.
     */
    error NonExistingLoan();

    /**
     * @notice Thrown when caller is not a LOAN token holder.
     */
    error CallerNotLOANTokenHolder();

    /**
     * @notice Thrown when loan duration is below the minimum.
     */
    error InvalidDuration(uint256 current, uint256 limit);

    /**
     * @notice Thrown when accruing interest APR is above the maximum.
     */
    error InterestAPROutOfBounds(uint256 current, uint256 limit);

    /**
     * @notice Thrown when caller is not a vault.
     */
    error CallerNotVault();

    /**
     * @notice Thrown when caller is not the borrower/proposer
     */
    error CallerNotProposer();

    /**
     * @notice Thrown when pool based source of funds doesn't have a registered adapter.
     */
    error InvalidSourceOfFunds(address sourceOfFunds);

    /**
     * @notice Thrown when the loan credit address is different than the expected credit address.
     */
    error DifferentCreditAddress(address loanCreditAddress, address expectedCreditAddress);

    /**
     * @notice Thrown when a state fingerprint computer is not registered.
     */
    error MissingStateFingerprintComputer();

    /**
     * @notice Thrown when a proposed collateral state fingerprint doesn't match the current state.
     */
    error InvalidCollateralStateFingerprint(bytes32 current, bytes32 proposed);

    /**
     * @notice Thrown when proposal acceptor and proposer are the same.
     */
    error AcceptorIsProposer(address addr);

    /**
     * @notice Thrown when credit amount is below the minimum amount for the proposal.
     */
    error CreditAmountTooSmall(uint256 amount, uint256 minimum);

    /**
     * @notice Thrown when credit amount is above the maximum amount for the proposal, but not 100% of available
     */
    error CreditAmountLeavesTooLittle(uint256 amount, uint256 maximum);

    /**
     * @notice Thrown when a proposal would exceed the available credit limit.
     */
    error AvailableCreditLimitExceeded(uint256 used, uint256 limit);

    /**
     * @notice Thrown when a proposal has an available credit limit of zero.
     */
    error AvailableCreditLimitZero();

    /**
     * @notice Thrown when caller is not allowed to accept a proposal.
     */
    error CallerNotAllowedAcceptor(address current, address allowed);

    /**
     * @notice Thrown when the proposal already exists.
     */
    error ProposalAlreadyExists();

    /**
     * @notice Thrown when the proposal has not been made.
     */
    error ProposalNotMade();

    /**
     * @notice Thrown when a partial loan is attempted for NFT collateral.
     */
    error OnlyCompleteLendingForNFTs(uint256 creditAmount, uint256 availableCreditLimit);

    /**
     * @notice Thrown when the start timestamp is greater than the default timestamp.
     */
    error InvalidDurationStartTime();

    /* -------------------------------------------------------------------------- */
    /*                                   PERMIT                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Thrown when the permit owner is not matching.
     */
    error InvalidPermitOwner(address current, address expected);

    /**
     * @notice Thrown when the permit asset is not matching.
     */
    error InvalidPermitAsset(address current, address expected);
}
