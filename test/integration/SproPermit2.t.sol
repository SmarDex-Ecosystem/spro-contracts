// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IAllowanceTransfer } from "permit2/src/interfaces/IAllowanceTransfer.sol";

import { SproForkBase } from "test/integration/utils/Fixtures.sol";
import { T20 } from "test/helper/T20.sol";
import { Spro } from "test/integration/SDDeploymentTest.t.sol";

import { ISproTypes } from "src/interfaces/ISproTypes.sol";

contract SDSimpleLoanIntegrationTest is SproForkBase {
    uint256 public constant COLLATERAL_AMOUNT = 10_000e18;
    uint256 public constant CREDIT_AMOUNT = 60e18;
    uint256 public constant FIXED_INTEREST_AMOUNT = 5e18;
    uint256 public constant CREDIT_LIMIT = 100e18;
    uint256 public constant INITIAL_SDEX_BALANCE = 1_000_000e18;

    uint256 internal constant SIG_USER1_PK = 1;
    address internal sigUser1 = vm.addr(SIG_USER1_PK);

    T20 t20;
    T20 credit;

    uint256 lenderPK = uint256(777);
    address lender = vm.addr(lenderPK);
    uint256 borrowerPK = uint256(888);
    address borrower = vm.addr(borrowerPK);
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
            0,
            uint40(block.timestamp) + 5 days,
            uint40(block.timestamp) + 10 days,
            borrower,
            keccak256(abi.encode(borrower)),
            0,
            0,
            address(deployment.config)
        );

        // Mint and approve SDEX
        deployment.sdex.mint(lender, INITIAL_SDEX_BALANCE);
        vm.prank(lender);
        deployment.sdex.approve(address(deployment.config), type(uint256).max);
        deployment.sdex.mint(borrower, INITIAL_SDEX_BALANCE);
        vm.prank(borrower);
        deployment.sdex.approve(address(deployment.config), type(uint256).max);

        credit.mint(sigUser1, CREDIT_LIMIT);
        vm.prank(sigUser1);
        credit.approve(address(deployment.permit2), type(uint256).max);
    }

    function test_permit2CreateLoan() public {
        IAllowanceTransfer.PermitDetails[] memory details = new IAllowanceTransfer.PermitDetails[](1);
        details[0] =
            IAllowanceTransfer.PermitDetails(address(proposal.creditAddress), uint160(proposal.collateralAmount), 0, 0);
        IAllowanceTransfer.PermitBatch memory permitBatch =
            IAllowanceTransfer.PermitBatch(details, address(deployment.config), block.timestamp);
        bytes memory signature =
            getPermitBatchSignature(permitBatch, SIG_USER1_PK, deployment.permit2.DOMAIN_SEPARATOR());

        _createERC20Proposal();
        Spro.LenderSpec memory lenderSpec = _buildLenderSpec(true);

        // Lender: creates the loan
        vm.prank(sigUser1);
        deployment.config.createLoan(proposal, lenderSpec, "", abi.encode(permitBatch, signature));
    }

    function test_permit2CreateProposal() public {
        proposal.proposer = sigUser1;
        vm.startPrank(sigUser1);
        deployment.sdex.approve(address(deployment.permit2), type(uint256).max);
        IAllowanceTransfer.PermitDetails[] memory details = new IAllowanceTransfer.PermitDetails[](2);
        details[0] =
            IAllowanceTransfer.PermitDetails(address(proposal.collateralAddress), uint160(COLLATERAL_AMOUNT), 0, 0);
        details[1] = IAllowanceTransfer.PermitDetails(address(deployment.sdex), uint160(UNLISTED_FEE), 0, 0);
        IAllowanceTransfer.PermitBatch memory permitBatch =
            IAllowanceTransfer.PermitBatch(details, address(deployment.config), block.timestamp);
        bytes memory signature =
            getPermitBatchSignature(permitBatch, SIG_USER1_PK, deployment.permit2.DOMAIN_SEPARATOR());

        t20.mint(sigUser1, proposal.collateralAmount);

        deployment.config.createProposal(proposal, abi.encode(permitBatch, signature));
        vm.stopPrank();
    }

    function test_permit2RepayLoan() public {
        // Borrower: creates proposal
        _createERC20Proposal();

        // Mint initial state & approve credit
        credit.mint(lender, CREDIT_LIMIT);
        vm.prank(lender);
        credit.approve(address(deployment.config), CREDIT_LIMIT);

        // Lender: creates the loan
        vm.prank(lender);
        uint256 loanId = deployment.config.createLoan(proposal, _buildLenderSpec(false), "", "");

        // Borrower: cancels proposal, withdrawing unused collateral
        vm.prank(borrower);
        deployment.config.cancelProposal(proposal);

        // Warp ahead, just before loan default
        vm.warp(proposal.loanExpiration - proposal.startTimestamp - 1);

        uint256 repaymentAmount = deployment.config.loanRepaymentAmount(loanId);
        deployment.sdex.approve(address(deployment.permit2), type(uint256).max);
        IAllowanceTransfer.PermitDetails[] memory details = new IAllowanceTransfer.PermitDetails[](2);
        details[0] = IAllowanceTransfer.PermitDetails(address(proposal.creditAddress), uint160(repaymentAmount), 0, 0);
        details[1] = IAllowanceTransfer.PermitDetails(address(deployment.sdex), uint160(UNLISTED_FEE), 0, 0);
        IAllowanceTransfer.PermitBatch memory permitBatch =
            IAllowanceTransfer.PermitBatch(details, address(deployment.config), block.timestamp);
        bytes memory signature =
            getPermitBatchSignature(permitBatch, SIG_USER1_PK, deployment.permit2.DOMAIN_SEPARATOR());

        vm.prank(sigUser1);
        deployment.config.repayLoan(loanId, abi.encode(permitBatch, signature));
    }

    // Make the proposal
    function _createERC20Proposal() internal {
        // Mint initial state & approve collateral
        t20.mint(borrower, proposal.collateralAmount);
        vm.prank(borrower);
        t20.approve(address(deployment.config), proposal.collateralAmount);

        vm.prank(borrower);
        deployment.config.createProposal(proposal, "");
    }

    function _buildLenderSpec(bool complete) internal view returns (ISproTypes.LenderSpec memory lenderSpec) {
        lenderSpec = complete
            ? ISproTypes.LenderSpec(lender, CREDIT_LIMIT, "")
            : ISproTypes.LenderSpec(lender, CREDIT_AMOUNT, "");
    }
}
