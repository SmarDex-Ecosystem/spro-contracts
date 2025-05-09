# ISproStorage
[Git Source](https://github.com/SmarDex-Ecosystem/spro-contracts/blob/b818fd0bfa6775908ae9ca2555b57c4ae28c9b28/src/interfaces/ISproStorage.sol)


## Functions
### BPS_DIVISOR

Retrieves the denominator used for the reward multipliers.


```solidity
function BPS_DIVISOR() external view returns (uint256 BPS_DIVISOR);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`BPS_DIVISOR`|`uint256`|The BPS divisor.|


### MAX_SDEX_FEE

Retrieves the maximum SDEX fee that can be set by the contract owner.


```solidity
function MAX_SDEX_FEE() external view returns (uint256 MAX_SDEX_FEE);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`MAX_SDEX_FEE`|`uint256`|The maximum allowable fee in SDEX.|


### MIN_LOAN_DURATION

Retrieves the minimum loan duration allowed, expressed in seconds.


```solidity
function MIN_LOAN_DURATION() external view returns (uint32 MIN_LOAN_DURATION);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`MIN_LOAN_DURATION`|`uint32`|The minimum duration of a loan in seconds.|


### SDEX

Retrieves the address of the SDEX token contract.


```solidity
function SDEX() external view returns (address SDEX);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`SDEX`|`address`|The address of the SDEX token contract.|


### PERMIT2

Retrieves the address of the Permit2 contract used for transfer management.


```solidity
function PERMIT2() external view returns (IAllowanceTransfer PERMIT2);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`PERMIT2`|`IAllowanceTransfer`|The address of the Permit2 contract.|


### _proposalNonce

Retrieves the current proposal nonce.


```solidity
function _proposalNonce() external view returns (uint256 _proposalNonce);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`_proposalNonce`|`uint256`|The current proposal nonce.|


### _partialPositionBps

Retrieves the minimum usage ratio for partial lending, expressed in basis points.


```solidity
function _partialPositionBps() external view returns (uint16 _partialPositionBps);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`_partialPositionBps`|`uint16`|The minimum usage ratio for partial lending.|


### _fee

Retrieves the protocol fixed SDEX fee value.


```solidity
function _fee() external view returns (uint256 _fee);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`_fee`|`uint256`|The amount of SDEX required to pay the fee.|


### _loanToken

Retrieves the address of the {SproLoan} contract.


```solidity
function _loanToken() external view returns (SproLoan _loanToken);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`_loanToken`|`SproLoan`|The contract is an ERC721 token.|


### _withdrawableCollateral

Retrieves the withdrawable collateral amount for a given proposal hash.


```solidity
function _withdrawableCollateral(bytes32 proposalHash) external view returns (uint256 _withdrawableCollateral);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`proposalHash`|`bytes32`|The hash of the proposal.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`_withdrawableCollateral`|`uint256`|The remaining collateral amount for the proposal.|


### _proposalsMade

Checks if a proposal has already been made for a given proposal hash.


```solidity
function _proposalsMade(bytes32 proposalHash) external view returns (bool _proposalsMade);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`proposalHash`|`bytes32`|The hash of the proposal.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`_proposalsMade`|`bool`|True if the proposal has already been made, false otherwise.|


### _creditUsed

Retrieves the credit already used for a given proposal hash.


```solidity
function _creditUsed(bytes32 proposalHash) external view returns (uint256 _creditUsed);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`proposalHash`|`bytes32`|The hash of the proposal.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`_creditUsed`|`uint256`|The amount of credit already used for the given proposal hash.|


