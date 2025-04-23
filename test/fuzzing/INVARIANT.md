## When creates a proposal
- The borrower balances are updated:
    Balance(collateral) = previous - collateralAmount
	Balance(sdex) = previous - fee
    Balance(credit) = previous
- The spro balance is updated:
	Balance(collateral) = previous + collateralAmount
    Balance(credit) = previous
- _proposalNonce == number of proposal
- The dead address balance is updated:
	Balance(sdex) = previous + fee

## When creates a loan
- The lender balance is updated:
    Balance(credit) = previous - loanTerms.creditAmount
    Balance(collateral) = previous
- The borrower balance is updated:
	Balance(credit) = previous + loanTerms.creditAmount
    Balance(collateral) = previous
- Not possible to accept a loan after the start date:	startTimestamp > block.timestamp
- The proposal amount is at least >= the minimum
- The rest in the proposal must be greater than the proposal minAmount

## Loans
- The amount of collateral in the proposal should be >= of the required amount from loans

## Cancel proposal
- The borrower can withdraw the unused part of his collateral at anytime: Borrower balance(collateral) + _withdrawableCollateral[proposalHash]
- After cancellation, the lender cannot use this proposal to create a loan: ProposalDoesNotExists();

## ClaimLoan
- Lenders can't claim collateral before end time : revert LoanRunning()
- The lender cannot claim borrowToken if borrower already sent tokens: revert CallerNotLoanTokenHolder()
- The lender balance is updated if loan repaid:
	Balance(credit) = previous + loan.principalAmount + loan.fixedInterestAmount
	Balance(collateral) = previous
- The lender balance is updated if loan expired:
    Balance(credit) = previous
    Balance(collateral) = previous + collateralAmount
- The spro balance is updated if loan repaid:
	Balance(credit) = previous - loan.principalAmount - loan.fixedInterestAmount
    Balance(collateral) = previous
- The spro balance is updated if loan expired:
    Balance(credit) = previous
    Balance(collateral) = previous - collateralAmount

## Repay
- The borrower can't repay before the start date but anytime after
- The borrower balance is updated:
    Balance(credit) = previous - loan.principalAmount - loan.fixedInterestAmount
    Balance(collateral) = previous + collateralAmount
- The lender balance is updated if transfer success:
	Balance(credit) = previous + loan.principalAmount + loan.fixedInterestAmount
	Balance(credit) = before the lent + loan.fixedInterestAmount
    Balance(collateral) = previous
- The lender balance is updated if transfer failed:
	Balance(credit) = previous
- The lender balance is updated:
    Balance(collateral) = previous
- The spro balance is updated if transfer success:
	Balance(credit) = previous
    Balance(collateral) = previous - collateralAmount
- The spro balance is updated if transfer failed:
	Balance(credit) = previous + loan.principalAmount + loan.fixedInterestAmount
    Balance(collateral) = previous - collateralAmount

## Global
- The balance of the Spro is equal to the available credit limit from the open proposal, plus the loan amount and interest if the loan status is 'PAID_BACK'.

## Suite invariants table

