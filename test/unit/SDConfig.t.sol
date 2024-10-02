// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import { SDConfig } from "pwn/config/SDConfig.sol";

// forge inspect src/config/SDConfig.sol:SDConfig storage --pretty

abstract contract SDConfigTest is Test {
    bytes32 internal constant OWNER_SLOT = bytes32(uint256(0)); // `_owner` property position
    bytes32 internal constant PENDING_OWNER_SLOT = bytes32(uint256(1)); // `_pendingOwner` property position
    bytes32 internal constant INITIALIZED_SLOT =
        keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff)); // `_initialized`
        // property position
    bytes32 internal constant PARTIAL_POSITION_PERCENTAGE_SLOT = bytes32(uint256(1));
    uint256 internal constant PARTIAL_POSITION_PERCENTAGE_OFFSET = 176; // == 22 * 8
    bytes32 internal constant UNLISTED_FEE_SLOT = bytes32(uint256(2));
    bytes32 internal constant LISTED_FEE_SLOT = bytes32(uint256(3));
    bytes32 internal constant VARIABLE_FACTOR_SLOT = bytes32(uint256(4));
    bytes32 internal constant TOKEN_FACTORS_SLOT = bytes32(uint256(5));
    bytes32 internal constant LOAN_METADATA_URI_SLOT = bytes32(uint256(6)); // `loanMetadataUri` mapping position
    bytes32 internal constant SFC_REGISTRY_SLOT = bytes32(uint256(7)); // `_sfComputerRegistry` mapping position
    bytes32 internal constant POOL_ADAPTER_REGISTRY_SLOT = bytes32(uint256(8)); // `_poolAdapterRegistry` mapping
        // position

    SDConfig config;
    address owner = makeAddr("owner");
    address sdex = makeAddr("sdex");
    address sink = makeAddr("sink");
    address creditToken = makeAddr("creditToken");

    function setUp() public virtual {
        config = new SDConfig(sdex);
    }

    function _initialize() internal {
        // initialize variables
        vm.store(address(config), OWNER_SLOT, bytes32(uint256(uint160(owner))));
    }

    function _mockSupportsToken(address computer, address token, bool result) internal {
        vm.mockCall(computer, abi.encodeWithSignature("supportsToken(address)", token), abi.encode(result));
    }
}

/* ------------------------------------------------------------ */
/*  CONSTRUCTOR                                              */
/* ------------------------------------------------------------ */

contract SDConfig_Constructor_Test is SDConfigTest {
    function test_shouldInitializeWithCorrectValues() external view {
        bytes32 ownerValue = vm.load(address(config), OWNER_SLOT);
        assertEq(address(uint160(uint256(ownerValue))), address(0));

        bytes32 partialPositionValue = vm.load(address(config), PARTIAL_POSITION_PERCENTAGE_SLOT);
        assertEq(uint16(uint256(partialPositionValue >> PARTIAL_POSITION_PERCENTAGE_OFFSET)), 0);

        bytes32 unlistedFeeValue = vm.load(address(config), UNLISTED_FEE_SLOT);
        assertEq(uint256(unlistedFeeValue), 0);

        bytes32 listedFeeValue = vm.load(address(config), LISTED_FEE_SLOT);
        assertEq(uint256(listedFeeValue), 0);

        bytes32 variableFactorValue = vm.load(address(config), VARIABLE_FACTOR_SLOT);
        assertEq(uint256(variableFactorValue), 0);

        // SDEX token address should be initialised in constructor
        assertEq(sdex, config.SDEX());
    }
}

/* ------------------------------------------------------------ */
/*  INITIALIZE                                               */
/* ------------------------------------------------------------ */

