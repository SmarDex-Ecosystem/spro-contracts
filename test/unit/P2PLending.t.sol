// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import { Test } from "forge-std/Test.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { P2PLending } from "src/p2pLending/P2PLending.sol";
import { IP2PLendingEvents } from "src/interfaces/IP2PLendingEvents.sol";
import { IP2PLendingErrors } from "src/interfaces/IP2PLendingErrors.sol";
import { IP2PLendingTypes } from "src/interfaces/IP2PLendingTypes.sol";

contract P2PLendingTest is Test {
    P2PLending spro;
    address owner = address(this);
    address sdex = makeAddr("sdex");
    address permit2 = makeAddr("permit2");
    address alice = makeAddr("alice");

    uint256 constant FEE = 500e18;
    uint16 partialPositionBps = 900;

    function setUp() public virtual {
        spro = new P2PLending(sdex, permit2, FEE, partialPositionBps, owner);
    }
}

/* -------------------------------------------------------------------------- */
/*                                 CONSTRUCTOR                                */
/* -------------------------------------------------------------------------- */

contract TestP2PLendingConstructor is P2PLendingTest {
    function test_shouldInitializeWithCorrectValues() external view {
        assertEq(spro.owner(), owner);
        assertEq(spro._partialPositionBps(), partialPositionBps);
        assertEq(spro._fee(), FEE);
        assertEq(sdex, spro.SDEX());
    }

    function test_RevertWhen_incorrectPartialPositionBps() external {
        vm.expectRevert(abi.encodeWithSelector(IP2PLendingErrors.IncorrectPercentageValue.selector, 0));
        new P2PLending(sdex, permit2, FEE, 0, owner);

        uint256 bpsDivisor = spro.BPS_DIVISOR();
        vm.expectRevert(abi.encodeWithSelector(IP2PLendingErrors.IncorrectPercentageValue.selector, bpsDivisor / 2 + 1));
        new P2PLending(sdex, permit2, FEE, uint16(bpsDivisor / 2 + 1), owner);
    }

    function test_RevertWhen_zeroAddress() external {
        vm.expectRevert(abi.encodeWithSelector(IP2PLendingErrors.ZeroAddress.selector));
        new P2PLending(address(0), permit2, FEE, partialPositionBps, owner);

        vm.expectRevert(abi.encodeWithSelector(IP2PLendingErrors.ZeroAddress.selector));
        new P2PLending(sdex, address(0), FEE, partialPositionBps, owner);
    }

    function test_RevertWhen_incorrectFee() external {
        uint256 maxSdexFee = spro.MAX_SDEX_FEE();
        vm.expectRevert(abi.encodeWithSelector(IP2PLendingErrors.ExcessiveFee.selector, maxSdexFee + 1));
        new P2PLending(sdex, permit2, maxSdexFee + 1, partialPositionBps, owner);
    }
}

/* -------------------------------------------------------------------------- */
/*                                   SET FEE                                  */
/* -------------------------------------------------------------------------- */

contract TestP2PLendingSetFee is P2PLendingTest {
    function test_RevertWhen_callerIsNotOwner() external {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        vm.prank(alice);
        spro.setFee(FEE);
    }

    function test_RevertWhen_excessiveFee() external {
        uint256 maxSdexFee = spro.MAX_SDEX_FEE();
        vm.expectRevert(abi.encodeWithSelector(IP2PLendingErrors.ExcessiveFee.selector, maxSdexFee + 1));
        vm.prank(owner);
        spro.setFee(maxSdexFee + 1);
    }

    function test_feeUpdated() external {
        vm.expectEmit(true, true, true, true);
        emit IP2PLendingEvents.FeeUpdated(FEE + 1);

        vm.prank(owner);
        spro.setFee(FEE + 1);
        assertEq(spro._fee(), FEE + 1);
    }
}

/* -------------------------------------------------------------------------- */
/*                         PARTIAL LENDING THRESHOLDS                         */
/* -------------------------------------------------------------------------- */

contract TestP2PLendingPartialLendingThresholds is P2PLendingTest {
    uint16 internal constant PARTIAL_POSITION_BPS = 500;

    function setUp() public override {
        super.setUp();

        vm.startPrank(owner);
        spro.setPartialPositionPercentage(PARTIAL_POSITION_BPS);
        vm.stopPrank();
    }

    function test_partialPositionBpsUpdatedEmitEvent() external {
        vm.expectEmit(true, true, true, true);
        emit IP2PLendingEvents.PartialPositionBpsUpdated(PARTIAL_POSITION_BPS + 1);

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
        vm.expectRevert(abi.encodeWithSelector(IP2PLendingErrors.IncorrectPercentageValue.selector, 0));
        spro.setPartialPositionPercentage(0);
    }

    function testFuzz_RevertWhen_excessivePercentage(uint16 percentage) external {
        vm.assume(percentage > spro.BPS_DIVISOR() / 2);
        vm.startPrank(owner);

        vm.expectRevert(abi.encodeWithSelector(IP2PLendingErrors.IncorrectPercentageValue.selector, percentage));
        spro.setPartialPositionPercentage(percentage);
    }
}

/* -------------------------------------------------------------------------- */
/*                             tryClaimRepaidLoan                             */
/* -------------------------------------------------------------------------- */

contract TestP2PLendingTryClaimRepaidLoan is P2PLendingTest {
    function test_RevertWhen_tryClaimRepaidLoanUnauthorized() external {
        vm.expectRevert(IP2PLendingErrors.UnauthorizedCaller.selector);
        spro.tryClaimRepaidLoan(0, 0, address(0), address(0));
    }
}

/* -------------------------------------------------------------------------- */
/*                                   GETTER                                   */
/* -------------------------------------------------------------------------- */

contract TestP2PLendingGetLoan is P2PLendingTest {
    function test_getLoanReturnZeroForNonExistingLoan() external view {
        IP2PLendingTypes.Loan memory loan = spro.getLoan(0);

        assertEq(loan.lender, address(0));
    }
}
