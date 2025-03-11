// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import { Test } from "forge-std/Test.sol";

import { IAllowanceTransfer } from "permit2/src/interfaces/IAllowanceTransfer.sol";

import { T20 } from "test/helper/T20.sol";

import { ISproTypes } from "src/interfaces/ISproTypes.sol";
import { Spro } from "src/spro/Spro.sol";
import { SproLoan } from "src/spro/SproLoan.sol";

contract SDBaseIntegrationTest is Test {
    T20 t20;
    T20 credit;

    address lender = vm.addr(777);
    address borrower = vm.addr(888);
    ISproTypes.Proposal proposal;

    // Additional lenders
    address alice;
    uint256 aliceKey;
    address bob;
    address charlee;

    // Constants
    uint256 public constant COLLATERAL_AMOUNT = 10_000e18;
    uint256 public constant INITIAL_CREDIT_BALANCE = 1000e18;
    uint256 public constant CREDIT_AMOUNT = 60e18;
    uint256 public constant CREDIT_LIMIT = 100e18;
    uint256 public constant FIXED_INTEREST_AMOUNT = 5e18;
    uint256 public constant INITIAL_SDEX_BALANCE = 1_000_000e18;
    address payable constant PERMIT2 = payable(address(0x000000000022D473030F116dDEE9F6B43aC78BA3));
    address public constant ADMIN = address(0x1212121212121212121212121212121212121212);
    uint256 public constant FEE = 20e18;
    uint16 public constant PARTIAL_POSITION_BPS = 500;

    Deployment deployment;

    struct Deployment {
        Spro config;
        SproLoan loanToken;
        T20 sdex;
        IAllowanceTransfer permit2;
    }

    function _setUp(bool fork) public virtual {
        if (fork) {
            string memory url = vm.rpcUrl("mainnet");
            vm.createSelectFork(url);
            deployment.permit2 = IAllowanceTransfer(PERMIT2);
        } else {
            deployment.permit2 = IAllowanceTransfer(makeAddr("IAllowanceTransfer"));
        }
        deployment.sdex = new T20();

        vm.startPrank(ADMIN);
        deployment.config = new Spro(address(deployment.sdex), address(deployment.permit2), FEE, PARTIAL_POSITION_BPS);
        vm.stopPrank();

        deployment.loanToken = deployment.config._loanToken();

        // Deploy tokens
        t20 = new T20();
        credit = new T20();

        // Deploy protocol contracts
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
        deployment.sdex.mint(lender, INITIAL_SDEX_BALANCE);
        vm.prank(lender);
        deployment.sdex.approve(address(deployment.config), type(uint256).max);
        deployment.sdex.mint(borrower, INITIAL_SDEX_BALANCE);
        vm.prank(borrower);
        deployment.sdex.approve(address(deployment.config), type(uint256).max);

        // Set thresholds in config
        vm.startPrank(ADMIN);
        Spro(deployment.config).setPartialPositionPercentage(PARTIAL_POSITION_BPS);
        vm.stopPrank();

        // Setup lender addresses
        (alice, aliceKey) = makeAddrAndKey("alice");
        bob = makeAddr("bob");
        charlee = makeAddr("charlee");
    }

    function _createERC20Proposal() internal {
        // Mint initial state & approve collateral
        t20.mint(borrower, proposal.collateralAmount);

        vm.prank(borrower);
        t20.approve(address(deployment.config), proposal.collateralAmount);
        vm.prank(borrower);
        deployment.config.createProposal(proposal, "");
    }

    function _createLoan(ISproTypes.Proposal memory newProposal, bytes memory revertData)
        internal
        returns (uint256 loanId)
    {
        // Mint initial state & approve credit
        credit.mint(lender, INITIAL_CREDIT_BALANCE);
        vm.prank(lender);
        credit.approve(address(deployment.config), CREDIT_LIMIT);

        // Create Loan
        if (keccak256(revertData) != keccak256("")) {
            vm.expectRevert(revertData);
        }

        vm.prank(lender);
        return deployment.config.createLoan(newProposal, CREDIT_AMOUNT, "");
    }
}
