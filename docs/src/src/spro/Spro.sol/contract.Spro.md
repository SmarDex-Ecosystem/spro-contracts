# Spro
[Git Source](https://github.com/SmarDex-Ecosystem/spro-contracts/blob/b818fd0bfa6775908ae9ca2555b57c4ae28c9b28/src/spro/Spro.sol)

**Inherits:**
[SproStorage](/src/spro/SproStorage.sol/contract.SproStorage.md), [ISpro](/src/interfaces/ISpro.sol/interface.ISpro.md), Ownable2Step, ReentrancyGuard


## Functions
### constructor


```solidity
constructor(address sdex, address permit2, uint256 fee, uint16 partialPositionBps, address owner) Ownable(owner);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`sdex`|`address`|The SDEX token address.|
|`permit2`|`address`|The permit2 contract address.|
|`fee`|`uint256`|The fixed SDEX fee value.|
|`partialPositionBps`|`uint16`|The minimum usage ratio for partial lending (in basis points).|
|`owner`|`address`|The initial owner of the protocol.|


### setFee

Sets the protocol fee value.


```solidity
function setFee(uint256 newFee) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newFee`|`uint256`|The new fee value in SDEX tokens.|


### setPartialPositionPercentage

Sets the minimum usage ratio for partial lending.


```solidity
function setPartialPositionPercentage(uint16 newPartialPositionBps) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newPartialPositionBps`|`uint16`|The new percentage value, in basis points.|


### getProposalCreditStatus

Retrieves the used and remaining credit for a proposal.


```solidity
function getProposalCreditStatus(Proposal calldata proposal)
    external
    view
    returns (uint256 used_, uint256 remaining_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`proposal`|`Proposal`|The proposal structure.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`used_`|`uint256`|The used credit of the proposal.|
|`remaining_`|`uint256`|The remaining credit of the proposal.|


### getLoan

Retrieves the loan data for a given loan id.


```solidity
function getLoan(uint256 loanId) external view returns (Loan memory loan_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`loanId`|`uint256`|The loan ID.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`loan_`|`Loan`|The loan data.|


### totalLoanRepaymentAmount

Calculates the total repayment amount for multiple loans, with the fixed interest amounts.

*The credit token must be the same for all loans. The function filters by repayable loans.*


```solidity
function totalLoanRepaymentAmount(uint256[] calldata loanIds) external view returns (uint256 amount_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`loanIds`|`uint256[]`|Array of loan ids.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amount_`|`uint256`|The total repayment amount for all loans.|


### createProposal

Creates a new borrowing proposal.

*The collateral and SDEX tokens must be approved for the protocol contract. This contract is not suitable for
rebasing or fee-on-transfer tokens.*


```solidity
function createProposal(
    address collateralAddress,
    uint256 collateralAmount,
    address creditAddress,
    uint256 availableCreditLimit,
    uint256 fixedInterestAmount,
    uint40 startTimestamp,
    uint40 loanExpiration,
    bytes calldata permit2Data
) external nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralAddress`|`address`|The address of the collateral asset.|
|`collateralAmount`|`uint256`|The amount of the collateral asset.|
|`creditAddress`|`address`|The address of the credit asset.|
|`availableCreditLimit`|`uint256`|The available credit limit for the proposal.|
|`fixedInterestAmount`|`uint256`|The fixed interest amount in credit asset tokens.|
|`startTimestamp`|`uint40`|The start timestamp of the proposal.|
|`loanExpiration`|`uint40`|The expiration timestamp of the proposal.|
|`permit2Data`|`bytes`|The permit2 data, if the user opts to use permit2.|


### cancelProposal

Cancels a borrowing proposal.

*Transfers unused collateral to the proposer.*


```solidity
function cancelProposal(Proposal memory proposal) external nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`proposal`|`Proposal`|The proposal structure.|


### createLoan

Creates a new loan.

*This contract is not suitable for rebasing or fee-on-transfer tokens.*


```solidity
function createLoan(Proposal calldata proposal, uint256 creditAmount, bytes calldata permit2Data)
    external
    nonReentrant
    returns (uint256 loanId_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`proposal`|`Proposal`|The proposal structure.|
|`creditAmount`|`uint256`|The amount of credit tokens.|
|`permit2Data`|`bytes`|The permit2 data, if the user opts to use permit2.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`loanId_`|`uint256`|The ID of the created loan token.|


### repayLoan

Repays an active loan.

*Any address can repay an active loan if the `collateralRecipient` address is set to `address(0)`. The
collateral will be transferred to the borrower associated with the loan. If the caller is the borrower and
provides a `collateralRecipient` address, the collateral will be transferred to the specified address instead of
the borrower’s address. The protocol will attempt to send the credit to the lender. If the transfer fails, the
credit will be sent to the protocol, and the lender will be able to claim it later.*


```solidity
function repayLoan(uint256 loanId, bytes calldata permit2Data, address collateralRecipient) external nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`loanId`|`uint256`|The ID of the loan being repaid.|
|`permit2Data`|`bytes`|The permit2 data, if the user opts to use permit2.|
|`collateralRecipient`|`address`|The address that will receive the collateral. If address(0) is provided, the borrower's address will be used.|


### repayMultipleLoans

Repays multiple active loans.

*Any address can repay an active loan if the `collateralRecipient` address is set to `address(0)`. The
collateral will be transferred to the borrower associated with the loan. If the caller is the borrower and
provides a `collateralRecipient` address, the collateral will be transferred to the specified address instead of
the borrower’s address. The protocol will attempt to send the credit to the lender. If the transfer fails, the
credit will be sent to the protocol, and the lender will be able to claim it later.*


```solidity
function repayMultipleLoans(uint256[] calldata loanIds, bytes calldata permit2Data, address collateralRecipient)
    external
    nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`loanIds`|`uint256[]`|An array of loan IDs being repaid.|
|`permit2Data`|`bytes`|The permit2 data, if the user opts to use permit2.|
|`collateralRecipient`|`address`|The address that will receive the collateral. If address(0) is provided, the borrower's address will be used.|


### tryClaimRepaidLoan

Attempts to claim a repaid loan.

*This function can only be called by the protocol. If the transfer fails, the loan token will remain in
a repaid state, allowing the loan token holder to claim the repayment credit manually.*


```solidity
function tryClaimRepaidLoan(uint256 loanId, uint256 creditAmount, address creditAddress, address loanOwner) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`loanId`|`uint256`|The loan ID being claimed.|
|`creditAmount`|`uint256`|The amount of credit tokens to be claimed.|
|`creditAddress`|`address`|The address of the credit token send to the lender.|
|`loanOwner`|`address`|The address of the loan token holder.|


### claimMultipleLoans

Claims multiple repaid or defaulted loans.

*Only a loan token holder can claim their repaid or defaulted loan. Claiming transfers the repaid credit
or collateral to the loan token holder and burns the loan token.*


```solidity
function claimMultipleLoans(uint256[] calldata loanIds) external nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`loanIds`|`uint256[]`|An array of loan IDs being claimed.|


### claimLoan

Claims a repaid or defaulted loan.

*Only a loan token holder can claim their repaid or defaulted loan. Claiming transfers the repaid credit
or collateral to the loan token holder and burns the loan token.*


```solidity
function claimLoan(uint256 loanId) external nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`loanId`|`uint256`|The loan ID being claimed.|


### getProposalHash

Retrieves the proposal hash.


```solidity
function getProposalHash(Proposal memory proposal) public pure returns (bytes32 proposalHash_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`proposal`|`Proposal`|The proposal structure.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`proposalHash_`|`bytes32`|The hash of the proposal.|


### _claimLoan

Claims a repaid or defaulted loan.

*Only a loan token holder can claim their repaid or defaulted loan. Claiming transfers the repaid credit
or collateral to the loan token holder and burns the loan token.*


```solidity
function _claimLoan(uint256 loanId) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`loanId`|`uint256`|The loan ID being claimed.|


### _isLoanRepayable

Check if the loan can be repaid.


```solidity
function _isLoanRepayable(LoanStatus status, uint40 loanExpiration) internal view returns (bool canBeRepaid_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`status`|`LoanStatus`|The loan status.|
|`loanExpiration`|`uint40`|The loan expiration timestamp.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`canBeRepaid_`|`bool`|True if the loan can be repaid.|


### _acceptProposal

Accept a proposal and create new loan terms.


```solidity
function _acceptProposal(address acceptor, uint256 creditAmount, Proposal memory proposal)
    internal
    returns (bytes32 proposalHash_, Terms memory loanTerms_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`acceptor`|`address`|The address of the proposal acceptor.|
|`creditAmount`|`uint256`|The amount of credit to lend.|
|`proposal`|`Proposal`|The proposal structure.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`proposalHash_`|`bytes32`|The hash of the proposal.|
|`loanTerms_`|`Terms`|The terms of the loan.|


### _createLoan

Create a new loan token and store loan data.


```solidity
function _createLoan(Terms memory loanTerms) internal returns (uint256 loanId_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`loanTerms`|`Terms`|The terms of the loan.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`loanId_`|`uint256`|The Id of the new loan.|


### _settleLoanClaim

Settle the loan claim.


```solidity
function _settleLoanClaim(uint256 loanId, Loan memory loan, address loanOwner, bool defaulted) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`loanId`|`uint256`|The Id of the loan to settle.|
|`loan`|`Loan`|The loan structure.|
|`loanOwner`|`address`|The owner of the loan token.|
|`defaulted`|`bool`|True if the loan was defaulted.|


### _deleteLoan

Delete a loan from the storage and burn the token.


```solidity
function _deleteLoan(uint256 loanId) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`loanId`|`uint256`|The Id of the loan to delete.|


### _permit2Workflows

Handle approval and transfers using Permit2.


```solidity
function _permit2Workflows(bytes memory permit2Data, address from, address to, uint160 amount, address token)
    internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`permit2Data`|`bytes`|The permit2 data.|
|`from`|`address`|The address that will transfer the asset.|
|`to`|`address`|The address that will receive the asset.|
|`amount`|`uint160`|The amount to transfer.|
|`token`|`address`|The asset address.|


### _permit2WorkflowsBatch

Handle batch approvals and transfers via permit2

*If SDEX fees are set, they will be burned via transfer to the dead address*


```solidity
function _permit2WorkflowsBatch(bytes memory permit2Data, address from, address to, uint160 amount, address token)
    internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`permit2Data`|`bytes`|The permit2 data.|
|`from`|`address`|The address that will transfer the asset.|
|`to`|`address`|The address that will receive the asset.|
|`amount`|`uint160`|The amount to transfer.|
|`token`|`address`|The asset address.|


## Structs
### LoanWithId
*Data structure for the [repayMultipleLoans](/src/spro/Spro.sol/contract.Spro.md#repaymultipleloans) function.*


```solidity
struct LoanWithId {
    uint256 loanId;
    Loan loan;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`loanId`|`uint256`|The Id of a loan.|
|`loan`|`Loan`|The loan structure.|