| Invariant ID | Condition | Invariant Description                                                   | Tech Checks                                                           |
| ------------ | ----------| ----------------------------------------------------------------------- | --------------------------------------------------------------------- |
| GLOB-01      |           | The protocol balance should reflect the available credit limit from open proposals and loans.        | token.balanceOf(protocol) = available credit limit from open proposals + (loan amount + interest) if loan status is 'PAID_BACK' and nft not burned      |
| PROP-01      |     | Borrower's collateral token balance decreased by collateral amount.       | collateralToken.balanceOf(borrower) = previous - collateralAmount     |
| PROP-02      |     | Borrower must pay the SDEX fee.                                           | sdex.balanceOf(borrower) = previous - fee                             |
| PROP-03      |     | Borrower's borrow token balance unchanged.                                | borrowToken.balanceOf(borrower) = previous                            |
| PROP-04      |     | Protocol's collateral token balance increased by collateral amount.       | collateralToken.balanceOf(protocol) = previous + collateralAmount     |
| PROP-05      |     | Protocol's borrow token balance unchanged.                                | borrowToken.balanceOf(protocol) = previous                            |
| PROP-06      |     | The proposal nonce should be equal to the total number of proposals.      | _proposalNonce == number of proposal                                  |
| PROP-07      |     | Dead address's sdex balance increased by fee.                             | sdex.balanceOf(deadAddress) == previous + fee                         |
| LOAN-01      |     | Lender's borrow token balance decreased by credit amount.                 | borrowToken.balanceOf(lender) = previous - loanTerms.creditAmount     |
| LOAN-02      |     | Lender's collateral token balance unchanged.                              | collateralToken.balanceOf(lender) = previous                          |
| LOAN-03      |     | Borrower's borrow token balance increased by credit amount.               | borrowToken.balanceOf(borrower) = previous + loanTerms.creditAmount   |
| LOAN-04      |     | Borrower's collateral token balance unchanged.                            | collateralToken.balanceOf(borrower) = previous                        |
| LOAN-05      |     | A loan cannot be accepted after its start date.                           | startTimestamp > block.timestamp                                      |
| LOAN-06      |     | The loan amount must be greater than or equal to the proposal minimum amount.                       | loan amount is at least >= proposal.minAmount                                     |
| LOAN-07      |     | The rest in the proposal must be greater than or equal to the proposal minimum amount or equal to 0.            | proposal.availableCreditLimit - _creditUsed[proposalHash_] >= proposal.minAmount   or proposal.availableCreditLimit - _creditUsed[proposalHash_] == 0 |
| LOAN-08      |     | The collateral in a proposal should be greater than or equal to the loan’s required collateral.     | Collateral in proposal >= required collateral                                     |
| CANCEL-01    |     | The borrower can withdraw the unused part of the collateral anytime after proposal creation.        | collateralToken.balanceOf(borrower) + _withdrawableCollateral[proposalHash]       |
| CANCEL-02    |     | The protocol sent the withdrawn collateral by the borrower.               | collateralToken.balanceOf(protocol) - _withdrawableCollateral[proposalHash]       |
| CLAIM-01     | Lend repaid                    | Protocol's collateral token balance unchanged.                 | collateralToken.balanceOf(protocol) = previous            |
| CLAIM-02     | Lend repaid                    | Protocol's borrow token balance decreased by lended amount and interests.                            | borrowToken.balanceOf(protocol) = previous - loan.principalAmount - loan.fixedInterestAmount|
| CLAIM-03     | Loan expired                   | Lender's collateral token balance increased by the collateral amount.                       | collateralToken.balanceOf(lender) = previous + collateralAmount    |
| REPAY-01     |                                | The borrower can't repay before the loan's start date but can repay anytime after.        | Borrower can't repay before startTimestamp|
| REPAY-02     | The transfer fails             | Protocol's borrow token balance increased.                     | borrowToken.balanceOf(protocol) = previous + loan.principalAmount + loan.fixedInterestAmount  |
| REPAY-03     |                                | Borrower's collateral token balance increased by the collateral amount.                     | collateralToken.balanceOf(borrower) = previous + collateralAmount  |
| REPAY-04     |                                | Borrower's borrow token balance decreased by lended amount and interests.         | borrowToken.balanceOf(borrower) = previous - loan.principalAmount - loan.fixedInterestAmount|
| REPAY-05     | Transfer success               | Lender's borrow token balance increased by interests since before start of loan.         | borrowToken.balanceOf(lender) = previousLoanCreation + loan.fixedInterestAmount  |
| ENDLOAN-01   | Lend repaid and upon calling claimLoan         | Lender's collateral token balance unchanged                       | collateralToken.balanceOf(lender) = previous              |
|              | Call repayLoan                 |                                                                   |                                                           |
| ENDLOAN-02   | Loan expired and upon calling claimLoan        | Lender's borrow token balance unchanged.                          | borrowToken.balanceOf(lender) = previous                  |
|              | The transfer failed and upon calling repayLoan |                                                                   |                                                           |
| ENDLOAN-03   | Loan expired and upon calling claimLoan        | Protocol's borrow token unchanged if loan expired.     | borrowToken.balanceOf(protocol) = previous                |
|              | Transfer success and upon calling repayLoan    |                                                                   |                                                           |
| ENDLOAN-04   | Lend repaid and upon calling claimLoan         | Lender's borrow token balance increased by the lended amount and interests.    | borrowToken.balanceOf(lender) = previous + loan.principalAmount + loan.fixedInterestAmount  |
|              | Transfer success and upon calling repayLoan    |                                                                   |                                                           |
| ENDLOAN-05   | Loan expired and upon calling claimLoan        | Protocol's collateral token balance decreased by the collateralAmount.                    | collateralToken.balanceOf(protocol) = previous - collateralAmount  |
|              | Call repayLoan                 |                                                                                           |                                                           |