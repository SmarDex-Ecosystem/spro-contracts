# ISproTypes
[Git Source](https://github.com/SmarDex-Ecosystem/spro-contracts/blob/b818fd0bfa6775908ae9ca2555b57c4ae28c9b28/src/interfaces/ISproTypes.sol)


## Structs
### Terms
Structure defining a loan terms.


```solidity
struct Terms {
    address lender;
    address borrower;
    uint40 startTimestamp;
    uint40 loanExpiration;
    address collateralAddress;
    uint256 collateralAmount;
    address creditAddress;
    uint256 creditAmount;
    uint256 fixedInterestAmount;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`lender`|`address`|The address of a lender.|
|`borrower`|`address`|The address of a borrower.|
|`startTimestamp`|`uint40`|The start timestamp of the proposal.|
|`loanExpiration`|`uint40`|The expiration timestamp of the proposal.|
|`collateralAddress`|`address`|The address of a collateral asset.|
|`collateralAmount`|`uint256`|The amount of a collateral asset.|
|`creditAddress`|`address`|The address of a credit asset.|
|`creditAmount`|`uint256`|The amount of a credit asset.|
|`fixedInterestAmount`|`uint256`|Fixed interest amount in credit asset tokens.|

### Loan
Struct defining a loan.


```solidity
struct Loan {
    LoanStatus status;
    address lender;
    address borrower;
    uint40 startTimestamp;
    uint40 loanExpiration;
    address collateralAddress;
    uint256 collateralAmount;
    address creditAddress;
    uint256 principalAmount;
    uint256 fixedInterestAmount;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`status`|`LoanStatus`|The loan status.|
|`lender`|`address`|The address of a lender that funded the loan.|
|`borrower`|`address`|The address of a borrower.|
|`startTimestamp`|`uint40`|The start timestamp of the proposal.|
|`loanExpiration`|`uint40`|The expiration timestamp of the proposal.|
|`collateralAddress`|`address`|The address of a collateral asset.|
|`collateralAmount`|`uint256`|The amount of a collateral asset.|
|`creditAddress`|`address`|The address of an asset used as a loan credit.|
|`principalAmount`|`uint256`|Principal amount in credit asset tokens.|
|`fixedInterestAmount`|`uint256`|Fixed interest amount in credit asset tokens.|

### Proposal
Structure defining a proposal.


```solidity
struct Proposal {
    address collateralAddress;
    uint256 collateralAmount;
    address creditAddress;
    uint256 availableCreditLimit;
    uint256 fixedInterestAmount;
    uint40 startTimestamp;
    uint40 loanExpiration;
    address proposer;
    uint256 nonce;
    uint256 minAmount;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`collateralAddress`|`address`|The collateral asset address.|
|`collateralAmount`|`uint256`|The collateral asset amount.|
|`creditAddress`|`address`|The credit asset address.|
|`availableCreditLimit`|`uint256`|Available credit limit for the proposal. It is the maximum amount of tokens which can be borrowed using the proposal.|
|`fixedInterestAmount`|`uint256`|Fixed interest amount in credit asset tokens.|
|`startTimestamp`|`uint40`|The start timestamp of the proposal.|
|`loanExpiration`|`uint40`|The expiration timestamp of the proposal.|
|`proposer`|`address`|The address of a proposer.|
|`nonce`|`uint256`|Additional value to enable identical proposals in time. Without it, it would be impossible to make an identical proposal again.|
|`minAmount`|`uint256`|The minimum amount of credit tokens that can be borrowed from the proposal, or the remaining amount the lender must leave in the proposal.|

## Enums
### LoanStatus
Represents the status of a loan.


```solidity
enum LoanStatus {
    NONE,
    RUNNING,
    PAID_BACK,
    EXPIRED
}
```

