// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IAllowanceTransfer } from "permit2/src/interfaces/IAllowanceTransfer.sol";

import { SproForkBase } from "test/integration/utils/Fixtures.sol";
import { T20 } from "test/helper/T20.sol";
import { Spro } from "test/integration/SDDeploymentTest.t.sol";

import { ISproTypes } from "src/interfaces/ISproTypes.sol";

contract TestForkPermit2 is SproForkBase {
    uint256 public constant COLLATERAL_AMOUNT = 10_000e18;
    uint256 public constant CREDIT_AMOUNT = 60e18;
    uint256 public constant FIXED_INTEREST_AMOUNT = 5e18;
    uint256 public constant CREDIT_LIMIT = 100e18;
    uint256 public constant INITIAL_SDEX_BALANCE = 1_000_000e18;

    T20 t20;
    T20 credit;

    uint256 internal constant SIG_USER1_PK = 1;
    address internal sigUser1 = vm.addr(SIG_USER1_PK);
    address borrower = vm.addr(888);
    Spro.Proposal proposal;

    function setUp() public override {
        super.setUp();

        // Deploy tokens
        t20 = new T20();
        credit = new T20();

        proposal = ISproTypes.Proposal(
            address(t20),
            COLLATERAL_AMOUNT,
            address(credit),
            CREDIT_LIMIT,
            FIXED_INTEREST_AMOUNT,
            uint40(block.timestamp) + 5 days,
            uint40(block.timestamp) + 10 days,
            borrower,
            0,
            PARTIAL_POSITION_BPS
        );

        // Mint and approve SDEX
        deployment.sdex.mint(borrower, INITIAL_SDEX_BALANCE);
        deployment.sdex.mint(sigUser1, INITIAL_SDEX_BALANCE);
        credit.mint(sigUser1, CREDIT_LIMIT);
        vm.prank(sigUser1);
        credit.approve(address(deployment.permit2), type(uint256).max);
    }

    function test_permit2CreateLoan() public {
        IAllowanceTransfer.PermitDetails memory details =
            IAllowanceTransfer.PermitDetails(address(proposal.creditAddress), uint160(proposal.collateralAmount), 0, 0);
        IAllowanceTransfer.PermitSingle memory permitSign =
            IAllowanceTransfer.PermitSingle(details, address(deployment.config), block.timestamp);
        bytes memory signature = getPermitSignature(permitSign, SIG_USER1_PK, deployment.permit2.DOMAIN_SEPARATOR());

        _createERC20Proposal();

        // Lender: creates the loan
        vm.prank(sigUser1);
        deployment.config.createLoan(proposal, CREDIT_LIMIT, abi.encode(permitSign, signature));
    }

    function test_RevertWhen_permit2CreateLoan() public {
        IAllowanceTransfer.PermitDetails memory details =
            IAllowanceTransfer.PermitDetails(address(proposal.creditAddress), uint160(CREDIT_LIMIT - 1), 0, 0);
        IAllowanceTransfer.PermitSingle memory permitSign =
            IAllowanceTransfer.PermitSingle(details, address(deployment.config), block.timestamp);
        bytes memory signature = getPermitSignature(permitSign, SIG_USER1_PK, deployment.permit2.DOMAIN_SEPARATOR());

        _createERC20Proposal();

        vm.expectRevert(abi.encodeWithSelector(IAllowanceTransfer.InsufficientAllowance.selector, CREDIT_LIMIT - 1));
        // Lender: creates the loan
        vm.prank(sigUser1);
        deployment.config.createLoan(proposal, CREDIT_LIMIT, abi.encode(permitSign, signature));
    }

    function test_permit2CreateProposal() public {
        proposal.proposer = sigUser1;
        vm.startPrank(sigUser1);
        IERC20(proposal.collateralAddress).approve(address(deployment.permit2), type(uint256).max);
        deployment.sdex.approve(address(deployment.permit2), type(uint256).max);
        IAllowanceTransfer.PermitDetails[] memory details = new IAllowanceTransfer.PermitDetails[](2);
        details[0] = IAllowanceTransfer.PermitDetails(
            address(proposal.collateralAddress), uint160(COLLATERAL_AMOUNT), uint48(block.timestamp), 0
        );
        details[1] = IAllowanceTransfer.PermitDetails(
            address(deployment.sdex), uint160(deployment.config._fee()), uint48(block.timestamp), 0
        );
        IAllowanceTransfer.PermitBatch memory permitBatch =
            IAllowanceTransfer.PermitBatch(details, address(deployment.config), block.timestamp);
        bytes memory signature =
            getPermitBatchSignature(permitBatch, SIG_USER1_PK, deployment.permit2.DOMAIN_SEPARATOR());

        t20.mint(sigUser1, proposal.collateralAmount);

        deployment.config.createProposal(proposal, abi.encode(permitBatch, signature));
        vm.stopPrank();
    }

    function test_RevertWhen_permit2CreateProposal() public {
        proposal.proposer = sigUser1;
        vm.startPrank(sigUser1);
        IERC20(proposal.collateralAddress).approve(address(deployment.permit2), type(uint256).max);
        deployment.sdex.approve(address(deployment.permit2), type(uint256).max);
        IAllowanceTransfer.PermitDetails[] memory details = new IAllowanceTransfer.PermitDetails[](2);
        details[0] = IAllowanceTransfer.PermitDetails(
            address(proposal.collateralAddress), uint160(COLLATERAL_AMOUNT - 1), uint48(block.timestamp), 0
        );
        details[1] = IAllowanceTransfer.PermitDetails(
            address(deployment.sdex), uint160(deployment.config._fee()), uint48(block.timestamp), 0
        );
        IAllowanceTransfer.PermitBatch memory permitBatch =
            IAllowanceTransfer.PermitBatch(details, address(deployment.config), block.timestamp);
        bytes memory signature =
            getPermitBatchSignature(permitBatch, SIG_USER1_PK, deployment.permit2.DOMAIN_SEPARATOR());

        t20.mint(sigUser1, proposal.collateralAmount);

        vm.expectRevert(
            abi.encodeWithSelector(IAllowanceTransfer.InsufficientAllowance.selector, COLLATERAL_AMOUNT - 1)
        );
        deployment.config.createProposal(proposal, abi.encode(permitBatch, signature));
        vm.stopPrank();
    }

    function test_permit2RepayLoan() public {
        // Borrower: creates proposal
        _createERC20Proposal();

        // Mint initial state & approve credit
        credit.mint(sigUser1, CREDIT_LIMIT);
        vm.prank(sigUser1);
        credit.approve(address(deployment.config), CREDIT_LIMIT);

        // Lender: creates the loan
        vm.prank(sigUser1);
        uint256 loanId = deployment.config.createLoan(proposal, CREDIT_AMOUNT, "");

        // Borrower: cancels proposal, withdrawing unused collateral
        vm.prank(borrower);
        deployment.config.cancelProposal(proposal);

        // Warp ahead, just before loan default
        vm.warp(proposal.loanExpiration - proposal.startTimestamp - 1);

        ISproTypes.Loan memory loan = deployment.config.getLoan(loanId);
        uint256 repaymentAmount = loan.principalAmount + loan.fixedInterestAmount;
        IAllowanceTransfer.PermitDetails memory details =
            IAllowanceTransfer.PermitDetails(address(proposal.creditAddress), uint160(repaymentAmount), 0, 0);
        IAllowanceTransfer.PermitSingle memory permitSign =
            IAllowanceTransfer.PermitSingle(details, address(deployment.config), block.timestamp);
        bytes memory signature = getPermitSignature(permitSign, SIG_USER1_PK, deployment.permit2.DOMAIN_SEPARATOR());

        vm.prank(sigUser1);
        deployment.config.repayLoan(loanId, abi.encode(permitSign, signature));
    }

    function test_RevertWhen_Permit2RepayLoan() public {
        // Borrower: creates proposal
        _createERC20Proposal();

        // Mint initial state & approve credit
        credit.mint(sigUser1, CREDIT_LIMIT);
        vm.prank(sigUser1);
        credit.approve(address(deployment.config), CREDIT_LIMIT);

        // Lender: creates the loan
        vm.prank(sigUser1);
        uint256 loanId = deployment.config.createLoan(proposal, CREDIT_AMOUNT, "");

        // Borrower: cancels proposal, withdrawing unused collateral
        vm.prank(borrower);
        deployment.config.cancelProposal(proposal);

        // Warp ahead, just before loan default
        vm.warp(proposal.loanExpiration - proposal.startTimestamp - 1);

        ISproTypes.Loan memory loan = deployment.config.getLoan(loanId);
        uint256 repaymentAmount = loan.principalAmount + loan.fixedInterestAmount;
        IAllowanceTransfer.PermitDetails memory details =
            IAllowanceTransfer.PermitDetails(address(proposal.creditAddress), uint160(repaymentAmount - 1), 0, 0);
        IAllowanceTransfer.PermitSingle memory permitSign =
            IAllowanceTransfer.PermitSingle(details, address(deployment.config), block.timestamp);
        bytes memory signature = getPermitSignature(permitSign, SIG_USER1_PK, deployment.permit2.DOMAIN_SEPARATOR());

        vm.expectRevert(abi.encodeWithSelector(IAllowanceTransfer.InsufficientAllowance.selector, repaymentAmount - 1));
        vm.prank(sigUser1);
        deployment.config.repayLoan(loanId, abi.encode(permitSign, signature));
    }

    function test_permit2RepayMultipleLoans() public {
        // Borrower: creates proposal
        _createERC20Proposal();

        // Mint initial state & approve credit
        credit.mint(sigUser1, CREDIT_LIMIT);
        vm.prank(sigUser1);
        credit.approve(address(deployment.config), CREDIT_LIMIT);

        // Lender: creates the loan
        vm.startPrank(sigUser1);
        // Setup loanIds array
        uint256[] memory loanIds = new uint256[](3);
        loanIds[0] = deployment.config.createLoan(proposal, CREDIT_AMOUNT / 3, "");
        loanIds[1] = deployment.config.createLoan(proposal, CREDIT_AMOUNT / 3, "");
        loanIds[2] = deployment.config.createLoan(proposal, CREDIT_AMOUNT / 3, "");
        vm.stopPrank();

        // Borrower: cancels proposal, withdrawing unused collateral
        vm.prank(borrower);
        deployment.config.cancelProposal(proposal);

        // Warp ahead, just before loan default
        vm.warp(proposal.loanExpiration - proposal.startTimestamp - 1);

        uint256 totalRepaymentAmount;
        ISproTypes.Loan memory loan = deployment.config.getLoan(loanIds[0]);
        totalRepaymentAmount += loan.principalAmount + loan.fixedInterestAmount;
        loan = deployment.config.getLoan(loanIds[1]);
        totalRepaymentAmount += loan.principalAmount + loan.fixedInterestAmount;
        loan = deployment.config.getLoan(loanIds[2]);
        totalRepaymentAmount += loan.principalAmount + loan.fixedInterestAmount;
        IAllowanceTransfer.PermitDetails memory details =
            IAllowanceTransfer.PermitDetails(address(proposal.creditAddress), uint160(totalRepaymentAmount), 0, 0);
        IAllowanceTransfer.PermitSingle memory permitSign =
            IAllowanceTransfer.PermitSingle(details, address(deployment.config), block.timestamp);
        bytes memory signature = getPermitSignature(permitSign, SIG_USER1_PK, deployment.permit2.DOMAIN_SEPARATOR());

        vm.prank(sigUser1);
        deployment.config.repayMultipleLoans(loanIds, abi.encode(permitSign, signature));
    }

    function test_RevertWhen_WrongSignPermit2RepayMultipleLoans() public {
        // Borrower: creates proposal
        _createERC20Proposal();

        // Mint initial state & approve credit
        credit.mint(sigUser1, CREDIT_LIMIT);
        vm.prank(sigUser1);
        credit.approve(address(deployment.config), CREDIT_LIMIT);

        // Lender: creates the loan
        vm.startPrank(sigUser1);
        // Setup loanIds array
        uint256[] memory loanIds = new uint256[](3);
        loanIds[0] = deployment.config.createLoan(proposal, CREDIT_AMOUNT / 3, "");
        loanIds[1] = deployment.config.createLoan(proposal, CREDIT_AMOUNT / 3, "");
        loanIds[2] = deployment.config.createLoan(proposal, CREDIT_AMOUNT / 3, "");
        vm.stopPrank();

        // Borrower: cancels proposal, withdrawing unused collateral
        vm.prank(borrower);
        deployment.config.cancelProposal(proposal);

        // Warp ahead, just before loan default
        vm.warp(proposal.loanExpiration - proposal.startTimestamp - 1);

        uint256 totalRepaymentAmount;
        ISproTypes.Loan memory loan = deployment.config.getLoan(loanIds[0]);
        totalRepaymentAmount += loan.principalAmount + loan.fixedInterestAmount;
        loan = deployment.config.getLoan(loanIds[1]);
        totalRepaymentAmount += loan.principalAmount + loan.fixedInterestAmount;
        loan = deployment.config.getLoan(loanIds[2]);
        totalRepaymentAmount += loan.principalAmount + loan.fixedInterestAmount;
        IAllowanceTransfer.PermitDetails memory details =
            IAllowanceTransfer.PermitDetails(address(proposal.creditAddress), uint160(totalRepaymentAmount - 1), 0, 0);
        IAllowanceTransfer.PermitSingle memory permitSign =
            IAllowanceTransfer.PermitSingle(details, address(deployment.config), block.timestamp);
        bytes memory signature = getPermitSignature(permitSign, SIG_USER1_PK, deployment.permit2.DOMAIN_SEPARATOR());

        vm.expectRevert(
            abi.encodeWithSelector(IAllowanceTransfer.InsufficientAllowance.selector, totalRepaymentAmount - 1)
        );
        vm.prank(sigUser1);
        deployment.config.repayMultipleLoans(loanIds, abi.encode(permitSign, signature));
    }

    // Make the proposal
    function _createERC20Proposal() internal {
        // Mint initial state & approve collateral
        t20.mint(borrower, proposal.collateralAmount);
        vm.startPrank(borrower);
        deployment.sdex.approve(address(deployment.config), type(uint256).max);
        t20.approve(address(deployment.config), proposal.collateralAmount);
        deployment.config.createProposal(proposal, "");
        vm.stopPrank();
    }
}
