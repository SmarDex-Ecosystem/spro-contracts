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
	Balance(credit) = previous + principalAmount + fixedInterestAmount
	Balance(collateral) = previous
- The spro balance is updated if loan repaid:
	Balance(credit) = previous - principalAmount - fixedInterestAmount
    Balance(collateral) = previous
- The lender balance is updated if loan expired:
    Balance(credit) = previous
    Balance(collateral) = previous + collateralAmount
- The spro balance is updated if loan expired:
    Balance(credit) = previous
    Balance(collateral) = previous - collateralAmount

## Repay
- The borrower balance is updated:
    Balance(credit) = previous - loan.principalAmount - loan.fixedInterestAmount
    Balance(collateral) = previous + collateralAmount
- The lender balance is updated if transfer success:
	Balance(credit) = previous + loan.principalAmount + loan.fixedInterestAmount
	Balance(credit) = before the lent + loan.fixedInterestAmount
    Balance(collateral) = previous
- The lender balance is updated if transfer failed:
	Balance(credit) = previous
    Balance(collateral) = previous
- The spro balance is updated if transfer success:
	Balance(credit) = previous
    Balance(collateral) = previous - collateralAmount
- The spro balance is updated if transfer failed:
	Balance(credit) = previous + loan.principalAmount + loan.fixedInterestAmount
    Balance(collateral) = previous - collateralAmount
- The borrower can't repay before the start date but anytime after

## Global
- The balance of the Spro is equal to the available credit limit from the open proposal, plus the loan amount and interest if the loan status is 'PAID_BACK'.

## Suite invariants table

