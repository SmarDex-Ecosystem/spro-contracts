// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import { Test } from "forge-std/Test.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { Spro } from "src/spro/Spro.sol";
import { ISproEvents } from "src/interfaces/ISproEvents.sol";
import { ISproErrors } from "src/interfaces/ISproErrors.sol";
import { ISproTypes } from "src/interfaces/ISproTypes.sol";

contract SproTest is Test {
    Spro spro;
    address owner = address(this);
    address sdex = makeAddr("sdex");
    address permit2 = makeAddr("permit2");
    address alice = makeAddr("alice");

    uint256 constant FEE = 500e18;
    uint16 partialPositionBps = 900;

    function setUp() public virtual {
        spro = new Spro(sdex, permit2, FEE, partialPositionBps);
    }
}

/* -------------------------------------------------------------------------- */
/*                                 CONSTRUCTOR                                */
/* -------------------------------------------------------------------------- */

contract TestSproConstructor is SproTest {
    function test_shouldInitializeWithCorrectValues() external view {
        assertEq(spro.owner(), owner);
        assertEq(spro._partialPositionBps(), partialPositionBps);
        assertEq(spro._fee(), FEE);
        assertEq(sdex, spro.SDEX());
    }

    function test_RevertWhen_incorrectPartialPositionBps() external {
        vm.expectRevert(abi.encodeWithSelector(ISproErrors.IncorrectPercentageValue.selector, 0));
        new Spro(sdex, permit2, FEE, 0);

        uint256 bpsDivisor = spro.BPS_DIVISOR();
        vm.expectRevert(abi.encodeWithSelector(ISproErrors.IncorrectPercentageValue.selector, bpsDivisor / 2 + 1));
        new Spro(sdex, permit2, FEE, uint16(bpsDivisor / 2 + 1));
    }

    function test_RevertWhen_zeroAddress() external {
        vm.expectRevert(abi.encodeWithSelector(ISproErrors.ZeroAddress.selector));
        new Spro(address(0), permit2, FEE, partialPositionBps);

        vm.expectRevert(abi.encodeWithSelector(ISproErrors.ZeroAddress.selector));
        new Spro(sdex, address(0), FEE, partialPositionBps);
    }

    function test_RevertWhen_incorrectFee() external {
        uint256 maxSdexFee = config.MAX_SDEX_FEE();
        vm.expectRevert(abi.encodeWithSelector(ISproErrors.ExcessiveFee.selector, maxSdexFee + 1));
        new Spro(sdex, permit2, maxSdexFee + 1, partialPositionBps);
    }
}

/* -------------------------------------------------------------------------- */
/*                                   SET FEE                                  */
/* -------------------------------------------------------------------------- */

contract TestSproSetFee is SproTest {
    function test_RevertWhen_callerIsNotOwner() external {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        vm.prank(alice);
        spro.setFee(FEE);
    }

    function test_RevertWhen_excessiveFee() external {
        uint256 maxSdexFee = spro.MAX_SDEX_FEE();
        vm.expectRevert(abi.encodeWithSelector(ISproErrors.ExcessiveFee.selector, maxSdexFee + 1));
        vm.prank(owner);
        spro.setFee(maxSdexFee + 1);
    }

    function test_feeUpdated() external {
        vm.expectEmit(true, true, true, true);
        emit ISproEvents.FeeUpdated(FEE + 1);

        vm.prank(owner);
        spro.setFee(FEE + 1);
        assertEq(spro._fee(), FEE + 1);
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
        spro.setPartialPositionPercentage(PARTIAL_POSITION_BPS);
        vm.stopPrank();
    }

    function test_partialPositionBpsUpdatedEmitEvent() external {
        vm.expectEmit(true, true, true, true);
        emit ISproEvents.PartialPositionBpsUpdated(PARTIAL_POSITION_BPS + 1);

        vm.prank(owner);
        spro.setPartialPositionPercentage(PARTIAL_POSITION_BPS + 1);
        assertEq(spro._partialPositionBps(), PARTIAL_POSITION_BPS + 1);
    }

    function test_RevertWhen_whenCallerIsNotOwner() external {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        vm.prank(alice);
        spro.setPartialPositionPercentage(PARTIAL_POSITION_BPS);
    }

    function test_RevertWhen_whenZeroPercentage() external {
        vm.startPrank(owner);
        vm.expectRevert(abi.encodeWithSelector(ISproErrors.IncorrectPercentageValue.selector, 0));
        spro.setPartialPositionPercentage(0);
    }

    function testFuzz_RevertWhen_excessivePercentage(uint16 percentage) external {
        vm.assume(percentage > spro.BPS_DIVISOR() / 2);
        vm.startPrank(owner);

        vm.expectRevert(abi.encodeWithSelector(ISproErrors.IncorrectPercentageValue.selector, percentage));
        spro.setPartialPositionPercentage(percentage);
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
        spro.setLoanMetadataUri(tokenUri);
    }

    function testFuzz_shouldStoreLoanMetadataUri(string memory uri) external {
        vm.prank(owner);
        spro.setLoanMetadataUri(uri);

        assertEq(spro._loanToken()._metadataUri(), uri);
    }
}

/* -------------------------------------------------------------------------- */
/*                             tryClaimRepaidLoan                             */
/* -------------------------------------------------------------------------- */

contract TestSproTryClaimRepaidLoan is SproTest {
    function test_RevertWhen_tryClaimRepaidLoanUnauthorized() external {
        vm.expectRevert(ISproErrors.UnauthorizedCaller.selector);
        spro.tryClaimRepaidLoan(0, 0, address(0), address(0));
    }
}

/* -------------------------------------------------------------------------- */
/*                                   GETTER                                   */
/* -------------------------------------------------------------------------- */

contract TestSproGetLoan is SproTest {
    function test_getLoanReturnZeroForNonExistingLoan() external view {
        ISproTypes.Loan memory loan = spro.getLoan(0);

        assertEq(loan.lender, address(0));
    }
}
