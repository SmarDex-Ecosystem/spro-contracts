// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import { Test } from "forge-std/Test.sol";

import { IAllowanceTransfer } from "permit2/src/interfaces/IAllowanceTransfer.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { T20 } from "test/helper/T20.sol";

import { ISproTypes } from "src/interfaces/ISproTypes.sol";
import { Spro } from "src/spro/Spro.sol";
import { SproLoan } from "src/spro/SproLoan.sol";

contract SDBaseIntegrationTest is Test {
    T20 collateral;
    T20 credit;

    address lender = vm.addr(777);
    address borrower = vm.addr(888);
    ISproTypes.Proposal proposal;

    // Additional lenders
    address alice;
    uint256 aliceKey;
    address bob;
    address charlie;

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

    Spro spro;
    SproLoan loanToken;
    T20 sdex;
    IAllowanceTransfer permit2;

    function _setUp(bool fork) public virtual {
        if (fork) {
            string memory url = vm.rpcUrl("mainnet");
            vm.createSelectFork(url);
            permit2 = IAllowanceTransfer(PERMIT2);
        } else {
            permit2 = IAllowanceTransfer(makeAddr("IAllowanceTransfer"));
        }
        sdex = new T20("SDEX", "SDEX");

        vm.prank(ADMIN);
        spro = new Spro(address(sdex), address(permit2), FEE, PARTIAL_POSITION_BPS, ADMIN);

        loanToken = spro._loanToken();

        // Deploy tokens
        collateral = new T20("collateral", "collateral");
        credit = new T20("credit", "credit");

        proposal = ISproTypes.Proposal(
            address(collateral),
            COLLATERAL_AMOUNT,
            address(credit),
            CREDIT_LIMIT,
            FIXED_INTEREST_AMOUNT,
            uint40(block.timestamp) + 5 days,
            uint40(block.timestamp) + 10 days,
            borrower,
            0,
            Math.mulDiv(CREDIT_LIMIT, PARTIAL_POSITION_BPS, spro.BPS_DIVISOR())
        );

        // Mint and approve SDEX
        sdex.mint(lender, INITIAL_SDEX_BALANCE);
        vm.prank(lender);
        sdex.approve(address(spro), type(uint256).max);
        sdex.mint(borrower, INITIAL_SDEX_BALANCE);
        vm.prank(borrower);
        sdex.approve(address(spro), type(uint256).max);

        // Setup lender addresses
        (alice, aliceKey) = makeAddrAndKey("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");
    }

    function _createERC20Proposal() internal {
        collateral.mint(borrower, proposal.collateralAmount);

        vm.prank(borrower);
        collateral.approve(address(spro), proposal.collateralAmount);
        vm.prank(borrower);
        spro.createProposal(
            proposal.collateralAddress,
            proposal.collateralAmount,
            proposal.creditAddress,
            proposal.availableCreditLimit,
            proposal.fixedInterestAmount,
            proposal.startTimestamp,
            proposal.loanExpiration,
            ""
        );
    }

    function _createLoan(ISproTypes.Proposal memory newProposal, uint256 amount, bytes memory revertData)
        internal
        returns (uint256 loanId)
    {
        // Mint initial state & approve credit
        credit.mint(lender, INITIAL_CREDIT_BALANCE);
        vm.prank(lender);
        credit.approve(address(spro), CREDIT_LIMIT);

        // Create Loan
        if (keccak256(revertData) != keccak256("")) {
            vm.expectRevert(revertData);
        }

        vm.prank(lender);
        return spro.createLoan(newProposal, amount, "");
    }
}
