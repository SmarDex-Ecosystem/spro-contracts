// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IAllowanceTransfer } from "permit2/src/interfaces/IAllowanceTransfer.sol";
import { PermitSignature } from "permit2/test/utils/PermitSignature.sol";

import { SDBaseIntegrationTest } from "test/integration/utils/Fixtures.sol";

import { ISproTypes } from "src/interfaces/ISproTypes.sol";
import { ISproErrors } from "src/interfaces/ISproErrors.sol";
import { Spro } from "src/spro/Spro.sol";

contract TestForkPermit2 is SDBaseIntegrationTest, PermitSignature {
    uint256 internal constant SIG_USER1_PK = 1;
    address internal sigUser1 = vm.addr(SIG_USER1_PK);

    function setUp() public {
        _setUp(true);

        // Mint and approve SDEX
        sdex.mint(borrower, INITIAL_SDEX_BALANCE);
        sdex.mint(sigUser1, INITIAL_SDEX_BALANCE);
        credit.mint(sigUser1, CREDIT_LIMIT);
        vm.prank(sigUser1);
        credit.approve(address(permit2), type(uint256).max);
    }

    function test_ForkPermit2CreateLoan() public {
        IAllowanceTransfer.PermitDetails memory details =
            IAllowanceTransfer.PermitDetails(address(proposal.creditAddress), uint160(CREDIT_LIMIT), 0, 0);
        IAllowanceTransfer.PermitSingle memory permitSign =
            IAllowanceTransfer.PermitSingle(details, address(spro), block.timestamp);
        bytes memory signature = getPermitSignature(permitSign, SIG_USER1_PK, permit2.DOMAIN_SEPARATOR());

        _createERC20Proposal();

        vm.prank(sigUser1);
        spro.createLoan(proposal, CREDIT_LIMIT, abi.encode(permitSign, signature));

        assertEq(credit.balanceOf(address(sigUser1)), 0, "sigUser1 must transfer credit");
        assertEq(credit.balanceOf(address(borrower)), CREDIT_LIMIT, "borrower must receive credit");
        assertEq(collateral.balanceOf(address(spro)), COLLATERAL_AMOUNT, "spro keeps the collateral");
    }

    function test_RevertWhen_ForkPermit2CreateLoan() public {
        IAllowanceTransfer.PermitDetails memory details =
            IAllowanceTransfer.PermitDetails(address(proposal.creditAddress), uint160(CREDIT_LIMIT - 1), 0, 0);
        IAllowanceTransfer.PermitSingle memory permitSign =
            IAllowanceTransfer.PermitSingle(details, address(spro), block.timestamp);
        bytes memory signature = getPermitSignature(permitSign, SIG_USER1_PK, permit2.DOMAIN_SEPARATOR());

        _createERC20Proposal();

        vm.expectRevert(abi.encodeWithSelector(IAllowanceTransfer.InsufficientAllowance.selector, CREDIT_LIMIT - 1));
        vm.prank(sigUser1);
        spro.createLoan(proposal, CREDIT_LIMIT, abi.encode(permitSign, signature));
    }

    function test_ForkPermit2CreateProposal() public {
        proposal.proposer = sigUser1;
        vm.startPrank(sigUser1);
        IERC20(proposal.collateralAddress).approve(address(permit2), type(uint256).max);
        sdex.approve(address(permit2), type(uint256).max);
        IAllowanceTransfer.PermitDetails[] memory details = new IAllowanceTransfer.PermitDetails[](2);
        details[0] = IAllowanceTransfer.PermitDetails(
            address(proposal.collateralAddress), uint160(COLLATERAL_AMOUNT), uint48(block.timestamp), 0
        );
        details[1] = IAllowanceTransfer.PermitDetails(address(sdex), uint160(spro._fee()), uint48(block.timestamp), 0);
        IAllowanceTransfer.PermitBatch memory permitBatch =
            IAllowanceTransfer.PermitBatch(details, address(spro), block.timestamp);
        bytes memory signature = getPermitBatchSignature(permitBatch, SIG_USER1_PK, permit2.DOMAIN_SEPARATOR());

        collateral.mint(sigUser1, proposal.collateralAmount);

        spro.createProposal(
            proposal.collateralAddress,
            proposal.collateralAmount,
            proposal.creditAddress,
            proposal.availableCreditLimit,
            proposal.fixedInterestAmount,
            proposal.startTimestamp,
            proposal.loanExpiration,
            abi.encode(permitBatch, signature)
        );
        vm.stopPrank();

        assertEq(collateral.balanceOf(address(sigUser1)), 0, "borrower must transfer collateral");
        assertEq(collateral.balanceOf(address(spro)), COLLATERAL_AMOUNT, "spro must receive collateral");
    }

    function test_RevertWhen_ForkPermit2CreateProposal() public {
        proposal.proposer = sigUser1;
        vm.startPrank(sigUser1);
        IERC20(proposal.collateralAddress).approve(address(permit2), type(uint256).max);
        sdex.approve(address(permit2), type(uint256).max);
        IAllowanceTransfer.PermitDetails[] memory details = new IAllowanceTransfer.PermitDetails[](2);
        details[0] = IAllowanceTransfer.PermitDetails(
            address(proposal.collateralAddress), uint160(COLLATERAL_AMOUNT - 1), uint48(block.timestamp), 0
        );
        details[1] = IAllowanceTransfer.PermitDetails(address(sdex), uint160(spro._fee()), uint48(block.timestamp), 0);
        IAllowanceTransfer.PermitBatch memory permitBatch =
            IAllowanceTransfer.PermitBatch(details, address(spro), block.timestamp);
        bytes memory signature = getPermitBatchSignature(permitBatch, SIG_USER1_PK, permit2.DOMAIN_SEPARATOR());

        vm.expectRevert(
            abi.encodeWithSelector(IAllowanceTransfer.InsufficientAllowance.selector, COLLATERAL_AMOUNT - 1)
        );
        spro.createProposal(
            proposal.collateralAddress,
            proposal.collateralAmount,
            proposal.creditAddress,
            proposal.availableCreditLimit,
            proposal.fixedInterestAmount,
            proposal.startTimestamp,
            proposal.loanExpiration,
            abi.encode(permitBatch, signature)
        );
        vm.stopPrank();
    }

    function test_ForkPermit2RepayLoan() public {
        _createERC20Proposal();
        uint256 loanId = _createLoan(proposal, CREDIT_AMOUNT, "");

        vm.prank(borrower);
        spro.cancelProposal(proposal);

        // Warp ahead, just before loan default
        vm.warp(proposal.loanExpiration - proposal.startTimestamp - 1);

        ISproTypes.Loan memory loan = spro.getLoan(loanId);
        uint256 repaymentAmount = loan.principalAmount + loan.fixedInterestAmount;
        IAllowanceTransfer.PermitDetails memory details =
            IAllowanceTransfer.PermitDetails(address(proposal.creditAddress), uint160(repaymentAmount), 0, 0);
        IAllowanceTransfer.PermitSingle memory permitSign =
            IAllowanceTransfer.PermitSingle(details, address(spro), block.timestamp);
        bytes memory signature = getPermitSignature(permitSign, SIG_USER1_PK, permit2.DOMAIN_SEPARATOR());

        vm.prank(sigUser1);
        spro.repayLoan(loanId, abi.encode(permitSign, signature), address(0));

        assertEq(collateral.balanceOf(address(spro)), 0, "spro must transfer collateral");
        assertEq(collateral.balanceOf(address(borrower)), COLLATERAL_AMOUNT, "borrower must receive collateral");
        assertEq(credit.balanceOf(address(spro)), 0, "spro must transfer credit");
        assertEq(
            credit.balanceOf(address(lender)),
            INITIAL_CREDIT_BALANCE - CREDIT_AMOUNT + repaymentAmount,
            "lender must receive repayment"
        );
    }

    function test_RevertWhen_ForkPermit2RepayLoan() public {
        _createERC20Proposal();
        uint256 loanId = _createLoan(proposal, CREDIT_AMOUNT, "");

        vm.prank(borrower);
        spro.cancelProposal(proposal);

        // Warp ahead, just before loan default
        vm.warp(proposal.loanExpiration - proposal.startTimestamp - 1);

        ISproTypes.Loan memory loan = spro.getLoan(loanId);
        uint256 repaymentAmount = loan.principalAmount + loan.fixedInterestAmount;
        IAllowanceTransfer.PermitDetails memory details =
            IAllowanceTransfer.PermitDetails(address(proposal.creditAddress), uint160(repaymentAmount - 1), 0, 0);
        IAllowanceTransfer.PermitSingle memory permitSign =
            IAllowanceTransfer.PermitSingle(details, address(spro), block.timestamp);
        bytes memory signature = getPermitSignature(permitSign, SIG_USER1_PK, permit2.DOMAIN_SEPARATOR());

        vm.expectRevert(abi.encodeWithSelector(IAllowanceTransfer.InsufficientAllowance.selector, repaymentAmount - 1));
        vm.prank(sigUser1);
        spro.repayLoan(loanId, abi.encode(permitSign, signature), address(0));
    }

    function test_ForkPermit2RepayMultipleLoans() public {
        _createERC20Proposal();

        credit.mint(lender, CREDIT_AMOUNT);
        vm.startPrank(lender);
        credit.approve(address(spro), CREDIT_AMOUNT);

        uint256[] memory loanIds = new uint256[](3);
        loanIds[0] = spro.createLoan(proposal, CREDIT_AMOUNT / 3, "");
        loanIds[1] = spro.createLoan(proposal, CREDIT_AMOUNT / 3, "");
        loanIds[2] = spro.createLoan(proposal, CREDIT_AMOUNT / 3, "");
        vm.stopPrank();

        vm.prank(borrower);
        spro.cancelProposal(proposal);

        // Warp ahead, just before loan default
        vm.warp(proposal.loanExpiration - proposal.startTimestamp - 1);

        uint256 totalRepaymentAmount = spro.totalLoanRepaymentAmount(loanIds);
        IAllowanceTransfer.PermitDetails memory details =
            IAllowanceTransfer.PermitDetails(address(proposal.creditAddress), uint160(totalRepaymentAmount), 0, 0);
        IAllowanceTransfer.PermitSingle memory permitSign =
            IAllowanceTransfer.PermitSingle(details, address(spro), block.timestamp);
        bytes memory signature = getPermitSignature(permitSign, SIG_USER1_PK, permit2.DOMAIN_SEPARATOR());

        vm.prank(sigUser1);
        spro.repayMultipleLoans(loanIds, abi.encode(permitSign, signature), address(0));

        assertEq(collateral.balanceOf(address(spro)), 0, "spro must transfer collateral");
        assertEq(collateral.balanceOf(address(borrower)), COLLATERAL_AMOUNT, "borrower must receive collateral");
        assertEq(credit.balanceOf(address(spro)), 0, "spro must transfer credit");
        assertEq(credit.balanceOf(address(lender)), totalRepaymentAmount, "lender must receive repayment");
    }

    function test_RevertWhen_ForkWrongSignPermit2RepayMultipleLoans() public {
        _createERC20Proposal();

        credit.mint(sigUser1, CREDIT_LIMIT);
        vm.prank(sigUser1);
        credit.approve(address(spro), CREDIT_LIMIT);

        vm.startPrank(sigUser1);
        uint256[] memory loanIds = new uint256[](3);
        loanIds[0] = spro.createLoan(proposal, CREDIT_AMOUNT / 3, "");
        loanIds[1] = spro.createLoan(proposal, CREDIT_AMOUNT / 3, "");
        loanIds[2] = spro.createLoan(proposal, CREDIT_AMOUNT / 3, "");
        vm.stopPrank();

        vm.prank(borrower);
        spro.cancelProposal(proposal);

        // Warp ahead, just before loan default
        vm.warp(proposal.loanExpiration - proposal.startTimestamp - 1);

        uint256 totalRepaymentAmount = spro.totalLoanRepaymentAmount(loanIds);
        IAllowanceTransfer.PermitDetails memory details =
            IAllowanceTransfer.PermitDetails(address(proposal.creditAddress), uint160(totalRepaymentAmount - 1), 0, 0);
        IAllowanceTransfer.PermitSingle memory permitSign =
            IAllowanceTransfer.PermitSingle(details, address(spro), block.timestamp);
        bytes memory signature = getPermitSignature(permitSign, SIG_USER1_PK, permit2.DOMAIN_SEPARATOR());

        vm.expectRevert(
            abi.encodeWithSelector(IAllowanceTransfer.InsufficientAllowance.selector, totalRepaymentAmount - 1)
        );
        vm.prank(sigUser1);
        spro.repayMultipleLoans(loanIds, abi.encode(permitSign, signature), address(0));
    }

    function test_ForkPermit2GriefingCreateProposal() public {
        proposal.proposer = sigUser1;
        vm.startPrank(sigUser1);
        IERC20(proposal.collateralAddress).approve(address(permit2), type(uint256).max);
        sdex.approve(address(permit2), type(uint256).max);
        IAllowanceTransfer.PermitDetails[] memory details = new IAllowanceTransfer.PermitDetails[](2);
        details[0] = IAllowanceTransfer.PermitDetails(
            address(proposal.collateralAddress), uint160(COLLATERAL_AMOUNT), uint48(block.timestamp), 0
        );
        details[1] = IAllowanceTransfer.PermitDetails(address(sdex), uint160(spro._fee()), uint48(block.timestamp), 0);
        IAllowanceTransfer.PermitBatch memory permitBatch =
            IAllowanceTransfer.PermitBatch(details, address(spro), block.timestamp);
        bytes memory signature = getPermitBatchSignature(permitBatch, SIG_USER1_PK, permit2.DOMAIN_SEPARATOR());
        vm.stopPrank();

        collateral.mint(sigUser1, proposal.collateralAmount);

        // griefing
        IAllowanceTransfer(spro.PERMIT2()).permit(sigUser1, permitBatch, signature);

        vm.prank(sigUser1);
        spro.createProposal(
            proposal.collateralAddress,
            proposal.collateralAmount,
            proposal.creditAddress,
            proposal.availableCreditLimit,
            proposal.fixedInterestAmount,
            proposal.startTimestamp,
            proposal.loanExpiration,
            abi.encode(permitBatch, signature)
        );

        assertEq(collateral.balanceOf(address(sigUser1)), 0, "borrower must transfer collateral");
        assertEq(collateral.balanceOf(address(spro)), COLLATERAL_AMOUNT, "spro must receive collateral");
    }

    function test_ForkPermit2GriefingCreateLoan() public {
        IAllowanceTransfer.PermitDetails memory details =
            IAllowanceTransfer.PermitDetails(address(proposal.creditAddress), uint160(CREDIT_LIMIT), 0, 0);
        IAllowanceTransfer.PermitSingle memory permitSign =
            IAllowanceTransfer.PermitSingle(details, address(spro), block.timestamp);
        bytes memory signature = getPermitSignature(permitSign, SIG_USER1_PK, permit2.DOMAIN_SEPARATOR());

        _createERC20Proposal();

        // griefing
        IAllowanceTransfer(spro.PERMIT2()).permit(sigUser1, permitSign, signature);

        vm.prank(sigUser1);
        spro.createLoan(proposal, CREDIT_LIMIT, abi.encode(permitSign, signature));

        assertEq(credit.balanceOf(address(sigUser1)), 0, "sigUser1 must transfer credit");
        assertEq(credit.balanceOf(address(borrower)), CREDIT_LIMIT, "borrower must receive credit");
        assertEq(collateral.balanceOf(address(spro)), COLLATERAL_AMOUNT, "spro keeps the collateral");
    }

    function test_RevertWhen_ForkPermit2TransferMismatchCreateProposal() external {
        proposal.proposer = sigUser1;

        vm.startPrank(sigUser1);
        IERC20(proposal.collateralAddress).approve(address(permit2), type(uint256).max);
        sdex.approve(address(permit2), type(uint256).max);
        IAllowanceTransfer.PermitDetails[] memory details = new IAllowanceTransfer.PermitDetails[](2);
        details[0] = IAllowanceTransfer.PermitDetails(
            address(proposal.collateralAddress), uint160(COLLATERAL_AMOUNT), uint48(block.timestamp), 0
        );
        details[1] = IAllowanceTransfer.PermitDetails(address(sdex), uint160(spro._fee()), uint48(block.timestamp), 0);
        IAllowanceTransfer.PermitBatch memory permitBatch =
            IAllowanceTransfer.PermitBatch(details, address(spro), block.timestamp);
        bytes memory signature = getPermitBatchSignature(permitBatch, SIG_USER1_PK, permit2.DOMAIN_SEPARATOR());

        collateral.mint(sigUser1, proposal.collateralAmount);

        collateral.setFee(true);

        vm.expectRevert(ISproErrors.TransferMismatch.selector);
        spro.createProposal(
            proposal.collateralAddress,
            proposal.collateralAmount,
            proposal.creditAddress,
            proposal.availableCreditLimit,
            proposal.fixedInterestAmount,
            proposal.startTimestamp,
            proposal.loanExpiration,
            abi.encode(permitBatch, signature)
        );
        vm.stopPrank();
    }

    function test_RevertWhen_ForkPermit2TransferMismatchCreateLoan() public {
        IAllowanceTransfer.PermitDetails memory details =
            IAllowanceTransfer.PermitDetails(address(proposal.creditAddress), uint160(CREDIT_LIMIT), 0, 0);
        IAllowanceTransfer.PermitSingle memory permitSign =
            IAllowanceTransfer.PermitSingle(details, address(spro), block.timestamp);
        bytes memory signature = getPermitSignature(permitSign, SIG_USER1_PK, permit2.DOMAIN_SEPARATOR());

        _createERC20Proposal();
        credit.mint(sigUser1, CREDIT_LIMIT);
        vm.prank(sigUser1);
        IERC20(proposal.creditAddress).approve(address(permit2), type(uint256).max);

        credit.setFee(true);

        vm.expectRevert(ISproErrors.TransferMismatch.selector);
        vm.prank(sigUser1);
        spro.createLoan(proposal, CREDIT_LIMIT, abi.encode(permitSign, signature));
    }
}
