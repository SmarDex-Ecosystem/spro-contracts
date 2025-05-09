# ISproErrors
[Git Source](https://github.com/SmarDex-Ecosystem/spro-contracts/blob/b818fd0bfa6775908ae9ca2555b57c4ae28c9b28/src/interfaces/ISproErrors.sol)

Defines all custom errors emitted by the Spro protocol.


## Errors
### ZeroAddress
Thrown when the address is zero.


```solidity
error ZeroAddress();
```

### Expired
Thrown when a proposal is expired.


```solidity
error Expired(uint256 current, uint256 expiration);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`current`|`uint256`|The current timestamp.|
|`expiration`|`uint256`|The expiration timestamp.|

### IncorrectPercentageValue
Thrown when trying to set an incorrect partial position value.


```solidity
error IncorrectPercentageValue(uint16 partialPositionBps);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`partialPositionBps`|`uint16`|The incorrect value.|

### LoanCannotBeRepaid
Thrown when a loan cannot be repaid.


```solidity
error LoanCannotBeRepaid();
```

### LoanRunning
Thrown when a loan is still running.


```solidity
error LoanRunning();
```

### CallerNotLoanTokenHolder
Thrown when caller is not the loan token holder.


```solidity
error CallerNotLoanTokenHolder();
```

### InvalidDuration
Thrown when a loan duration is below the minimum allowed.


```solidity
error InvalidDuration(uint256 current, uint256 limit);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`current`|`uint256`|The current duration.|
|`limit`|`uint256`|The minimum duration.|

### UnauthorizedCaller
Thrown when the caller is not the protocol.


```solidity
error UnauthorizedCaller();
```

### CallerNotProposer
Thrown when caller is not the proposer.


```solidity
error CallerNotProposer();
```

### CallerNotBorrower
Thrown when caller is not the borrower.


```solidity
error CallerNotBorrower();
```

### DifferentCreditAddress
Thrown when the loan credit address is different than the expected credit address.


```solidity
error DifferentCreditAddress(address loanCreditAddress, address expectedCreditAddress);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`loanCreditAddress`|`address`|The address of the loan credit.|
|`expectedCreditAddress`|`address`|The expected address of the credit.|

### AcceptorIsProposer
Thrown when the proposal acceptor and proposer are identical.


```solidity
error AcceptorIsProposer(address addr);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`addr`|`address`|The identical address.|

### CreditAmountTooSmall
Thrown when the credit amount is below the minimum amount for the proposal.


```solidity
error CreditAmountTooSmall(uint256 amount, uint256 minimum);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The wanted credit amount.|
|`minimum`|`uint256`|The minimum credit amount allowed.|

### CreditAmountRemainingBelowMinimum
Thrown when the credit amount remaining is insufficient, smaller than the minimum required for a future
loan.


```solidity
error CreditAmountRemainingBelowMinimum(uint256 amount, uint256 minimum);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The wanted credit amount.|
|`minimum`|`uint256`|The minimum credit amount that should remain.|

### AvailableCreditLimitExceeded
Thrown when a proposal would exceed the available credit limit.


```solidity
error AvailableCreditLimitExceeded(uint256 creditAvailable);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`creditAvailable`|`uint256`|The available credit amount.|

### AvailableCreditLimitZero
Thrown when a proposal has an available credit of zero.


```solidity
error AvailableCreditLimitZero();
```

### ProposalDoesNotExists
Thrown when the proposal does not exist.


```solidity
error ProposalDoesNotExists();
```

### InvalidStartTime
Thrown when the proposal start time is invalid.

*Either the start time is in the past or the start time is after the expiration time.*


```solidity
error InvalidStartTime();
```

### ExcessiveFee
Thrown when owner tries to set a fee that is higher than the maximum allowed.


```solidity
error ExcessiveFee(uint256 fee);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`fee`|`uint256`|The fee value.|

### TransferMismatch
Thrown when a token transfer does not match the expected amount.


```solidity
error TransferMismatch();
```

