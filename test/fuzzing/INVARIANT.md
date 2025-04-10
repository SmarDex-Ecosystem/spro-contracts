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

| Invariant ID | Invariant Description                                                   | Tech Checks                                                           |
| ------------ | ----------------------------------------------------------------------- | --------------------------------------------------------------------- |
| GLOB-01      | The protocol balance should reflect the available credit limit from open proposals and loans.        | borrowToken.balanceOf(protocol) = available credit limit from open proposals + (loan amount + interest) if loan status is 'PAID_BACK' and nft not burned                         |
| PROP-01      | Borrower's collateralToken balance decreased by collateralAmount.       | collateralToken.balanceOf(borrower) = previous - collateralAmount     |
| PROP-02      | Borrower must pay the SDEX fee.                                         | sdex.balanceOf(borrower) = previous - fee                             |
| PROP-03      | Borrower's borrowToken balance unchanged.                               | borrowToken.balanceOf(borrower) = previous                            |
| PROP-04      | Protocol's collateralToken balance increased by collateralAmount.       | collateralToken.balanceOf(spro) = previous + collateralAmount         |
| PROP-05      | Protocol's borrowToken balance unchanged.                               | borrowToken.balanceOf(protocol) = previous                            |
| PROP-06      | The proposal nonce should be equal to the total number of proposals.    | _proposalNonce == number of proposal                                  |
| PROP-07      | Dead address's sdex balance increased by fee.                           | sdex.balanceOf(deadAddress) == previous + fee                         |
| LOAN-01      | Lender's borrowToken balance decreased by creditAmount.                 | borrowToken.balanceOf(lender) = previous - loanTerms.creditAmount     |
| LOAN-02      | Lender's collateralToken balance unchanged.                             | collateralToken.balanceOf(lender) = previous                          |
| LOAN-03      | Borrower's borrowToken balance increased by creditAmount.               | borrowToken.balanceOf(borrower) = previous + loanTerms.creditAmount   |
| LOAN-04      | Borrower's collateralToken balance unchanged.                           | collateralToken.balanceOf(borrower) = previous                        |
| LOAN-05      | A loan cannot be accepted after its start date.                         | startTimestamp > block.timestamp                                      |
| LOAN-06      | The loan amount must be greater than or equal to the proposal minAmount.                            | Proposal amount is at least >= the minimum                                        |
| LOAN-07      | The rest in the proposal must be greater than the proposal minAmount                                | proposal.availableCreditLimit - _creditUsed[proposalHash_] > proposal.minAmount   |
| LOAN-08      | The collateral in a proposal should be greater than or equal to the loan’s required collateral.     | Collateral in proposal >= required collateral                                     |
| CANCEL-01    | The borrower can withdraw the unused part of the collateral anytime after proposal creation.        | collateralToken.balanceOf(borrower) + _withdrawableCollateral[proposalHash]       |
| CANCEL-02    | After cancellation, the lender cannot use the proposal to create a loan.                            | ProposalDoesNotExists()                                                           |
| CLAIM-01     | The lender cannot claim collateralToken before the loan's end time.     | call reverts with LoanRunning()                                       |
| CLAIM-02     | The lender cannot claim borrowToken if borrower already sent tokens.    | call reverts with CallerNotLoanTokenHolder()                          |
| REPAY-01     | The borrower can't repay before the loan's start date but can repay anytime after.                  | Borrower can't repay before startTimestamp|

If claimLoan or repayLoan is called, the loan status will change. Invariants are checks depending on the loan status before and after the call.

