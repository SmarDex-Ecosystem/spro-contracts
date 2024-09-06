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
    event LOANMetadataUriUpdated(address indexed loanContract, string newUri);
    event DefaultLOANMetadataUriUpdated(string newUri);

    function setUp() public virtual {
        config = new SDConfig();
    }

    function _initialize() internal {
        // initialize variables
        vm.store(address(config), OWNER_SLOT, bytes32(uint256(uint160(owner))));
        vm.store(address(config), SDEX_SLOT, bytes32(uint256(uint160(sdex))));
        vm.store(address(config), SINK_SLOT, bytes32(uint256(uint160(sink))));
    }

    function _mockSupportsToken(address computer, address token, bool result) internal {
        vm.mockCall(computer, abi.encodeWithSignature("supportsToken(address)", token), abi.encode(result));
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

/*----------------------------------------------------------*|
|*  # PARTIAL LENDING THRESHOLDS                            *|
|*----------------------------------------------------------*/

contract SDConfig_PartialLendingThresholds_Test is SDConfigTest {
    uint16 internal constant PERCENTAGE = 1e4;
    uint16 internal constant DEFAULT_MIN_THRESHOLD = 500;
    uint16 internal constant DEFAULT_MAX_THRESHOLD = 9500;

    function setUp() public override {
        super.setUp();

        _initialize();

        vm.startPrank(owner);
        config.setMaximumPartialPositionPercentage(DEFAULT_MAX_THRESHOLD);
        config.setMinimumPartialPositionPercentage(DEFAULT_MIN_THRESHOLD);
        vm.stopPrank();
    }

    function test_shouldFail_whenCallerIsNotOwner() external {
        vm.expectRevert("Ownable: caller is not the owner");
        config.setMinimumPartialPositionPercentage(2000);

        vm.expectRevert("Ownable: caller is not the owner");
        config.setMaximumPartialPositionPercentage(9500);
    }

    function testFuzz_shouldFail_ExcessivePercentage(uint16 percentage) external {
        vm.assume(percentage > PERCENTAGE);
        vm.startPrank(owner);

        vm.expectRevert(abi.encodeWithSelector(SDConfig.ExcessivePercentageValue.selector, percentage));
        config.setMinimumPartialPositionPercentage(percentage);

        vm.expectRevert(abi.encodeWithSelector(SDConfig.ExcessivePercentageValue.selector, percentage));
        config.setMaximumPartialPositionPercentage(percentage);
    }

    function test_shouldFail_setMinimumAboveMaximum() external {
        vm.startPrank(owner);
        vm.expectRevert(SDConfig.ThresholdsOutOfOrder.selector);
        config.setMinimumPartialPositionPercentage(DEFAULT_MAX_THRESHOLD + 1);
    }

    function test_shouldFail_setMaximumBelowMinimum() external {
        vm.startPrank(owner);
        vm.expectRevert(SDConfig.ThresholdsOutOfOrder.selector);
        config.setMaximumPartialPositionPercentage(DEFAULT_MIN_THRESHOLD - 1);
    }
}

/*----------------------------------------------------------*|
|*  # SET LOAN METADATA URI                                 *|
|*----------------------------------------------------------*/

contract SDConfig_SetLOANMetadataUri_Test is SDConfigTest {
    string tokenUri = "test.token.uri";
    address loanContract = address(0x63);

    function setUp() public override {
        super.setUp();

        _initialize();
    }

    function test_shouldFail_whenCallerIsNotOwner() external {
        vm.expectRevert("Ownable: caller is not the owner");
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
        emit LOANMetadataUriUpdated(loanContract, tokenUri);

        vm.prank(owner);
        config.setLOANMetadataUri(loanContract, tokenUri);
    }
}

/*----------------------------------------------------------*|
|*  # SET DEFAULT LOAN METADATA URI                         *|
|*----------------------------------------------------------*/

contract SDConfig_SetDefaultLOANMetadataUri_Test is SDConfigTest {
    string tokenUri = "test.token.uri";

    function setUp() public override {
        super.setUp();

        _initialize();
    }

    function test_shouldFail_whenCallerIsNotOwner() external {
        vm.expectRevert("Ownable: caller is not the owner");
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
        emit DefaultLOANMetadataUriUpdated(tokenUri);

        vm.prank(owner);
        config.setDefaultLOANMetadataUri(tokenUri);
    }
}

/*----------------------------------------------------------*|
|*  # LOAN METADATA URI                                     *|
|*----------------------------------------------------------*/

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

/*----------------------------------------------------------*|
|*  # GET STATE FINGERPRINT COMPUTER                        *|
|*----------------------------------------------------------*/

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

/*----------------------------------------------------------*|
|*  # REGISTER STATE FINGERPRINT COMPUTER                   *|
|*----------------------------------------------------------*/

contract SDConfig_RegisterStateFingerprintComputer_Test is SDConfigTest {
    function setUp() public override {
        super.setUp();

        _initialize();
    }

    function testFuzz_shouldFail_whenCallerIsNotOwner(address caller) external {
        vm.assume(caller != owner);

        vm.expectRevert("Ownable: caller is not the owner");
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

/*----------------------------------------------------------*|
|*  # GET POOL ADAPTER                                      *|
|*----------------------------------------------------------*/

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

/*----------------------------------------------------------*|
|*  # REGISTER POOL ADAPTER                                 *|
|*----------------------------------------------------------*/

contract SDConfig_RegisterPoolAdapter_Test is SDConfigTest {
    function setUp() public override {
        super.setUp();

        _initialize();
    }

    function testFuzz_shouldFail_whenCallerIsNotOwner(address caller) external {
        vm.assume(caller != owner);

        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(caller);
        config.registerPoolAdapter(address(0), address(0));
    }

    function testFuzz_shouldStoreAdapter(address pool, address adapter) external {
        vm.prank(owner);
        config.registerPoolAdapter(pool, adapter);

        assertEq(address(config.getPoolAdapter(pool)), adapter);
    }
}
