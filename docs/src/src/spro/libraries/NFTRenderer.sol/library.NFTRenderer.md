# NFTRenderer
[Git Source](https://github.com/SmarDex-Ecosystem/spro-contracts/blob/b818fd0bfa6775908ae9ca2555b57c4ae28c9b28/src/spro/libraries/NFTRenderer.sol)


## Functions
### render

Renders the JSON metadata for a given loan NFT.


```solidity
function render(ISproTypes.Loan memory loan) internal view returns (string memory uri_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`loan`|`ISproTypes.Loan`|The loan data.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`uri_`|`string`|The JSON metadata URI for the loan NFT.|


### renderBackgroundAndTop

Renders the SVG background and top section of the NFT.


```solidity
function renderBackgroundAndTop(string memory creditTicker, string memory collateralTicker)
    internal
    pure
    returns (string memory background_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`creditTicker`|`string`|The ticker of the credit asset.|
|`collateralTicker`|`string`|The ticker of the collateral asset.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`background_`|`string`|The SVG string for the background and top section.|


### renderInfobox

Renders the infobox sections of the NFT.


```solidity
function renderInfobox(
    string memory creditTicker,
    string memory collateralTicker,
    uint256 interest,
    uint256 credit,
    uint256 collateral
) internal pure returns (string memory infobox_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`creditTicker`|`string`|The ticker of the credit asset.|
|`collateralTicker`|`string`|The ticker of the collateral asset.|
|`interest`|`uint256`|The interest amount.|
|`credit`|`uint256`|The credit amount.|
|`collateral`|`uint256`|The collateral amount.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`infobox_`|`string`|The SVG string for the infobox sections.|


### renderAttributes

Renders the attributes for the NFT.


```solidity
function renderAttributes(
    string memory creditTicker,
    string memory collateralTicker,
    uint256 interest,
    uint256 creditAmount,
    uint256 collateralAmount
) internal pure returns (string memory attributes_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`creditTicker`|`string`|The ticker of the credit asset.|
|`collateralTicker`|`string`|The ticker of the collateral asset.|
|`interest`|`uint256`|The interest amount.|
|`creditAmount`|`uint256`|The credit amount.|
|`collateralAmount`|`uint256`|The collateral amount.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`attributes_`|`string`|The JSON string for the attributes.|