| Invariant ID | Invariant Description                                                                            | Tech Checks                                                                                                                                                      |
| ------------ | ------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| GLOB-01      | The protocol balance should reflect the available credit limit from open proposals and loans.        | borrowToken.balanceOf(protocol) = available credit limit from open proposals + (loan amount + interest) if loan status is 'PAID_BACK' and nft not burned                                              |
| PROP-01      | Borrower's collateralToken balance decreased by collateralAmount.                                               | collateralToken.balanceOf(borrower) = previous - collateralAmount                                                                                                               |
| PROP-02      | Borrower must pay the SDEX fee.                                                                       | sdex.balanceOf(borrower) = previous - fee                                                                                                                                  |
| PROP-03      | Borrower's borrowToken balance unchanged.                                                               | borrowToken.balanceOf(borrower) = previous                                                                                                                                      |
| PROP-04      | Protocol's collateralToken balance increased by collateralAmount.                                            | collateralToken.balanceOf(spro) = previous + collateralAmount                                                                                                               |
| PROP-05      | Protocol's borrowToken balance unchanged.                                                          | borrowToken.balanceOf(protocol) = previous                                                                                                                                      |
| PROP-06      | The proposal nonce should equal the number of proposals.                                          | _proposalNonce == number of proposal                                                                                                                                      |
| PROP-07      | Dead address's sdex balance increased by fee.                                                     | sdex.balanceOf(deadAddress) == previous + fee                                                                                                                                    |
| LOAN-01      | Lender's borrowToken balance decreased by creditAmount.                                      | borrowToken.balanceOf(lender) = previous - loanTerms.creditAmount                                                                                                            |
| LOAN-02      | Lender's collateralToken balance unchanged.                                                         | collateralToken.balanceOf(lender) = previous                                                                                                                                  |
| LOAN-03      | Borrower's borrowToken balance increased by creditAmount.                                       | borrowToken.balanceOf(borrower) = previous + loanTerms.creditAmount                                                                                                            |
| LOAN-04      | Borrower's collateralToken balance unchanged.                                                         | collateralToken.balanceOf(borrower) = previous                                                                                                                                  |
| LOAN-05      | A loan cannot be accepted after its start date.                                                  | startTimestamp > block.timestamp                                                                                                                                |
| LOAN-06      | The loan amount must be greater than or equal to the proposal minAmount.         | Proposal amount is at least >= the minimum                                                                                                 |
| LOAN-07      | The rest in the proposal must be greater than the proposal minAmount                      | proposal.availableCreditLimit - _creditUsed[proposalHash_] > proposal.minAmount                                                                                                 |
| LOAN-08      | The collateral in a proposal should be greater than or equal to the loan’s required collateral.    | Collateral in proposal >= required collateral                                                                                                                   |
| CANCEL-01       | The borrower can withdraw the unused part of the collateral anytime after proposal creation. | collateralToken.balanceOf(borrower) + _withdrawableCollateral[proposalHash]                                                                                           |
| CANCEL-02       | After cancellation, the lender cannot use the proposal to create a loan.                         | ProposalDoesNotExists()                                                                                                                                         |
| CLAIM-01     | The lender cannot claim collateralToken before the loan's end time.                                  | call reverts with LoanRunning()                                                                                                                                             |
| CLAIM-02     | The lender cannot claim borrowToken if borrower already sent tokens.                                  | call reverts with CallerNotLoanTokenHolder()                                                                                                                                             |
| CLAIM-03     | Lender's borrowToken balance increased by the principalAmount and fixedInterestAmount if lend repaid. | borrowToken.balanceOf(lender) = previous + loan.principalAmount + loan.fixedInterestAmount                                                                                   |
| CLAIM-04     | Lender's collateralToken balance unchanged if lend repaid. | collateralToken.balanceOf(lender) = previous                                                                                  |
| CLAIM-05     | protocol's borrowToken balance decreased by the principalAmount and fixedInterestAmount if lend repaid.   | borrowToken.balanceOf(protocol) = previous - loan.principalAmount - loan.fixedInterestAmount                                                                                   |
| CLAIM-06     | protocol's collateralToken balance unchanged if lend repaid. | collateralToken.balanceOf(protocol) = previous                                                                                  |
| CLAIM-07     | Lender's borrowToken balance unchanged if lend repaid. | borrowToken.balanceOf(lender) = previous                                                                                  |
| CLAIM-08     | Lender's collateralToken balance increased by the collateralAmount if loan expired. | collateralToken.balanceOf(lender) = previous + collateralAmount                                                                                   |
| CLAIM-09     | Protocol's borrowToken unchanged if loan expired.   | borrowToken.balanceOf(protocol) = previous                                                                                 |
| CLAIM-10     | Protocol's collateralToken balance decreased by the collateralAmount if loan expired.   | collateralToken.balanceOf(protocol) = previous - collateralAmount                                                                                   |
| REPAY-01     | Borrower's borrowToken balance decreased by loan.principalAmount and loan.fixedInterestAmount.         | borrowToken.balanceOf(borrower) = previous - loan.principalAmount - loan.fixedInterestAmount                                                                                   |
| REPAY-02     | Borrower's collateralToken balance increased by collateralAmount.         | collateralToken.balanceOf(borrower) = previous - collateralAmount                                                                                   |
| REPAY-03     | Lender's borrowToken balance increased by loan.principalAmount + loan.fixedInterestAmount if the transfer success.        | borrowToken.balanceOf(lender) = previous + loan.principalAmount + loan.fixedInterestAmount                                                                                   |
| REPAY-04     | Lender's borrowToken balance increased by loan.fixedInterestAmount since before start of loan if the transfer success.        | borrowToken.balanceOf(lender) = previousLoan + loan.fixedInterestAmount                                                                                   |
| REPAY-05     | Lender's borrowToken balance unchanged if the transfer failed.         | borrowToken.balanceOf(lender) = previous                                                                                   |
| REPAY-05     | Lender's collateralToken balance unchanged.         | collateralToken.balanceOf(lender) = previous                                                                                   |
| REPAY-08     | Protocol's borrowToken balance unchanged if the transfer success.                              | borrowToken.balanceOf(protocol) = previous                                    |
| REPAY-07     | Protocol's collateralToken balance decreased by collateralAmount.         | collateralToken.balanceOf(protocol) = previous - collateralAmount                                                                                   |
| REPAY-09     | Protocol's borrowToken balance increased if the transfer fails.                              | borrowToken.balanceOf(protocol) = previous + loan.principalAmount + loan.fixedInterestAmount                                                                                   |
| REPAY-10     | The borrower can't repay before the loan's start date but can repay anytime after.               | Borrower can't repay before startTimestamp                                            |