contract SDConfig_Initialize_Test is SDConfigTest {
    uint256 fixFeeUnlisted = 500e18;
    uint256 fixFeeListed = 30e18;
    uint256 variableFactor = 1e13;
    uint16 partialPositionPercentage = 900;
    uint16 PERCENTAGE = 1e4;

    function setUp() public override {
        super.setUp();

        // mock that contract is not initialized
        vm.store(address(config), INITIALIZED_SLOT, bytes32(0));
    }

    function test_shouldSetValues() external {
        config.initialize(owner, fixFeeUnlisted, fixFeeListed, variableFactor, partialPositionPercentage);

        bytes32 ownerValue = vm.load(address(config), OWNER_SLOT);
        assertEq(address(uint160(uint256(ownerValue))), owner);

        assertEq(config.partialPositionPercentage(), partialPositionPercentage);

        bytes32 unlistedFeeValue = vm.load(address(config), UNLISTED_FEE_SLOT);
        assertEq(uint256(unlistedFeeValue), fixFeeUnlisted);

        bytes32 listedFeeValue = vm.load(address(config), LISTED_FEE_SLOT);
        assertEq(uint256(listedFeeValue), fixFeeListed);

        bytes32 variableFactorValue = vm.load(address(config), VARIABLE_FACTOR_SLOT);
        assertEq(uint256(variableFactorValue), variableFactor);
    }

    function test_shouldFail_whenCalledSecondTime() external {
        config.initialize(owner, fixFeeUnlisted, fixFeeListed, variableFactor, partialPositionPercentage);

        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));
        config.initialize(owner, fixFeeUnlisted, fixFeeListed, variableFactor, partialPositionPercentage);
    }

    function test_shouldFail_whenOwnerIsZeroAddress() external {
        vm.expectRevert("Owner is zero address");
        config.initialize(address(0), fixFeeUnlisted, fixFeeListed, variableFactor, partialPositionPercentage);
    }

    function test_shouldFail_whenPartialPositionPercentageIsInvalid() external {
        vm.expectRevert("Partial percentage position value is invalid");
        config.initialize(owner, fixFeeUnlisted, fixFeeListed, variableFactor, 0);

        vm.expectRevert("Partial percentage position value is invalid");
        config.initialize(owner, fixFeeUnlisted, fixFeeListed, variableFactor, PERCENTAGE + 1);
    }
}

/* ------------------------------------------------------------ */
/*  SET FIX FEE UNLISTED                                     */
/* ------------------------------------------------------------ */

contract SDConfig_SetUnlistedFee_Test is SDConfigTest {
    uint256 fee = 90e18;

    function setUp() public override {
        super.setUp();

        _initialize();
    }

    function test_shouldFail_whenCallerIsNotOwner() external {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this)));
        config.setFixFeeUnlisted(fee);
    }

    function test_shouldSetFeeValue() external {
        vm.prank(owner);
        config.setFixFeeUnlisted(fee);

        bytes32 unlistedFeeValue = vm.load(address(config), UNLISTED_FEE_SLOT);
        assertEq(uint256(unlistedFeeValue), fee);
    }

    function test_shouldEmitEvent_FeeUpdated() external {
        vm.expectEmit(true, true, true, true);
        emit SDConfig.FixFeeUnlistedUpdated(0, fee);

        vm.prank(owner);
        config.setFixFeeUnlisted(fee);
    }
}

/* ------------------------------------------------------------ */
/*  SET FIX FEE LISTED                                       */
/* ------------------------------------------------------------ */

contract SDConfig_SetListedFee_Test is SDConfigTest {
    uint256 fee = 90e18;

    function setUp() public override {
        super.setUp();

        _initialize();
    }

    function test_shouldFail_whenCallerIsNotOwner() external {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this)));
        config.setFixFeeListed(fee);
    }

    function test_shouldSetFeeValue() external {
        vm.prank(owner);
        config.setFixFeeListed(fee);

        bytes32 listedFeeValue = vm.load(address(config), LISTED_FEE_SLOT);
        assertEq(uint256(listedFeeValue), fee);
    }

    function test_shouldEmitEvent_FeeUpdated() external {
        vm.expectEmit(true, true, false, false);
        emit SDConfig.FixFeeListedUpdated(0, fee);

        vm.prank(owner);
        config.setFixFeeListed(fee);
    }
}

