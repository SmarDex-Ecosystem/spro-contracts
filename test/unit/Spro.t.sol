// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import { Test } from "forge-std/Test.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { Spro } from "src/spro/Spro.sol";
import { ISproEvents } from "src/interfaces/ISproEvents.sol";
import { ISproErrors } from "src/interfaces/ISproErrors.sol";
import { SproConstantsLibrary as Constants } from "src/libraries/SproConstantsLibrary.sol";

abstract contract SproTest is Test {
    Spro config;
    address owner = address(this);
    address sdex = makeAddr("sdex");
    address public permit2 = makeAddr("permit2");
    address alice = makeAddr("alice");

    uint256 constant FEE = 500e18;
    uint16 partialPositionBps = 900;

    function setUp() public virtual {
        config = new Spro(sdex, permit2, FEE, partialPositionBps);
    }
}

/* -------------------------------------------------------------------------- */
/*                                 CONSTRUCTOR                                */
/* -------------------------------------------------------------------------- */

contract TestSproConstructor is SproTest {
    function test_shouldInitializeWithCorrectValues() external view {
        assertEq(config.owner(), owner);
        assertEq(config._partialPositionBps(), partialPositionBps);
        assertEq(config._fee(), FEE);
        assertEq(sdex, config.SDEX());
    }

    function test_RevertWhen_incorrectPartialPositionBps() external {
        vm.expectRevert(abi.encodeWithSelector(ISproErrors.IncorrectPercentageValue.selector, 0));
        new Spro(sdex, permit2, FEE, 0);

        vm.expectRevert(
            abi.encodeWithSelector(ISproErrors.IncorrectPercentageValue.selector, Constants.BPS_DIVISOR / 2 + 1)
        );
        new Spro(sdex, permit2, FEE, uint16(Constants.BPS_DIVISOR / 2 + 1));
    }

    function test_RevertWhen_zeroAddress() external {
        vm.expectRevert(abi.encodeWithSelector(ISproErrors.ZeroAddress.selector));
        new Spro(address(0), permit2, FEE, partialPositionBps);

        vm.expectRevert(abi.encodeWithSelector(ISproErrors.ZeroAddress.selector));
        new Spro(sdex, address(0), FEE, partialPositionBps);
    }
}

/* -------------------------------------------------------------------------- */
/*                                   SET FEE                                  */
/* -------------------------------------------------------------------------- */

contract TestSproSetFee is SproTest {
    function test_RevertWhen_callerIsNotOwner() external {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        vm.prank(alice);
        config.setFee(FEE);
    }

    function test_RevertWhen_excessiveFee() external {
        vm.expectRevert(abi.encodeWithSelector(ISproErrors.ExcessiveFee.selector, Constants.MAX_SDEX_FEE + 1));
        vm.prank(owner);
        config.setFee(Constants.MAX_SDEX_FEE + 1);
    }

    function test_feeUpdated() external {
        vm.expectEmit(true, true, true, true);
        emit ISproEvents.FeeUpdated(FEE + 1);

        vm.prank(owner);
        config.setFee(FEE + 1);
        assertEq(config._fee(), FEE + 1);
    }
}

/* -------------------------------------------------------------------------- */
/*                         PARTIAL LENDING THRESHOLDS                         */
/* -------------------------------------------------------------------------- */

contract TestSproPartialLendingThresholds is SproTest {
    uint16 internal constant PARTIAL_POSITION_BPS = 500;

    function setUp() public override {
        super.setUp();

        vm.startPrank(owner);
        config.setPartialPositionPercentage(PARTIAL_POSITION_BPS);
        vm.stopPrank();
    }

    function test_partialPositionBpsUpdatedEmitEvent() external {
        vm.expectEmit(true, true, true, true);
        emit ISproEvents.PartialPositionBpsUpdated(PARTIAL_POSITION_BPS + 1);

        vm.prank(owner);
        config.setPartialPositionPercentage(PARTIAL_POSITION_BPS + 1);
        assertEq(config._partialPositionBps(), PARTIAL_POSITION_BPS + 1);
    }

    function test_RevertWhen_whenCallerIsNotOwner() external {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        vm.prank(alice);
        config.setPartialPositionPercentage(PARTIAL_POSITION_BPS);
    }

    function test_RevertWhen_whenZeroPercentage() external {
        vm.startPrank(owner);

        vm.expectRevert(ISproErrors.ZeroPercentageValue.selector);
        config.setPartialPositionPercentage(0);
    }

    function testFuzz_RevertWhen_excessivePercentage(uint16 percentage) external {
        vm.assume(percentage > Constants.BPS_DIVISOR / 2);
        vm.startPrank(owner);

        vm.expectRevert(abi.encodeWithSelector(ISproErrors.IncorrectPercentageValue.selector, percentage));
        config.setPartialPositionPercentage(percentage);
    }
}

/* -------------------------------------------------------------------------- */
/*                            SET LOAN METADATA URI                           */
/* -------------------------------------------------------------------------- */

contract TestSproSetLoanMetadataUri is SproTest {
    string tokenUri = "test.token.uri";

    function test_RevertWhen_whenCallerIsNotOwner() external {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        vm.prank(alice);
        config.setLoanMetadataUri(tokenUri);
    }

    function testFuzz_shouldStoreLoanMetadataUri(string memory uri) external {
        vm.prank(owner);
        config.setLoanMetadataUri(uri);

        assertEq(config._loanToken()._metadataUri(), uri);
    }
}
