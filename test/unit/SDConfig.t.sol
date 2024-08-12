// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import {Test} from "forge-std/src/Test.sol";

import {SDConfig} from "pwn/config/SDConfig.sol";

// forge inspect src/config/SDConfig.sol:SDConfig storage --pretty

abstract contract SDConfigTest is Test {
    bytes32 internal constant OWNER_SLOT = bytes32(uint256(0)); // `_owner` property position
    bytes32 internal constant PENDING_OWNER_SLOT = bytes32(uint256(1)); // `_pendingOwner` property position
    bytes32 internal constant INITIALIZED_SLOT = bytes32(uint256(1)); // `_initialized` property position
    bytes32 internal constant FEE_SLOT = bytes32(uint256(1)); // `fee` property position
    bytes32 internal constant SDEX_SLOT = bytes32(uint256(2));
    bytes32 internal constant SINK_SLOT = bytes32(uint256(3));
    bytes32 internal constant UNLISTED_FEE_SLOT = bytes32(uint256(4));
    bytes32 internal constant LISTED_FEE_SLOT = bytes32(uint256(5));
    bytes32 internal constant VARIABLE_FACTOR_SLOT = bytes32(uint256(6));
    bytes32 internal constant TOKEN_FACTORS_SLOT = bytes32(uint256(7));
    bytes32 internal constant LOAN_METADATA_URI_SLOT = bytes32(uint256(8)); // `loanMetadataUri` mapping position
    bytes32 internal constant SFC_REGISTRY_SLOT = bytes32(uint256(9)); // `_sfComputerRegistry` mapping position
    bytes32 internal constant POOL_ADAPTER_REGISTRY_SLOT = bytes32(uint256(10)); // `_poolAdapterRegistry` mapping position

    SDConfig config;
    address owner = makeAddr("owner");
    address sdex = makeAddr("sdex");
    address sink = makeAddr("sink");
    address creditToken = makeAddr("creditToken");

    event ListedFeeUpdated(uint256 oldFee, uint256 newFee);
    event UnlistedFeeUpdated(uint256 oldFee, uint256 newFee);
    event VariableFactorUpdated(uint256 oldFactor, uint256 newFactor);
    event SDEXInitialized(address sdex);
    event SinkInitialized(address sink);
    event ListedTokenUpdated(address token, uint256 factor);

    function setUp() public virtual {
        config = new SDConfig();
    }

    function _initialize() internal {
        // initialize variables
        vm.store(address(config), OWNER_SLOT, bytes32(uint256(uint160(owner))));
        vm.store(address(config), SDEX_SLOT, bytes32(uint256(uint160(sdex))));
        vm.store(address(config), SINK_SLOT, bytes32(uint256(uint160(sink))));
    }
}

/*----------------------------------------------------------*|
|*  # CONSTRUCTOR                                           *|
|*----------------------------------------------------------*/

contract SDConfig_Constructor_Test is SDConfigTest {
    function test_shouldInitializeWithZeroValues() external view {
        bytes32 ownerValue = vm.load(address(config), OWNER_SLOT);
        assertEq(address(uint160(uint256(ownerValue))), address(0));

        bytes32 initializedSlotValue = vm.load(address(config), INITIALIZED_SLOT);
        assertEq(uint16(uint256((initializedSlotValue << 88) >> 248)), 255); // disable initializers

        bytes32 sdexValue = vm.load(address(config), SDEX_SLOT);
        assertEq(address(uint160(uint256(sdexValue))), address(0));

        bytes32 sinkValue = vm.load(address(config), SINK_SLOT);
        assertEq(address(uint160(uint256(sinkValue))), address(0));

        bytes32 unlistedFeeValue = vm.load(address(config), UNLISTED_FEE_SLOT);
        assertEq(uint256(unlistedFeeValue), 0);

        bytes32 listedFeeValue = vm.load(address(config), LISTED_FEE_SLOT);
        assertEq(uint256(listedFeeValue), 0);

        bytes32 variableFactorValue = vm.load(address(config), VARIABLE_FACTOR_SLOT);
        assertEq(uint256(variableFactorValue), 0);
    }
}

/*----------------------------------------------------------*|
|*  # INITIALIZE                                            *|
|*----------------------------------------------------------*/

