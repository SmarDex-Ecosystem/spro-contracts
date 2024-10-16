// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import { Spro } from "src/spro/Spro.sol";
import { ISproEvents } from "src/interfaces/ISproEvents.sol";
import { ISproErrors } from "src/interfaces/ISproErrors.sol";

// forge inspect src/config/Spro.sol:Spro storage --pretty

abstract contract SproTest is Test {
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

    Spro config;
    address owner = address(this);
    address sdex = makeAddr("sdex");
    address public permit2 = makeAddr("permit2");
    address public weth9 = makeAddr("weth9");
    address alice = makeAddr("alice");
    address creditToken = makeAddr("creditToken");

    uint256 fixFeeUnlisted = 500e18;
    uint256 fixFeeListed = 30e18;
    uint256 variableFactor = 1e13;
    uint16 partialPositionBps = 900;
    uint16 PERCENTAGE = 1e4;

    function setUp() public virtual {
        config = new Spro(sdex, permit2, weth9, fixFeeUnlisted, fixFeeListed, variableFactor, partialPositionBps);
    }

    function _mockSupportsToken(address computer, address token, bool result) internal {
        vm.mockCall(computer, abi.encodeWithSignature("supportsToken(address)", token), abi.encode(result));
    }
}

/* -------------------------------------------------------------------------- */
/*                                 CONSTRUCTOR                                */
/* -------------------------------------------------------------------------- */

contract TestSproConstructor is SproTest {
    function test_shouldInitializeWithCorrectValues() external view {
        assertEq(config.owner(), owner);
        assertEq(config.partialPositionBps(), partialPositionBps);
        assertEq(config.fixFeeUnlisted(), fixFeeUnlisted);
        assertEq(config.fixFeeListed(), fixFeeListed);
        assertEq(config.variableFactor(), variableFactor);
        assertEq(sdex, config.SDEX());
    }
}

/* ------------------------------------------------------------ */
/*  SET FIX FEE UNLISTED                                     */
/* ------------------------------------------------------------ */

contract TestSproSetUnlistedFee is SproTest {
    uint256 fee = 90e18;

    function test_shouldFail_whenCallerIsNotOwner() external {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        vm.prank(alice);
        config.setFixFeeUnlisted(fee);
    }

    function test_shouldSetFeeValue() external {
        vm.prank(owner);
        config.setFixFeeUnlisted(fee);

        assertEq(config.fixFeeUnlisted(), fee);
    }

    function test_shouldEmitEvent_FeeUpdated() external {
        vm.expectEmit(true, true, true, true);
        emit ISproEvents.FixFeeUnlistedUpdated(fixFeeUnlisted, fee);

        vm.prank(owner);
        config.setFixFeeUnlisted(fee);
    }
}

/* ------------------------------------------------------------ */
/*  SET FIX FEE LISTED                                       */
/* ------------------------------------------------------------ */

contract TestSproSetListedFee is SproTest {
    uint256 fee = 90e18;

    function test_shouldFail_whenCallerIsNotOwner() external {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        vm.prank(alice);
        config.setFixFeeListed(fee);
    }

    function test_shouldSetFeeValue() external {
        vm.prank(owner);
        config.setFixFeeListed(fee);

        assertEq(config.fixFeeListed(), fee);
    }

    function test_shouldEmitEvent_FeeUpdated() external {
        vm.expectEmit(true, true, false, false);
        emit ISproEvents.FixFeeListedUpdated(fixFeeListed, fee);

        vm.prank(owner);
        config.setFixFeeListed(fee);
    }
}

/* ------------------------------------------------------------ */
/*  SET LISTED TOKEN                                         */
/* ------------------------------------------------------------ */

contract TestSproSetListedToken is SproTest {
    uint256 factor = 1e14;

    function test_shouldFail_whenCallerIsNotOwner() external {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        vm.prank(alice);
        config.setListedToken(creditToken, factor);
    }

    function test_shouldSetListedTokenValue() external {
        vm.prank(owner);
        config.setListedToken(creditToken, factor);

        assertEq(config.tokenFactors(creditToken), factor);
    }

    function test_shouldSetListedTokenValue_ResetToZero() external {
        vm.prank(owner);
        config.setListedToken(creditToken, factor);

        assertEq(config.tokenFactors(creditToken), factor);

        // Reset
        vm.prank(owner);
        config.setListedToken(creditToken, 0);

        assertEq(config.tokenFactors(creditToken), 0);
    }

    function test_shouldEmitEvent_TokenFactorUpdated() external {
        vm.expectEmit(true, true, false, false);
        emit ISproEvents.ListedTokenUpdated(creditToken, factor);

        vm.prank(owner);
        config.setListedToken(creditToken, factor);
    }
}

/* ------------------------------------------------------------ */
/*  PARTIAL LENDING THRESHOLDS                               */
/* ------------------------------------------------------------ */