/* ------------------------------------------------------------ */
/*  SET LISTED TOKEN                                         */
/* ------------------------------------------------------------ */

contract SDConfig_SetListedToken_Test is SDConfigTest {
    uint256 factor = 1e14;

    function setUp() public override {
        super.setUp();

        _initialize();
    }

    function test_shouldFail_whenCallerIsNotOwner() external {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this)));
        config.setListedToken(creditToken, factor);
    }

    function test_shouldSetListedTokenValue() external {
        vm.prank(owner);
        config.setListedToken(creditToken, factor);

        bytes32 tokenFactorValue = vm.load(address(config), keccak256(abi.encode(creditToken, TOKEN_FACTORS_SLOT)));
        assertEq(uint256(tokenFactorValue), factor);
    }

    function test_shouldSetListedTokenValue_ResetToZero() external {
        vm.prank(owner);
        config.setListedToken(creditToken, factor);

        bytes32 tokenFactorValue = vm.load(address(config), keccak256(abi.encode(creditToken, TOKEN_FACTORS_SLOT)));
        assertEq(uint256(tokenFactorValue), factor);

        // Reset
        vm.prank(owner);
        config.setListedToken(creditToken, 0);

        tokenFactorValue = vm.load(address(config), keccak256(abi.encode(creditToken, TOKEN_FACTORS_SLOT)));
        assertEq(uint256(tokenFactorValue), 0);
    }

    function test_shouldEmitEvent_TokenFactorUpdated() external {
        vm.expectEmit(true, true, false, false);
        emit SDConfig.ListedTokenUpdated(creditToken, factor);

        vm.prank(owner);
        config.setListedToken(creditToken, factor);
    }
}

/* ------------------------------------------------------------ */
/*  PARTIAL LENDING THRESHOLDS                               */
/* ------------------------------------------------------------ */

contract SDConfig_PartialLendingThresholds_Test is SDConfigTest {
    uint16 internal constant PERCENTAGE = 1e4;
    uint16 internal constant DEFAULT_THRESHOLD = 500;

    function setUp() public override {
        super.setUp();

        _initialize();

        vm.startPrank(owner);
        config.setPartialPositionPercentage(DEFAULT_THRESHOLD);
        vm.stopPrank();
    }

    function test_shouldFail_whenCallerIsNotOwner() external {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this)));
        config.setPartialPositionPercentage(2000);
    }

    function test_shouldFail_whenZeroPercentage() external {
        vm.startPrank(owner);

        vm.expectRevert(SDConfig.ZeroPercentageValue.selector);
        config.setPartialPositionPercentage(0);
    }

    function testFuzz_shouldFail_ExcessivePercentage(uint16 percentage) external {
        vm.assume(percentage > PERCENTAGE);
        vm.startPrank(owner);

        vm.expectRevert(abi.encodeWithSelector(SDConfig.ExcessivePercentageValue.selector, percentage));
        config.setPartialPositionPercentage(percentage);
    }
}

/* ------------------------------------------------------------ */
/*  SET LOAN METADATA URI                                    */
/* ------------------------------------------------------------ */

