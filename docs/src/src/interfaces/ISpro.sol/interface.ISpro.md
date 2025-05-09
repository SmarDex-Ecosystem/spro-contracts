# ISpro
[Git Source](https://github.com/SmarDex-Ecosystem/spro-contracts/blob/b818fd0bfa6775908ae9ca2555b57c4ae28c9b28/src/interfaces/ISpro.sol)

**Inherits:**
[ISproTypes](/src/interfaces/ISproTypes.sol/interface.ISproTypes.md), [ISproErrors](/src/interfaces/ISproErrors.sol/interface.ISproErrors.md), [ISproEvents](/src/interfaces/ISproEvents.sol/interface.ISproEvents.md)

Interface for the Spro protocol.


## Functions
### setFee

Sets the protocol fee value.


```solidity
function setFee(uint256 newFee) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newFee`|`uint256`|The new fee value in SDEX tokens.|


### setPartialPositionPercentage

Sets the minimum usage ratio for partial lending.


```solidity
function setPartialPositionPercentage(uint16 newPartialPositionBps) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newPartialPositionBps`|`uint16`|The new percentage value, in basis points.|


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


### getProposalCreditStatus

Retrieves the used and remaining credit for a proposal.


```solidity
function getProposalCreditStatus(ISproTypes.Proposal memory proposal)
    external
    view
    returns (uint256 used_, uint256 remaining_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`proposal`|`ISproTypes.Proposal`|The proposal structure.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`used_`|`uint256`|The used credit of the proposal.|
|`remaining_`|`uint256`|The remaining credit of the proposal.|


### getProposalHash

Retrieves the proposal hash.


```solidity
function getProposalHash(ISproTypes.Proposal memory proposal) external returns (bytes32 proposalHash_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`proposal`|`ISproTypes.Proposal`|The proposal structure.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`proposalHash_`|`bytes32`|The hash of the proposal.|


### totalLoanRepaymentAmount

Calculates the total repayment amount for multiple loans, with the fixed interest amounts.

*The credit token must be the same for all loans. The function filters by repayable loans.*


```solidity
function totalLoanRepaymentAmount(uint256[] memory loanIds) external view returns (uint256 amount_);
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
) external;
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
function cancelProposal(Proposal memory proposal) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`proposal`|`Proposal`|The proposal structure.|


### createLoan

Creates a new loan.

*This contract is not suitable for rebasing or fee-on-transfer tokens.*


```solidity
function createLoan(Proposal memory proposal, uint256 creditAmount, bytes calldata permit2Data)
    external
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
function repayLoan(uint256 loanId, bytes calldata permit2Data, address collateralRecipient) external;
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
    external;
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
function claimMultipleLoans(uint256[] memory loanIds) external;
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
function claimLoan(uint256 loanId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`loanId`|`uint256`|The loan ID being claimed.|


