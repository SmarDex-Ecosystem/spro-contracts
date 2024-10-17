// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IAllowanceTransfer } from "permit2/src/interfaces/IAllowanceTransfer.sol";

import { SproForkBase } from "test/integration/utils/Fixtures.sol";
import { T20 } from "test/helper/T20.sol";
import { Spro } from "test/integration/SDDeploymentTest.t.sol";

import { ISproTypes } from "src/interfaces/ISproTypes.sol";

contract TestForPermit2 is SproForkBase {
    uint256 public constant COLLATERAL_AMOUNT = 10_000e18;
    uint256 public constant CREDIT_AMOUNT = 60e18;
    uint256 public constant FIXED_INTEREST_AMOUNT = 5e18;
    uint256 public constant CREDIT_LIMIT = 100e18;
    uint256 public constant INITIAL_SDEX_BALANCE = 1_000_000e18;

    T20 t20;
    T20 credit;

    uint256 internal constant SIG_USER1_PK = 1;
    address internal sigUser1 = vm.addr(SIG_USER1_PK);
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
        deployment.sdex.mint(borrower, INITIAL_SDEX_BALANCE);
        deployment.sdex.mint(sigUser1, INITIAL_SDEX_BALANCE);
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
        Spro.LenderSpec memory lenderSpec = ISproTypes.LenderSpec(sigUser1, CREDIT_LIMIT, "");

        // Lender: creates the loan
        vm.prank(sigUser1);
        deployment.config.createLoan(proposal, lenderSpec, "", abi.encode(permitBatch, signature));
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
            address(deployment.sdex), uint160(deployment.config.fixFeeUnlisted()), uint48(block.timestamp), 0
        );
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
        credit.mint(sigUser1, CREDIT_LIMIT);
        vm.prank(sigUser1);
        credit.approve(address(deployment.config), CREDIT_LIMIT);

        // Lender: creates the loan
        vm.prank(sigUser1);
        uint256 loanId =
            deployment.config.createLoan(proposal, ISproTypes.LenderSpec(sigUser1, CREDIT_AMOUNT, ""), "", "");

        // Borrower: cancels proposal, withdrawing unused collateral
        vm.prank(borrower);
        deployment.config.cancelProposal(proposal);

        // Warp ahead, just before loan default
        vm.warp(proposal.loanExpiration - proposal.startTimestamp - 1);

        uint256 repaymentAmount = deployment.config.loanRepaymentAmount(loanId);
        IAllowanceTransfer.PermitDetails[] memory details = new IAllowanceTransfer.PermitDetails[](1);
        details[0] = IAllowanceTransfer.PermitDetails(address(proposal.creditAddress), uint160(repaymentAmount), 0, 0);
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
        vm.startPrank(borrower);
        deployment.sdex.approve(address(deployment.config), type(uint256).max);
        t20.approve(address(deployment.config), proposal.collateralAmount);
        deployment.config.createProposal(proposal, "");
        vm.stopPrank();
    }
}
