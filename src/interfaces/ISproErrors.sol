// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title Errors for the Spro Protocol
 * @notice Defines all custom errors emitted by the Spro protocol.
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
     * @notice Thrown when trying to set an incorrect partial position value.
     * @param partialPositionBps The incorrect value.
     */
    error IncorrectPercentageValue(uint16 partialPositionBps);

    /// @notice Thrown when a loan cannot be repaid.
    error LoanCannotBeRepaid();

    /// @notice Thrown when a loan is still running.
    error LoanRunning();

    /// @notice Thrown when caller is not the loan token holder.
    error CallerNotLoanTokenHolder();

    /**
     * @notice Thrown when a loan duration is below the minimum allowed.
     * @param current The current duration.
     * @param limit The minimum duration.
     */
    error InvalidDuration(uint256 current, uint256 limit);

    /// @notice Thrown when the caller is not the protocol.
    error UnauthorizedCaller();

    /// @notice Thrown when caller is not the proposer.
    error CallerNotProposer();

    /// @notice Thrown when caller is not the borrower.
    error CallerNotBorrower();

    /**
     * @notice Thrown when the loan credit address is different than the expected credit address.
     * @param loanCreditAddress The address of the loan credit.
     * @param expectedCreditAddress The expected address of the credit.
     */
    error DifferentCreditAddress(address loanCreditAddress, address expectedCreditAddress);

    /**
     * @notice Thrown when the proposal acceptor and proposer are identical.
     * @param addr The identical address.
     */
    error AcceptorIsProposer(address addr);

    /**
     * @notice Thrown when the credit amount is below the minimum amount for the proposal.
     * @param amount The wanted credit amount.
     * @param minimum The minimum credit amount allowed.
     */
    error CreditAmountTooSmall(uint256 amount, uint256 minimum);

    /**
     * @notice Thrown when the credit amount remaining is insufficient, smaller than the minimum required for a future
     * loan.
     * @param amount The wanted credit amount.
     * @param minimum The minimum credit amount that should remain.
     */
    error CreditAmountRemainingBelowMinimum(uint256 amount, uint256 minimum);

    /**
     * @notice Thrown when a proposal would exceed the available credit limit.
     * @param creditAvailable The available credit amount.
     */
    error AvailableCreditLimitExceeded(uint256 creditAvailable);

    /// @notice Thrown when a proposal has an available credit of zero.
    error AvailableCreditLimitZero();

    /// @notice Thrown when the proposal does not exist.
    error ProposalDoesNotExists();

    /**
     * @notice Thrown when the proposal start time is invalid.
     * @dev Either the start time is in the past or the start time is after the expiration time.
     */
    error InvalidStartTime();

    /**
     * @notice Thrown when owner tries to set a fee that is higher than the maximum allowed.
     * @param fee The fee value.
     */
    error ExcessiveFee(uint256 fee);

    /// @notice Thrown when a token transfer does not match the expected amount.
    error TransferMismatch();
}