contract SDConfig_SetLOANMetadataUri_Test is SDConfigTest {
    string tokenUri = "test.token.uri";
    address loanContract = address(0x63);

    function setUp() public override {
        super.setUp();

        _initialize();
    }

    function test_shouldFail_whenCallerIsNotOwner() external {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this)));
        config.setLOANMetadataUri(loanContract, tokenUri);
    }

    function test_shouldFail_whenZeroLoanContract() external {
        vm.expectRevert(abi.encodeWithSelector(SDConfig.ZeroLoanContract.selector));
        vm.prank(owner);
        config.setLOANMetadataUri(address(0), tokenUri);
    }

    function testFuzz_shouldStoreLoanMetadataUriToLoanContract(address _loanContract) external {
        vm.assume(_loanContract != address(0));
        loanContract = _loanContract;

        vm.prank(owner);
        config.setLOANMetadataUri(loanContract, tokenUri);

        bytes32 tokenUriValue = vm.load(address(config), keccak256(abi.encode(loanContract, LOAN_METADATA_URI_SLOT)));
        bytes memory memoryTokenUri = bytes(tokenUri);
        bytes32 _tokenUri;
        assembly {
            _tokenUri := mload(add(memoryTokenUri, 0x20))
        }
        // Remove string length
        assertEq(keccak256(abi.encodePacked(tokenUriValue >> 8)), keccak256(abi.encodePacked(_tokenUri >> 8)));
    }

    function test_shouldEmitEvent_LOANMetadataUriUpdated() external {
        vm.expectEmit(true, true, true, true);
        emit SDConfig.LOANMetadataUriUpdated(loanContract, tokenUri);

        vm.prank(owner);
        config.setLOANMetadataUri(loanContract, tokenUri);
    }
}

/* ------------------------------------------------------------ */
/*  SET DEFAULT LOAN METADATA URI                            */
/* ------------------------------------------------------------ */

contract SDConfig_SetDefaultLOANMetadataUri_Test is SDConfigTest {
    string tokenUri = "test.token.uri";

    function setUp() public override {
        super.setUp();

        _initialize();
    }

    function test_shouldFail_whenCallerIsNotOwner() external {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this)));
        config.setDefaultLOANMetadataUri(tokenUri);
    }

    function test_shouldStoreDefaultLoanMetadataUri() external {
        vm.prank(owner);
        config.setDefaultLOANMetadataUri(tokenUri);

        bytes32 tokenUriValue = vm.load(address(config), keccak256(abi.encode(address(0), LOAN_METADATA_URI_SLOT)));
        bytes memory memoryTokenUri = bytes(tokenUri);
        bytes32 _tokenUri;
        assembly {
            _tokenUri := mload(add(memoryTokenUri, 0x20))
        }
        // Remove string length
        assertEq(keccak256(abi.encodePacked(tokenUriValue >> 8)), keccak256(abi.encodePacked(_tokenUri >> 8)));
    }

    function test_shouldEmitEvent_DefaultLOANMetadataUriUpdated() external {
        vm.expectEmit(true, true, true, true);
        emit SDConfig.DefaultLOANMetadataUriUpdated(tokenUri);

        vm.prank(owner);
        config.setDefaultLOANMetadataUri(tokenUri);
    }
}

/* ------------------------------------------------------------ */
/*  LOAN METADATA URI                                        */
/* ------------------------------------------------------------ */

contract SDConfig_LoanMetadataUri_Test is SDConfigTest {
    function setUp() public override {
        super.setUp();

        _initialize();
    }

    function testFuzz_shouldReturnDefaultLoanMetadataUri_whenNoStoreValueForLoanContract(address loanContract)
        external
    {
        string memory defaultUri = "default.token.uri";

        vm.prank(owner);
        config.setDefaultLOANMetadataUri(defaultUri);

        string memory uri = config.loanMetadataUri(loanContract);
        assertEq(uri, defaultUri);
    }

    function testFuzz_shouldReturnLoanMetadataUri_whenStoredValueForLoanContract(address loanContract) external {
        vm.assume(loanContract != address(0));
        string memory tokenUri = "test.token.uri";

        vm.prank(owner);
        config.setLOANMetadataUri(loanContract, tokenUri);

        string memory uri = config.loanMetadataUri(loanContract);
        assertEq(uri, tokenUri);
    }
}

/* ------------------------------------------------------------ */
/*  GET STATE FINGERPRINT COMPUTER                           */
/* ------------------------------------------------------------ */

