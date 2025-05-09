# SproLoan
[Git Source](https://github.com/SmarDex-Ecosystem/spro-contracts/blob/b818fd0bfa6775908ae9ca2555b57c4ae28c9b28/src/spro/SproLoan.sol)

**Inherits:**
[ISproLoan](/src/interfaces/ISproLoan.sol/interface.ISproLoan.md), ERC721, Ownable


## State Variables
### _lastLoanId
Retrieves the last used ID.

*The first ID is 1, this value is incremental.*


```solidity
uint256 public _lastLoanId;
```


## Functions
### constructor


```solidity
constructor(address deployer) ERC721("Spro Loan", "LOAN") Ownable(deployer);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`deployer`|`address`|The deployer address.|


### mint

Mints a new token.

*Only the owner can mint a new token.*


```solidity
function mint(address to) external onlyOwner returns (uint256 loanId_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|The address of the new token owner.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`loanId_`|`uint256`|loanId The Id of the new token.|


### burn

Burns a token.

*Only the owner can burn a token.*


```solidity
function burn(uint256 loanId) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`loanId`|`uint256`|The Id of the token to burn.|


### tokenURI

*See {IERC721Metadata-tokenURI}.*


```solidity
function tokenURI(uint256 tokenId) public view virtual override returns (string memory uri_);
```

