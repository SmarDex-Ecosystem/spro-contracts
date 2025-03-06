// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title ISproErrors
 * @notice Errors for the Spro Protocol
 */
interface ISproErrors {
    /// @notice Thrown when the address is zero.
    error ZeroAddress();

    /**
     * @notice Thrown when a proposal is expired.
     * @param current The current timestamp.
     * @param expiration The expiration timestamp.
     */
    error Expired(uint256 current, uint256 expiration);

    /**
     * @notice Thrown when the Vault receives an asset that is not transferred by the Vault itself.
     */
    error UnsupportedTransferFunction();

    /**
     * @notice Thrown when registering a computer which does not support the asset it is registered for.
     * @param computer The address of the computer.
     * @param asset The address of the asset.
     */
    error InvalidComputerContract(address computer, address asset);

    /**
     * @notice Thrown when trying to set an incorrect percentage value.
     * @param percentage The percentage value.
     */
    error IncorrectPercentageValue(uint16 percentage);

    /**
     * @notice Thrown when trying to set a percentage value equal to zero.
     */
    error ZeroPercentageValue();

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
     * @param loanExpiration The timestamp of the end of the loan.
     */
    error LoanDefaulted(uint40 loanExpiration);

    /**
     * @notice Thrown when loan doesn't exist.
     */
    error NonExistingLoan();

    /**
     * @notice Thrown when caller is not a Loan token holder.
     */
    error CallerNotLoanTokenHolder();

    /**
     * @notice Thrown when loan duration is below the minimum.
     * @param current The current duration.
     * @param limit The minimum duration.
     */
    error InvalidDuration(uint256 current, uint256 limit);

    /**
     * @notice Thrown when accruing interest APR is above the maximum.
     * @param current The current APR.
     * @param limit The maximum APR.
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
     * @param sourceOfFunds The address of the source of funds.
     */
    error InvalidSourceOfFunds(address sourceOfFunds);

    /**
     * @notice Thrown when the loan credit address is different than the expected credit address.
     * @param loanCreditAddress The address of the loan credit.
     * @param expectedCreditAddress The expected address of the credit.
     */
    error DifferentCreditAddress(address loanCreditAddress, address expectedCreditAddress);

    /**
     * @notice Thrown when proposal acceptor and proposer are the same.
     * @param addr The address of the acceptor/proposer.
     */
    error AcceptorIsProposer(address addr);

    /**
     * @notice Thrown when credit amount is below the minimum amount for the proposal.
     * @param amount The credit amount.
     * @param minimum The minimum credit amount.
     */
    error CreditAmountTooSmall(uint256 amount, uint256 minimum);

    /**
     * @notice Thrown when credit amount is above the maximum amount for the proposal, but not 100% of available.
     * @param amount The credit amount.
     * @param maximum The maximum credit amount.
     */
    error CreditAmountLeavesTooLittle(uint256 amount, uint256 maximum);

    /**
     * @notice Thrown when a proposal would exceed the available credit limit.
     * @param used The amount of credit used.
     * @param limit The available credit limit.
     */
    error AvailableCreditLimitExceeded(uint256 used, uint256 limit);

    /**
     * @notice Thrown when a proposal has an available credit limit of zero.
     */
    error AvailableCreditLimitZero();

    /**
     * @notice Thrown when caller is not allowed to accept a proposal.
     * @param current The address of the caller.
     * @param allowed The address of the allowed acceptor.
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
     * @param creditAmount The amount of credit.
     * @param availableCreditLimit The available credit limit.
     */
    error OnlyCompleteLendingForNFTs(uint256 creditAmount, uint256 availableCreditLimit);

    /**
     * @notice Thrown when the start timestamp is greater than the default timestamp.
     */
    error InvalidDurationStartTime();

    /**
     * @notice Thrown when owner set a fee that is too high.
     * @param fee The fee amount.
     */
    error ExcessiveFee(uint256 fee);
}