contract TestSproPartialLendingThresholds is SproTest {
    uint16 internal constant DEFAULT_THRESHOLD = 500;

    function setUp() public override {
        super.setUp();

        vm.startPrank(owner);
        config.setPartialPositionPercentage(DEFAULT_THRESHOLD);
        vm.stopPrank();
    }

    function test_shouldFail_whenCallerIsNotOwner() external {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        vm.prank(alice);
        config.setPartialPositionPercentage(2000);
    }

    function test_shouldFail_whenZeroPercentage() external {
        vm.startPrank(owner);

        vm.expectRevert(ISproErrors.ZeroPercentageValue.selector);
        config.setPartialPositionPercentage(0);
    }

    function testFuzz_shouldFail_ExcessivePercentage(uint16 percentage) external {
        vm.assume(percentage > PERCENTAGE);
        vm.startPrank(owner);

        vm.expectRevert(abi.encodeWithSelector(ISproErrors.ExcessivePercentageValue.selector, percentage));
        config.setPartialPositionPercentage(percentage);
    }
}

/* ------------------------------------------------------------ */
/*  SET LOAN METADATA URI                                    */
/* ------------------------------------------------------------ */

contract TestSprosetLoanMetadataUri is SproTest {
    string tokenUri = "test.token.uri";
    address loanContract = address(0x63);

    function test_shouldFail_whenCallerIsNotOwner() external {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        vm.prank(alice);
        config.setLoanMetadataUri(loanContract, tokenUri);
    }

    function test_shouldFail_whenZeroLoanContract() external {
        vm.expectRevert(abi.encodeWithSelector(ISproErrors.DefaultLoanContract.selector));
        vm.prank(owner);
        config.setLoanMetadataUri(address(0), tokenUri);
    }

    function testFuzz_shouldStoreLoanMetadataUriToLoanContract(address _loanContract) external {
        vm.assume(_loanContract != address(0));
        loanContract = _loanContract;

        vm.prank(owner);
        config.setLoanMetadataUri(loanContract, tokenUri);

        assertEq(config._loanMetadataUri(loanContract), tokenUri);
    }

    function test_shouldEmitEvent_LoanMetadataUriUpdated() external {
        vm.expectEmit(true, true, true, true);
        emit ISproEvents.LoanMetadataUriUpdated(loanContract, tokenUri);

        vm.prank(owner);
        config.setLoanMetadataUri(loanContract, tokenUri);
    }
}

/* ------------------------------------------------------------ */
/*  SET DEFAULT LOAN METADATA URI                            */
/* ------------------------------------------------------------ */

contract TestSprosetDefaultLoanMetadataUri is SproTest {
    string tokenUri = "test.token.uri";

    function test_shouldFail_whenCallerIsNotOwner() external {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        vm.prank(alice);
        config.setDefaultLoanMetadataUri(tokenUri);
    }

    function test_shouldStoreDefaultLoanMetadataUri() external {
        vm.prank(owner);
        config.setDefaultLoanMetadataUri(tokenUri);

        assertEq(config._loanMetadataUri(address(0)), tokenUri);
    }

    function test_shouldEmitEvent_DefaultLoanMetadataUriUpdated() external {
        vm.expectEmit(true, true, true, true);
        emit ISproEvents.DefaultLoanMetadataUriUpdated(tokenUri);

        vm.prank(owner);
        config.setDefaultLoanMetadataUri(tokenUri);
    }
}

/* ------------------------------------------------------------ */
/*  LOAN METADATA URI                                        */
/* ------------------------------------------------------------ */

contract TestSproLoanMetadataUri is SproTest {
    function testFuzz_shouldReturnDefaultLoanMetadataUri_whenNoStoreValueForLoanContract(address loanContract)
        external
    {
        string memory defaultUri = "default.token.uri";

        vm.prank(owner);
        config.setDefaultLoanMetadataUri(defaultUri);

        string memory uri = config.loanMetadataUri(loanContract);
        assertEq(uri, defaultUri);
    }

    function testFuzz_shouldReturnLoanMetadataUri_whenStoredValueForLoanContract(address loanContract) external {
        vm.assume(loanContract != address(0));
        string memory tokenUri = "test.token.uri";

        vm.prank(owner);
        config.setLoanMetadataUri(loanContract, tokenUri);

        string memory uri = config.loanMetadataUri(loanContract);
        assertEq(uri, tokenUri);
    }
}

/* ------------------------------------------------------------ */
/*  GET POOL ADAPTER                                         */
/* ------------------------------------------------------------ */

contract TestSproGetPoolAdapter is SproTest {
    function testFuzz_shouldReturnStoredAdapter_whenIsRegistered(address pool, address adapter) external {
        vm.prank(owner);
        config.registerPoolAdapter(pool, adapter);

        assertEq(address(config.getPoolAdapter(pool)), adapter);
    }
}

/* ------------------------------------------------------------ */
/*  REGISTER POOL ADAPTER                                    */
/* ------------------------------------------------------------ */

contract TestSproRegisterPoolAdapter is SproTest {
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
