# SproStorage
[Git Source](https://github.com/SmarDex-Ecosystem/spro-contracts/blob/b818fd0bfa6775908ae9ca2555b57c4ae28c9b28/src/spro/SproStorage.sol)

**Inherits:**
[ISproStorage](/src/interfaces/ISproStorage.sol/interface.ISproStorage.md)


## State Variables
### DEAD_ADDRESS
*The address that will receive all fees.*


```solidity
address internal constant DEAD_ADDRESS = address(0xdead);
```


### BPS_DIVISOR
Retrieves the denominator used for the reward multipliers.


```solidity
uint256 public constant BPS_DIVISOR = 10_000;
```


### MAX_SDEX_FEE
Retrieves the maximum SDEX fee that can be set by the contract owner.


```solidity
uint256 public constant MAX_SDEX_FEE = 10_000_000e18;
```


### MIN_LOAN_DURATION
Retrieves the minimum loan duration allowed, expressed in seconds.


```solidity
uint32 public constant MIN_LOAN_DURATION = 10 minutes;
```


### SDEX
Retrieves the address of the SDEX token contract.


```solidity
address public immutable SDEX;
```


### PERMIT2
Retrieves the address of the Permit2 contract used for transfer management.


```solidity
IAllowanceTransfer public immutable PERMIT2;
```


### _proposalNonce
Retrieves the current proposal nonce.


```solidity
uint256 public _proposalNonce;
```


### _partialPositionBps
Retrieves the minimum usage ratio for partial lending, expressed in basis points.


```solidity
uint16 public _partialPositionBps;
```


### _fee
Retrieves the protocol fixed SDEX fee value.


```solidity
uint256 public _fee;
```


### _loanToken
Retrieves the address of the {SproLoan} contract.


```solidity
SproLoan public immutable _loanToken;
```


### _withdrawableCollateral
Retrieves the withdrawable collateral amount for a given proposal hash.


```solidity
mapping(bytes32 => uint256) public _withdrawableCollateral;
```


### _proposalsMade
Checks if a proposal has already been made for a given proposal hash.


```solidity
mapping(bytes32 => bool) public _proposalsMade;
```


### _creditUsed
Retrieves the credit already used for a given proposal hash.


```solidity
mapping(bytes32 => uint256) public _creditUsed;
```


### _loans
Mapping of all loan data by loan id.


```solidity
mapping(uint256 => ISproTypes.Loan) internal _loans;
```


