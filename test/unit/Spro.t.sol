// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import { Spro } from "src/spro/Spro.sol";
import { ISproEvents } from "src/interfaces/ISproEvents.sol";
import { ISproErrors } from "src/interfaces/ISproErrors.sol";
import { SproConstantsLibrary as Constants } from "src/libraries/SproConstantsLibrary.sol";

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
        // position

    Spro config;
    address owner = address(this);
    address sdex = makeAddr("sdex");
    address public permit2 = makeAddr("permit2");
    address alice = makeAddr("alice");
    address creditToken = makeAddr("creditToken");

    uint256 fee = 500e18;
    uint16 partialPositionBps = 900;
    uint16 PERCENTAGE = 1e4;

    function setUp() public virtual {
        config = new Spro(sdex, permit2, fee, partialPositionBps);
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
        assertEq(config.fee(), fee);
        assertEq(sdex, config.SDEX());
    }

    function test_RevertWhen_incorrectPartialPositionBps() external {
        vm.expectRevert(abi.encodeWithSelector(ISproErrors.IncorrectPercentageValue.selector, 0));
        new Spro(sdex, permit2, fee, 0);

        vm.expectRevert(
            abi.encodeWithSelector(ISproErrors.IncorrectPercentageValue.selector, Constants.BPS_DIVISOR / 2 + 1)
        );
        new Spro(sdex, permit2, fee, uint16(Constants.BPS_DIVISOR / 2 + 1));
    }

    function test_RevertWhen_zeroAddress() external {
        vm.expectRevert(abi.encodeWithSelector(ISproErrors.ZeroAddress.selector));
        new Spro(address(0), permit2, fee, partialPositionBps);

        vm.expectRevert(abi.encodeWithSelector(ISproErrors.ZeroAddress.selector));
        new Spro(sdex, address(0), fee, partialPositionBps);
    }
}

/* -------------------------------------------------------------------------- */
/*                                   SET FEE                                  */
/* -------------------------------------------------------------------------- */

contract TestSproSetUnlistedFee is SproTest {
    function test_shouldFail_whenCallerIsNotOwner() external {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        vm.prank(alice);
        config.setFee(fee);
    }

    function test_shouldSetFeeValue() external {
        vm.prank(owner);
        config.setFee(fee);

        assertEq(config.fee(), fee);
    }

    function test_RevertWhen_ExcessiveFee() external {
        vm.expectRevert(abi.encodeWithSelector(ISproErrors.ExcessiveFee.selector, 1_000_000e18 + 1));
        vm.prank(owner);
        config.setFee(1_000_000e18 + 1);
    }

    function test_shouldEmitEvent_FeeUpdated() external {
        vm.expectEmit(true, true, true, true);
        emit ISproEvents.FeeUpdated(fee, 50e18);

        vm.prank(owner);
        config.setFee(50e18);
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

        vm.expectRevert(abi.encodeWithSelector(ISproErrors.IncorrectPercentageValue.selector, percentage));
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
