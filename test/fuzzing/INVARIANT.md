## When creates a proposal
- The borrower balances are updated:
    Balance(collateral) = previous - collateralAmount
	Balance(sdex) = previous - fee
    Balance(credit) = previous
- The spro balance is updated:
	Balance(collateral) = previous + collateralAmount
    Balance(credit) = previous

## When creates a loan
- The lender balance is updated:
    Balance(credit) = previous - loanTerms.creditAmount
    Balance(collateral) = previous
- The borrower balance is updated:
	Balance(credit) = previous + loanTerms.creditAmount
    Balance(collateral) = previous
- Not possible to accept a loan after the start date:	startTimestamp > block.timestamp
- The proposal amount is lent at 100% or is at least >= the minimum

## Loans
- The amount of collateral in the proposal should be >= of the required amount from loans

## Cancel proposal
- The borrower can withdraw the unused part of his collateral at anytime: Borrower balance(collateral) + _withdrawableCollateral[proposalHash]
- After cancellation, the lender cannot use this proposal to create a loan: ProposalDoesNotExists();

## ClaimLoan
- Lenders can't claim collateral before end time : revert LoanRunning()
- Increase the lender's balance by the sum of the loan's principalAmount + fixedInterestAmount, which was repaid by the borrower, and decrease the spro by the same amount.
- Upon loan expiration, increase the lender's balance by the collateralAmount, and decrease the spro by the same amount.

## Repay
- The borrower balance is updated:
    Balance(credit) = previous - loan.principalAmount - loan.fixedInterestAmount
    Balance(collateral) = previous
- The lender balance is updated if transfer success:
	Balance(credit) = previous + loan.principalAmount + loan.fixedInterestAmount
	Balance(credit) = before the lent + loan.fixedInterestAmount
    Balance(collateral) = previous
- The spro balance is updated if transfer failed:
	Balance(credit) = previous + loan.principalAmount + loan.fixedInterestAmount
    Balance(collateral) = previous
- The borrower can't repay before the start date but anytime after

## Proposal
- _proposalNonce == number of proposal

## Global
- The balance of the Spro is equal to the available credit limit from the open proposal, plus the loan amount and interest if the loan status is 'PAID_BACK'.

## Suite invariants table

| Invariant ID | Invariant Description                                                                            | Tech Checks                                                                                                                                                      |
| ------------ | ------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| PROP-01      | Borrower's collateralToken balance decrease by collateralAmount.                                               | collateralToken.balanceOf(borrower) = previous - collateralAmount                                                                                                               |
| PROP-02      | Borrower must pay the fee.                                                                       | Balance(sdex) = previous - fee                                                                                                                                  |
| PROP-03      | Borrower's borrowToken balance unchanged.                                                               | borrowToken.balanceOf(borrower) = previous                                                                                                                                      |
| PROP-04      | Protocol's collateralToken balance increase by collateralAmount.                                            | collateralToken.balanceOf(spro) = previous + collateralAmount                                                                                                               |
| PROP-05      | Protocol's borrowToken balance unchanged.                                                          | borrowToken.balanceOf(protocol) = previous                                                                                                                                      |
| PROP-06      | The proposal nonce should equal the number of proposals.                                          | _proposalNonce == number of proposal                                                                                                                            |
| LOAN-01      | The lender balance (borrowToken) should be updated when creating a loan.                              | Balance(credit) = previous - loanTerms.creditAmount                                                                                                            |
| LOAN-02      | The lender balance (collateral) not changed.                                                         | collateral.balanceOf(lender) = previous                                                                                                                                  |
| LOAN-03      | The borrower balance (borrowToken) should be updated when creating a loan.                               | Balance(credit) = previous + loanTerms.creditAmount                                                                                                            |
| LOAN-04      | The borrower balance (collateral) not changed.                                                         | Balance(collateral) = previous                                                                                                                                  |
| LOAN-05      | A loan cannot be accepted after its start date.                                                  | startTimestamp > block.timestamp                                                                                                                                |
| LOAN-06      | The loan amount must be lent at 100% or be greater than or equal to the minimum required.         | Proposal amount is lent at 100% or is at least >= the minimum                                                                                                 |
| LOAN-07      | The collateral in a proposal should be greater than or equal to the loan’s required collateral.    | Collateral in proposal >= required collateral                                                                                                                   |
| CAN-01       | The borrower can withdraw the unused part of the collateral anytime after proposal cancellation. | Borrower balance(collateral) + _withdrawableCollateral[proposalHash]                                                                                           |
| CAN-02       | After cancellation, the lender cannot use the proposal to create a loan.                         | ProposalDoesNotExists()                                                                                                                                         |
| CLAIM-01     | The lender cannot claim collateral before the loan's end time.                                  | revert LoanRunning()                                                                                                                                             |
| CLAIM-02     | The lender's balance should increase by the principalAmount + fixedInterestAmount after repayment. | Balance(credit) = previous + loan.principalAmount + loan.fixedInterestAmount                                                                                   |
| CLAIM-03     | The spro balance should decrease by the amount repaid by the borrower after loan expiration.      | Balance(credit) = previous - loan.principalAmount - loan.fixedInterestAmount                                                                                   |
| REPAY-01     | The borrower balance (credit) should decrease after repayment.                                  | Balance(credit) = previous - loan.principalAmount - loan.fixedInterestAmount                                                                                   |
| REPAY-02     | The lender balance (credit) should increase after the borrower repays the loan.                  | Balance(credit) = previous + loan.principalAmount + loan.fixedInterestAmount                                                                                   |
| REPAY-03     | The spro balance should be updated if the repayment transfer fails.                              | Balance(credit) = previous + loan.principalAmount + loan.fixedInterestAmount                                                                                   |
| REPAY-04     | The borrower can't repay before the loan's start date but can repay anytime after.               | Borrower can't repay before startTimestamp                                                                                                                      |
| REPAY-05     | The borrower balance (collateral) should remain the same after repayment.                        | Balance(collateral) = previous                                                                                                                                  |
| REPAY-06     | The lender balance (collateral) should remain the same after repayment.                          | Balance(collateral) = previous                                                                                                                                  |
| GLOB-01      | The spro balance should reflect the available credit limit from open proposals and loans.        | Balance(spro) = available credit limit from open proposals + loan amount + interest if loan status is 'PAID_BACK'                                              |