| Invariant ID  | Description                                            | Tech Checks                                               |
| ------------  | -----------------------------------------------------  | --------------------------------------------------------- |
| ENDLOAN-01    | Lender's collateralToken balance unchanged if lend repaid(claimLoan).                 | collateralToken.balanceOf(lender) = previous              |
|               | Lender's collateralToken balance unchanged if transfer success(repayLoan).            |                                                           |
|               | Lender's collateralToken balance unchanged if transfer failed (repayLoan).            |                                                           |
| ENDLOAN-02    | Protocol's collateralToken balance unchanged if lend repaid(claimLoan).               | collateralToken.balanceOf(protocol) = previous            |
| ENDLOAN-03    | Lender's borrowToken balance unchanged if loan expired(claimLoan).                    | borrowToken.balanceOf(lender) = previous                  |
|               | Lender's borrowToken balance unchanged if the transfer failed(repayLoan).             |                                                           |
| ENDLOAN-04    | Protocol's borrowToken unchanged if loan expired(claimLoan).                          | borrowToken.balanceOf(protocol) = previous                |
|               | Protocol's borrowToken balance unchanged if transfer success(repayLoan).              |                                                           |
| ENDLOAN-05    | Lender's borrowToken balance increased by the principalAmount and fixedInterestAmount if lend repaid(claimLoan).         | borrowToken.balanceOf(lender) = previous + loan.principalAmount + loan.fixedInterestAmount  |
|               | Lender's borrowToken balance increased by loan.principalAmount + loan.fixedInterestAmount if transfer success(repayLoan).|                         |
| ENDLOAN-06    | Protocol's borrowToken balance increased if the transfer fails(repayLoan).             | borrowToken.balanceOf(protocol) = previous + loan.principalAmount + loan.fixedInterestAmount  |
| ENDLOAN-07    | Protocol's borrowToken balance decreased by loan.principalAmount and loan.fixedInterestAmount if lend repaid(claimLoan).             | borrowToken.balanceOf(protocol) = previous - loan.principalAmount - loan.fixedInterestAmount  |
| ENDLOAN-08    | Lender's collateralToken balance increased by the collateralAmount if loan expired(claimLoan).                    | collateralToken.balanceOf(lender) = previous + collateralAmount    |
| ENDLOAN-09    | Borrower's collateralToken balance increased by the collateralAmount(repayLoan).                                  | collateralToken.balanceOf(borrower) = previous + collateralAmount  |
| ENDLOAN-10    | Protocol's collateralToken balance decreased by the collateralAmount if loan expired(claimLoan).                  | collateralToken.balanceOf(protocol) = previous - collateralAmount  |
|               | Protocol's collateralToken balance decreased by collateralAmount if transfer success(repayLoan).                  |                                                           |
|               | Protocol's collateralToken balance decreased by collateralAmount if transfer failed(repayLoan).                   |                                                           |
| ENDLOAN-11    | Borrower's borrowToken balance decreased by loan.principalAmount and loan.fixedInterestAmount(repayLoan).         | borrowToken.balanceOf(borrower) = previous - loan.principalAmount - loan.fixedInterestAmount|
| ENDLOAN-12    | Lender's borrowToken balance increased by loan.fixedInterestAmount since before start of loan if transfer success(repayLoan).                | borrowToken.balanceOf(lender) = previousLoanCreation + loan.fixedInterestAmount  |

Condition for ENDLOAN-01 to ENDLOAN-12:

| Invariant ID  | Loan Status before the call | Loan Status after the call  |
| ------------  | --------------------------- | --------------------------- |
| ENDLOAN-01    | PAID_BACK                   | burned                      |
|               | isLoanRepayable             | burned                      |
|               | isLoanRepayable             | PAID_BACK                   |
| ENDLOAN-02    | PAID_BACK                   | burned                      |
| ENDLOAN-03    | !isLoanRepayable            | burned                      |
|               | isLoanRepayable             | PAID_BACK                   |
| ENDLOAN-04    | !isLoanRepayable            | burned                      |
|               | isLoanRepayable             | burned                      |
| ENDLOAN-05    | PAID_BACK                   | burned                      |
|               | isLoanRepayable             | burned                      |
| ENDLOAN-06    | isLoanRepayable             | PAID_BACK                   |
| ENDLOAN-07    | PAID_BACK                   | burned                      |
| ENDLOAN-08    | !isLoanRepayable            | burned                      |
| ENDLOAN-09    | isLoanRepayable             | burned                      |
| ENDLOAN-10    | !isLoanRepayable            | burned                      |
|               | isLoanRepayable             | burned                      |
|               | isLoanRepayable             | PAID_BACK                   |
| ENDLOAN-11    | isLoanRepayable             | burned                      |
| ENDLOAN-12    | isLoanRepayable             | burned                      |