# ISproEvents
[Git Source](https://github.com/SmarDex-Ecosystem/spro-contracts/blob/b818fd0bfa6775908ae9ca2555b57c4ae28c9b28/src/interfaces/ISproEvents.sol)

**Inherits:**
[ISproTypes](/src/interfaces/ISproTypes.sol/interface.ISproTypes.md)

Defines all custom events emitted by the Spro protocol.


## Events
### FeeUpdated
The fee was updated.


```solidity
event FeeUpdated(uint256 newFee);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newFee`|`uint256`|The new fee.|

### PartialPositionBpsUpdated
The partial position was updated.


```solidity
event PartialPositionBpsUpdated(uint256 newPartialPositionBps);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newPartialPositionBps`|`uint256`|The new partial position.|

### LoanCreated
A new loan was created.


```solidity
event LoanCreated(uint256 loanId, bytes32 indexed proposalHash, Terms loanTerms);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`loanId`|`uint256`|The loan ID.|
|`proposalHash`|`bytes32`|The hash of the proposal.|
|`loanTerms`|`Terms`|The terms of the loan.|

### LoanPaidBack
A loan was paid back.


```solidity
event LoanPaidBack(uint256 loanId);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`loanId`|`uint256`|The loan ID.|

### LoanClaimed
A repaid or defaulted loan was claimed.


```solidity
event LoanClaimed(uint256 loanId, bool defaulted);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`loanId`|`uint256`|The loan ID.|
|`defaulted`|`bool`|True if the loan was defaulted.|

### ProposalCreated
A proposal was created.


```solidity
event ProposalCreated(bytes32 proposalHash, Proposal proposal, uint256 sdexBurned);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`proposalHash`|`bytes32`|The hash of the proposal.|
|`proposal`|`Proposal`|The proposal structure.|
|`sdexBurned`|`uint256`|The SDEX fee amount burned.|

### ProposalCanceled
A proposal was canceled.


```solidity
event ProposalCanceled(bytes32 proposalHash);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`proposalHash`|`bytes32`|The hash of the proposal.|