contract SDConfig_GetStateFingerprintComputer_Test is SDConfigTest {
    function setUp() public override {
        super.setUp();

        _initialize();
    }

    function testFuzz_shouldReturnStoredComputer_whenIsRegistered(address asset, address computer) external {
        bytes32 assetSlot = keccak256(abi.encode(asset, SFC_REGISTRY_SLOT));
        vm.store(address(config), assetSlot, bytes32(uint256(uint160(computer))));

        assertEq(address(config.getStateFingerprintComputer(asset)), computer);
    }
}

/* ------------------------------------------------------------ */
/*  REGISTER STATE FINGERPRINT COMPUTER                      */
/* ------------------------------------------------------------ */

contract SDConfig_RegisterStateFingerprintComputer_Test is SDConfigTest {
    function setUp() public override {
        super.setUp();

        _initialize();
    }

    function testFuzz_shouldFail_whenCallerIsNotOwner(address caller) external {
        vm.assume(caller != owner);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, caller));
        vm.prank(caller);
        config.registerStateFingerprintComputer(address(0), address(0));
    }

    function testFuzz_shouldUnregisterComputer_whenComputerIsZeroAddress(address asset) external {
        address computer = makeAddr("computer");
        bytes32 assetSlot = keccak256(abi.encode(asset, SFC_REGISTRY_SLOT));
        vm.store(address(config), assetSlot, bytes32(uint256(uint160(computer))));

        vm.prank(owner);
        config.registerStateFingerprintComputer(asset, address(0));

        assertEq(address(config.getStateFingerprintComputer(asset)), address(0));
    }

    function testFuzz_shouldFail_whenComputerDoesNotSupportToken(address asset, address computer) external {
        assumeAddressIsNot(computer, AddressType.ForgeAddress, AddressType.Precompile, AddressType.ZeroAddress);
        _mockSupportsToken(computer, asset, false);

        vm.expectRevert(abi.encodeWithSelector(SDConfig.InvalidComputerContract.selector, computer, asset));
        vm.prank(owner);
        config.registerStateFingerprintComputer(asset, computer);
    }

    function testFuzz_shouldRegisterComputer(address asset, address computer) external {
        assumeAddressIsNot(computer, AddressType.ForgeAddress, AddressType.Precompile, AddressType.ZeroAddress);
        _mockSupportsToken(computer, asset, true);

        vm.prank(owner);
        config.registerStateFingerprintComputer(asset, computer);

        assertEq(address(config.getStateFingerprintComputer(asset)), computer);
    }
}

/* ------------------------------------------------------------ */
/*  GET POOL ADAPTER                                         */
/* ------------------------------------------------------------ */

contract SDConfig_GetPoolAdapter_Test is SDConfigTest {
    function setUp() public override {
        super.setUp();

        _initialize();
    }

    function testFuzz_shouldReturnStoredAdapter_whenIsRegistered(address pool, address adapter) external {
        bytes32 poolSlot = keccak256(abi.encode(pool, POOL_ADAPTER_REGISTRY_SLOT));
        vm.store(address(config), poolSlot, bytes32(uint256(uint160(adapter))));

        assertEq(address(config.getPoolAdapter(pool)), adapter);
    }
}

/* ------------------------------------------------------------ */
/*  REGISTER POOL ADAPTER                                    */
/* ------------------------------------------------------------ */

contract SDConfig_RegisterPoolAdapter_Test is SDConfigTest {
    function setUp() public override {
        super.setUp();

        _initialize();
    }

    function testFuzz_shouldFail_whenCallerIsNotOwner(address caller) external {
        vm.assume(caller != owner);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, caller));
        vm.prank(caller);
        config.registerPoolAdapter(address(0), address(0));
    }

    function testFuzz_shouldStoreAdapter(address pool, address adapter) external {
        vm.prank(owner);
        config.registerPoolAdapter(pool, adapter);

        assertEq(address(config.getPoolAdapter(pool)), adapter);
    }
}