contract SDConfig_Initialize_Test is SDConfigTest {
    uint256 unlistedFee = 500e18;
    uint256 listedFee = 30e18;
    uint256 variableFactor = 1e13;

    function setUp() public override {
        super.setUp();

        // mock that contract is not initialized
        vm.store(address(config), INITIALIZED_SLOT, bytes32(0));
    }

    function test_shouldSetValues() external {
        config.initialize(owner, sdex, sink, unlistedFee, listedFee, variableFactor);

        bytes32 ownerValue = vm.load(address(config), OWNER_SLOT);
        assertEq(address(uint160(uint256(ownerValue))), owner);

        bytes32 sdexValue = vm.load(address(config), SDEX_SLOT);
        assertEq(address(uint160(uint256(sdexValue))), sdex);

        bytes32 sinkValue = vm.load(address(config), SINK_SLOT);
        assertEq(address(uint160(uint256(sinkValue))), sink);

        bytes32 unlistedFeeValue = vm.load(address(config), UNLISTED_FEE_SLOT);
        assertEq(uint256(unlistedFeeValue), unlistedFee);

        bytes32 listedFeeValue = vm.load(address(config), LISTED_FEE_SLOT);
        assertEq(uint256(listedFeeValue), listedFee);

        bytes32 variableFactorValue = vm.load(address(config), VARIABLE_FACTOR_SLOT);
        assertEq(uint256(variableFactorValue), variableFactor);
    }

    function test_shouldFail_whenCalledSecondTime() external {
        config.initialize(owner, sdex, sink, unlistedFee, listedFee, variableFactor);

        vm.expectRevert("Initializable: contract is already initialized");
        config.initialize(owner, sdex, sink, unlistedFee, listedFee, variableFactor);
    }

    function test_shouldFail_whenOwnerIsZeroAddress() external {
        vm.expectRevert("Owner is zero address");
        config.initialize(address(0), sdex, sink, unlistedFee, listedFee, variableFactor);
    }

    function test_shouldFail_whenSDEXIsZeroAddress() external {
        vm.expectRevert(abi.encodeWithSelector(SDConfig.ZeroAddress.selector));
        config.initialize(owner, address(0), sink, unlistedFee, listedFee, variableFactor);
    }

    function test_shouldFail_whenSinkIsZeroAddress() external {
        vm.expectRevert(abi.encodeWithSelector(SDConfig.ZeroAddress.selector));
        config.initialize(owner, sdex, address(0), unlistedFee, listedFee, variableFactor);
    }
}

/*----------------------------------------------------------*|
|*  # SET UNLISTED FEE                                      *|
|*----------------------------------------------------------*/

contract SDConfig_SetUnlistedFee_Test is SDConfigTest {
    uint256 fee = 90e18;

    function setUp() public override {
        super.setUp();

        _initialize();
    }

    function test_shouldFail_whenCallerIsNotOwner() external {
        vm.expectRevert("Ownable: caller is not the owner");
        config.setUnlistedFee(fee);
    }

    function test_shouldSetFeeValue() external {
        vm.prank(owner);
        config.setUnlistedFee(fee);

        bytes32 unlistedFeeValue = vm.load(address(config), UNLISTED_FEE_SLOT);
        assertEq(uint256(unlistedFeeValue), fee);
    }

    function test_shouldEmitEvent_FeeUpdated() external {
        vm.expectEmit(true, true, false, false);
        emit UnlistedFeeUpdated(0, fee);

        vm.prank(owner);
        config.setUnlistedFee(fee);
    }
}

/*----------------------------------------------------------*|
|*  # SET LISTED FEE                                      *|
|*----------------------------------------------------------*/

contract SDConfig_SetListedFee_Test is SDConfigTest {
    uint256 fee = 90e18;

    function setUp() public override {
        super.setUp();

        _initialize();
    }

    function test_shouldFail_whenCallerIsNotOwner() external {
        vm.expectRevert("Ownable: caller is not the owner");
        config.setListedFee(fee);
    }

    function test_shouldSetFeeValue() external {
        vm.prank(owner);
        config.setListedFee(fee);

        bytes32 listedFeeValue = vm.load(address(config), LISTED_FEE_SLOT);
        assertEq(uint256(listedFeeValue), fee);
    }

    function test_shouldEmitEvent_FeeUpdated() external {
        vm.expectEmit(true, true, false, false);
        emit ListedFeeUpdated(0, fee);

        vm.prank(owner);
        config.setListedFee(fee);
    }
}

/*----------------------------------------------------------*|
|*  # SET LISTED TOKEN                                      *|
|*----------------------------------------------------------*/

contract SDConfig_SetListedToken_Test is SDConfigTest {
    uint256 factor = 1e14;

    function setUp() public override {
        super.setUp();

        _initialize();
    }

    function test_shouldFail_whenCallerIsNotOwner() external {
        vm.expectRevert("Ownable: caller is not the owner");
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
        emit ListedTokenUpdated(creditToken, factor);

        vm.prank(owner);
        config.setListedToken(creditToken, factor);
    }
}
