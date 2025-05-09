# ISproLoan
[Git Source](https://github.com/SmarDex-Ecosystem/spro-contracts/blob/b818fd0bfa6775908ae9ca2555b57c4ae28c9b28/src/interfaces/ISproLoan.sol)

**Inherits:**
IERC721


## Functions
### _lastLoanId

Retrieves the last used ID.

*The first ID is 1, this value is incremental.*


```solidity
function _lastLoanId() external view returns (uint256 _lastLoanId);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`_lastLoanId`|`uint256`|The last used ID.|


### mint

Mints a new token.

*Only the owner can mint a new token.*


```solidity
function mint(address to) external returns (uint256 loanId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|The address of the new token owner.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`loanId`|`uint256`|The Id of the new token.|


### burn

Burns a token.

*Only the owner can burn a token.*


```solidity
function burn(uint256 loanId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`loanId`|`uint256`|The Id of the token to burn.|


