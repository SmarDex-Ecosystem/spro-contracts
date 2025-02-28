// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { SigUtils } from "test/utils/SigUtils.sol";
import { CreditPermit } from "test/helper/CreditPermit.sol";
import { DummyPoolAdapter } from "test/helper/DummyPoolAdapter.sol";
import { T20 } from "test/helper/T20.sol";
import { SDDeploymentTest, Spro } from "test/integration/SDDeploymentTest.t.sol";

import { ISproTypes } from "src/interfaces/ISproTypes.sol";

abstract contract SDBaseIntegrationTest is SDDeploymentTest {
    T20 t20;
    T20 credit;

    uint256 lenderPK = uint256(777);
    address lender = vm.addr(lenderPK);
    uint256 borrowerPK = uint256(888);
    address borrower = vm.addr(borrowerPK);
    Spro.Proposal proposal;
    Spro.Permit permit;

    // Additional lenders
    address alice;
    uint256 aliceKey;
    address bob;
    address charlee;

    // permit
    CreditPermit creditPermit;
    SigUtils sigUtils;

    // pool adapter
    DummyPoolAdapter poolAdapter;

    // Constants
    uint256 public constant COLLATERAL_ID = 42;
    uint256 public constant COLLATERAL_AMOUNT = 10_000e18;
    uint256 public constant INITIAL_CREDIT_BALANCE = 1000e18;
    uint256 public constant CREDIT_AMOUNT = 60e18;
    uint256 public constant CREDIT_LIMIT = 100e18;
    uint256 public constant FIXED_INTEREST_AMOUNT = 5e18;

    uint256 public constant SLOT_PROPOSALS_MADE = 0;
    uint256 public constant SLOT_CREDIT_USED = 1;
    uint256 public constant SLOT_WITHDRAWABLE_COLLATERAL = 2;

    uint256 public constant INITIAL_SDEX_BALANCE = 1_000_000e18;

    uint16 public constant DEFAULT_THRESHOLD = 500;
    uint16 public constant PERCENTAGE = 1e4;

    function setUp() public virtual override {
        super.setUp();

        // Deploy tokens
        t20 = new T20();
        credit = new T20();

        // Permit
        creditPermit = new CreditPermit();
        sigUtils = new SigUtils(creditPermit.DOMAIN_SEPARATOR());

        // Pool adapter
        poolAdapter = new DummyPoolAdapter();
        vm.label(address(poolAdapter), "poolAdapter");

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
            address(deployment.config)
        );

        // Mint and approve SDEX
        deployment.sdex.mint(lender, INITIAL_SDEX_BALANCE);
        vm.prank(lender);
        deployment.sdex.approve(address(deployment.config), type(uint256).max);
        deployment.sdex.mint(borrower, INITIAL_SDEX_BALANCE);
        vm.prank(borrower);
        deployment.sdex.approve(address(deployment.config), type(uint256).max);

        // Set thresholds in config
        vm.startPrank(deployment.protocolAdmin);
        Spro(deployment.config).setPartialPositionPercentage(DEFAULT_THRESHOLD);
        vm.stopPrank();

        // Add labels
        vm.label(lender, "lender");
        vm.label(borrower, "borrower");
        vm.label(address(credit), "credit");
        vm.label(address(t20), "t20");

        // Setup & label new lender addresses
        (alice, aliceKey) = makeAddrAndKey("alice");
        vm.label(alice, "alice");
        bob = makeAddr("bob");
        vm.label(bob, "bob");
        charlee = makeAddr("charlee");
        vm.label(charlee, "charlee");
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

    function _createLoan(Spro.Proposal memory newProposal, bytes memory revertData) internal returns (uint256 loanId) {
        // Mint initial state & approve credit
        credit.mint(lender, INITIAL_CREDIT_BALANCE);
        vm.prank(lender);
        credit.approve(address(deployment.config), CREDIT_LIMIT);

        // Create Loan
        if (keccak256(revertData) != keccak256("")) {
            vm.expectRevert(revertData);
        }

        vm.prank(lender);
        return deployment.config.createLoan(newProposal, _buildLenderSpec(false), "");
    }

    function _cancelProposal(Spro.Proposal memory _proposal) internal {
        deployment.config.cancelProposal(_proposal);
    }

    function _buildLenderSpec(bool complete) internal view returns (ISproTypes.LenderSpec memory lenderSpec) {
        lenderSpec = complete
            ? ISproTypes.LenderSpec(lender, CREDIT_LIMIT, "")
            : ISproTypes.LenderSpec(lender, CREDIT_AMOUNT, "");
    }
}
