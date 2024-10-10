// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import {
    SDBaseIntegrationTest, Spro, IPWNDeployer, SproRevokedNonce
} from "test/integration/SDBaseIntegrationTest.t.sol";
import { SigUtils } from "test/utils/SigUtils.sol";
import { IPoolAdapter } from "test/helper/DummyPoolAdapter.sol";

import { ISproTypes } from "src/interfaces/ISproTypes.sol";
import { ISproErrors } from "src/interfaces/ISproErrors.sol";
import { SproConstantsLibrary as Constants } from "src/libraries/SproConstantsLibrary.sol";

contract SDSimpleLoanIntegrationTest is SDBaseIntegrationTest {
    function test_shouldCreateERC20Proposal_shouldCreatePartialLoan_shouldWithdrawRemainingCollateral() external {
        // Create the proposal
        vm.prank(borrower);
        bytes memory proposalSpec = _createERC20Proposal();

        // Create the loan
        vm.prank(lender);
        uint256 loanId = _createLoan(proposalSpec, "");

        // Borrower withdraws remaining collateral
        vm.startPrank(borrower);
        deployment.config.revokeNonce(proposal.nonceSpace, proposal.nonce);
        _cancelProposal(proposal);
        vm.stopPrank();

        // ASSERTIONS
        // loan token
        assertEq(deployment.loanToken.ownerOf(loanId), lender, "0: loanToken owner should be lender");
        // credit token
        assertEq(
            credit.balanceOf(lender),
            INITIAL_CREDIT_BALANCE - CREDIT_AMOUNT,
            "1: initial credit token balance reduced by credit amount"
        );
        assertEq(
            credit.balanceOf(borrower), CREDIT_AMOUNT, "2: credit token balance of borrower should be CREDIT_AMOUNT"
        );
        assertEq(
            credit.balanceOf(address(deployment.config)), 0, "3: credit token balance of loan contract should be 0"
        );
        // collateral token
        assertEq(t20.balanceOf(lender), 0, "4: ERC20 collateral token balance of lender should be 0");
        assertEq(
            t20.balanceOf(borrower),
            COLLATERAL_AMOUNT - (CREDIT_AMOUNT * COLLATERAL_AMOUNT) / CREDIT_LIMIT,
            "5: ERC20 collateral token balance of borrower should be unused collateral"
        );
        assertEq(
            t20.balanceOf(address(deployment.config)),
            (CREDIT_AMOUNT * COLLATERAL_AMOUNT) / CREDIT_LIMIT,
            "6: ERC20 collateral token balance of loan contract should be used collateral"
        );
        // nonce
        assertEq(
            deployment.revokedNonce.isNonceUsable(borrower, proposal.nonceSpace, proposal.nonce),
            false,
            "7: nonce for borrower should not be usable"
        );
        // loan id
        // assertEq(
        //     deployment.loanToken.loanContract(loanId),
        //     address(deployment.config),
        //     "8: loan contract should be mapped to loanId"
        // );
        // sdex fees
        assertEq(
            deployment.sdex.balanceOf(address(Constants.SINK)),
            deployment.config.fixFeeUnlisted(),
            "9: sink should contain the sdex unlisted fee"
        );
    }

    function test_PartialLoan_ERC20Collateral_CancelProposal_RepayLoan() external {
        // Borrower: creates proposal
        bytes memory proposalSpec = _createERC20Proposal();

        // Mint initial state & approve credit
        credit.mint(lender, INITIAL_CREDIT_BALANCE);
        vm.prank(lender);
        credit.approve(address(deployment.config), CREDIT_LIMIT);

        // Lender: creates the loan
        vm.prank(lender);
        uint256 loanId =
            deployment.config.createLOAN({ proposalData: proposalSpec, lenderSpec: _buildLenderSpec(false), extra: "" });

        // Borrower: cancels proposal, withdrawing unused collateral
        vm.startPrank(borrower);
        deployment.config.cancelProposal(proposalSpec);

        // Warp ahead, just before loan default
        vm.warp(proposal.defaultTimestamp - proposal.startTimestamp - 1);

        // Borrower approvals for credit token
        credit.mint(borrower, FIXED_INTEREST_AMOUNT); // helper step: mint fixed interest amount for the borrower
        credit.approve(address(deployment.config), CREDIT_AMOUNT + FIXED_INTEREST_AMOUNT);

        // Borrower: repays loan
        deployment.config.repayLOAN(loanId, "");

        // Assertions
        assertEq(credit.balanceOf(borrower), 0);
        assertEq(credit.balanceOf(lender), INITIAL_CREDIT_BALANCE + FIXED_INTEREST_AMOUNT);

        assertEq(t20.balanceOf(borrower), COLLATERAL_AMOUNT);
    }

    function test_PartialLoan_GtCreditThreshold() external {
        // Create the proposal
        vm.prank(borrower);
        bytes memory proposalSpec = _createERC20Proposal();

        // 97% of available credit limit
        uint256 amount = 9700 * CREDIT_LIMIT / 1e4;

        // Mint initial state & approve credit
        credit.mint(lender, INITIAL_CREDIT_BALANCE);
        vm.startPrank(lender);
        credit.approve(address(deployment.config), CREDIT_LIMIT);

        ISproTypes.LenderSpec memory lenderSpec =
            ISproTypes.LenderSpec({ sourceOfFunds: lender, creditAmount: amount, permitData: "" });

        // Create loan, expecting revert
        vm.expectRevert(
            abi.encodeWithSelector(
                ISproErrors.CreditAmountLeavesTooLittle.selector,
                amount,
                (PERCENTAGE - DEFAULT_THRESHOLD) * CREDIT_LIMIT / 1e4
            )
        );
        deployment.config.createLOAN({ proposalData: proposalSpec, lenderSpec: lenderSpec, extra: "" });
        vm.stopPrank();
    }

    function test_RevertWhen_CreateAlreadyMadeProposal() external {
        // Create the proposal
        _createERC20Proposal();
        // Mint initial state & approve collateral
        t20.mint(borrower, proposal.collateralAmount);
        vm.prank(borrower);
        t20.approve(address(deployment.config), proposal.collateralAmount);

        // Create the proposal
        bytes memory proposalSpec = abi.encode(proposal);

        vm.expectRevert(ISproErrors.ProposalAlreadyExists.selector);
        vm.prank(borrower);
        deployment.config.createProposal(proposalSpec);
    }

    function test_shouldFail_getProposalCreditStatus_ProposalNotMade() external {
        vm.expectRevert(ISproErrors.ProposalNotMade.selector);
        deployment.config.getProposalCreditStatus(proposal);
    }

    function testFuzz_GetProposalCreditStatus(uint256 limit, uint256 used) external {
        vm.assume(limit != 0);
        vm.assume(used <= limit);

        proposal.availableCreditLimit = limit;
        _createERC20Proposal();

        bytes32 proposalHash = deployment.config.getProposalHash(proposal);

        vm.store(address(deployment.config), keccak256(abi.encode(proposalHash, 0)), bytes32(uint256(1)));
        vm.store(address(deployment.config), keccak256(abi.encode(proposalHash, 1)), bytes32(used));

        (uint256 r, uint256 u) = deployment.config.getProposalCreditStatus(proposal);

        assertEq(r, limit - u);
    }

    function testGas_MultiplePartialLoans_Original() external {
        uint256[] memory loanIds = _setupMultipleRepay();
        vm.startPrank(borrower);
        uint256 startGas = gasleft();
        for (uint256 i; i < 4; ++i) {
            deployment.config.repayLOAN(loanIds[i], "");
        }
        emit log_named_uint("repayLOAN with for loop", startGas - gasleft());
    }

    function testGas_MultiplePartialLoans_RepayMultiple() external {
        uint256[] memory loanIds = _setupMultipleRepay();
        vm.startPrank(borrower);
        uint256 startGas = gasleft();
        deployment.config.repayMultipleLOANs(loanIds, address(credit), "");
        emit log_named_uint("Gas used", startGas - gasleft());
    }

    function test_MultiplePartialLoans_RepayMultiple() external {
        uint256[] memory loanIds = _setupMultipleRepay();

        vm.startPrank(borrower);
        deployment.config.repayMultipleLOANs(loanIds, address(credit), "");

        // Assertions
        assertEq(credit.balanceOf(borrower), 0);
        require(
            credit.balanceOf(lender) == credit.balanceOf(alice) && credit.balanceOf(lender) == credit.balanceOf(bob)
                && credit.balanceOf(lender) == credit.balanceOf(charlee)
        );
        assertEq(credit.balanceOf(lender), INITIAL_CREDIT_BALANCE + FIXED_INTEREST_AMOUNT);

        assertEq(0, deployment.loanToken.balanceOf(lender));
        assertEq(0, deployment.loanToken.balanceOf(alice));
        assertEq(0, deployment.loanToken.balanceOf(bob));
        assertEq(0, deployment.loanToken.balanceOf(charlee));

        assertEq(2000 * COLLATERAL_AMOUNT / 1e4, t20.balanceOf(borrower)); // 20% since 4 loans @ 5% minimum amount
        assertEq(8000 * COLLATERAL_AMOUNT / 1e4, t20.balanceOf(address(deployment.config)));
    }

    function test_MultiplePartialLoans_RepayMultiple_PermitCreditTokens() external {
        uint256[] memory loanIds = _setupMultipleRepayCreditPermit();

        permit.asset = address(creditPermit);
        permit.owner = borrower;
        permit.amount = deployment.config.totalLoanRepaymentAmount(loanIds, address(creditPermit));
        permit.deadline = 8 days;

        SigUtils.Permit memory p = SigUtils.Permit({
            owner: permit.owner,
            spender: address(deployment.config),
            value: permit.amount,
            nonce: creditPermit.nonces(borrower),
            deadline: permit.deadline
        });

        bytes32 digest = sigUtils.getTypedDataHash(p);

        vm.startPrank(borrower);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(borrowerPK, digest);

        permit.v = v;
        permit.r = r;
        permit.s = s;

        // zero the approvals before the repayment, tokens should be transferred via permit
        creditPermit.approve(address(deployment.config), 0);

        deployment.config.repayMultipleLOANs(loanIds, address(creditPermit), abi.encode(permit));
    }

    function test_MultiplePartialLoans_RepayLOAN_PermitCreditTokens() external {
        uint256[] memory loanIds = _setupMultipleRepayCreditPermit();

        permit.asset = address(creditPermit);
        permit.owner = borrower;
        permit.amount = deployment.config.loanRepaymentAmount(loanIds[0]);
        permit.deadline = 8 days;

        SigUtils.Permit memory p = SigUtils.Permit({
            owner: permit.owner,
            spender: address(deployment.config),
            value: permit.amount,
            nonce: creditPermit.nonces(borrower),
            deadline: permit.deadline
        });

        bytes32 digest = sigUtils.getTypedDataHash(p);

        vm.startPrank(borrower);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(borrowerPK, digest);

        permit.v = v;
        permit.r = r;
        permit.s = s;

        // zero the approvals before the repayment, tokens should be transferred via permit
        creditPermit.approve(address(deployment.config), 0);

        deployment.config.repayLOAN(loanIds[0], abi.encode(permit));
    }

    function test_MultiplePartialLoans_RepayMultiple_RepayerNotOwner() external {
        uint256[] memory loanIds = _setupMultipleRepay();

        address repayer = makeAddr("repayer");
        uint256 repayAmount = deployment.config.totalLoanRepaymentAmount(loanIds, address(credit));

        credit.mint(repayer, repayAmount);
        vm.startPrank(repayer);
        credit.approve(address(deployment.config), repayAmount);
        deployment.config.repayMultipleLOANs(loanIds, address(credit), "");
        vm.stopPrank();

        // Assertions
        assertEq(credit.balanceOf(borrower), 8 * FIXED_INTEREST_AMOUNT); // 4x minted in _setupMultipleRepay & not used
        require(
            credit.balanceOf(lender) == credit.balanceOf(alice) && credit.balanceOf(lender) == credit.balanceOf(bob)
                && credit.balanceOf(lender) == credit.balanceOf(charlee)
        );
        assertEq(credit.balanceOf(lender), INITIAL_CREDIT_BALANCE + FIXED_INTEREST_AMOUNT);

        assertEq(0, deployment.loanToken.balanceOf(lender));
        assertEq(0, deployment.loanToken.balanceOf(alice));
        assertEq(0, deployment.loanToken.balanceOf(bob));
        assertEq(0, deployment.loanToken.balanceOf(charlee));
        assertEq(2000 * COLLATERAL_AMOUNT / 1e4, t20.balanceOf(borrower)); // 20% since 4 loans @ 5% minimum amount
        assertEq(8000 * COLLATERAL_AMOUNT / 1e4, t20.balanceOf(address(deployment.config)));
    }

    function test_MultiplePartialLoans_RepayMultiple_ClaimMultiple() external {
        uint256[] memory loanIds = _setupMultipleRepay();

        vm.prank(alice);
        deployment.loanToken.transferFrom(alice, lender, 2);

        vm.prank(bob);
        deployment.loanToken.transferFrom(bob, lender, 3);

        vm.prank(borrower);
        deployment.config.repayMultipleLOANs(loanIds, address(credit), "");

        uint256[] memory ids = new uint256[](2);
        ids[0] = 2;
        ids[1] = 3;

        vm.prank(lender);
        deployment.config.claimMultipleLOANs(ids);
    }

    function _setupMultipleRepay() internal returns (uint256[] memory loanIds) {
        vm.prank(borrower);
        bytes memory proposalSpec = _createERC20Proposal();

        // Setup lenders array
        address[] memory lenders = new address[](4);
        lenders[0] = lender;
        lenders[1] = alice;
        lenders[2] = bob;
        lenders[3] = charlee;

        // Minimum credit amount
        uint256 minCreditAmount = (proposal.availableCreditLimit * deployment.config.partialPositionPercentage()) / 1e4;

        // Setup loanIds array
        loanIds = new uint256[](4);

        // Create loans for lenders
        for (uint256 i; i < 4; ++i) {
            // Mint initial state & approve credit
            credit.mint(lenders[i], INITIAL_CREDIT_BALANCE);
            vm.startPrank(lenders[i]);
            credit.approve(address(deployment.config), minCreditAmount);

            // Lender spec
            ISproTypes.LenderSpec memory lenderSpec =
                ISproTypes.LenderSpec({ sourceOfFunds: lenders[i], creditAmount: minCreditAmount, permitData: "" });

            // Create loan
            loanIds[i] = deployment.config.createLOAN({ proposalData: proposalSpec, lenderSpec: lenderSpec, extra: "" });
            vm.stopPrank();
        }

        // Warp forward 4 days
        skip(4 days);

        // Approve repayment amount
        uint256 totalAmount = deployment.config.totalLoanRepaymentAmount(loanIds, address(credit));
        credit.mint(borrower, 4 * FIXED_INTEREST_AMOUNT);
        vm.prank(borrower);
        credit.approve(address(deployment.config), totalAmount);
    }

    function _setupMultipleRepayCreditPermit() internal returns (uint256[] memory loanIds) {
        proposal.creditAddress = address(creditPermit);

        vm.prank(borrower);
        bytes memory proposalSpec = _createERC20Proposal();

        // Setup lenders array
        address[] memory lenders = new address[](4);
        lenders[0] = lender;
        lenders[1] = alice;
        lenders[2] = bob;
        lenders[3] = charlee;

        // Minimum credit amount
        uint256 minCreditAmount = (proposal.availableCreditLimit * deployment.config.partialPositionPercentage()) / 1e4;

        // Setup loanIds array
        loanIds = new uint256[](4);

        // Create loans for lenders
        for (uint256 i; i < 4; ++i) {
            // Mint initial state & approve credit
            creditPermit.mint(lenders[i], INITIAL_CREDIT_BALANCE);
            vm.startPrank(lenders[i]);
            creditPermit.approve(address(deployment.config), minCreditAmount);

            // Lender spec
            ISproTypes.LenderSpec memory lenderSpec =
                ISproTypes.LenderSpec({ sourceOfFunds: lenders[i], creditAmount: minCreditAmount, permitData: "" });

            // Create loan
            loanIds[i] = deployment.config.createLOAN({ proposalData: proposalSpec, lenderSpec: lenderSpec, extra: "" });
            vm.stopPrank();
        }

        // Warp forward 4 days
        skip(4 days);

        // Approve repayment amount
        uint256 totalAmount = deployment.config.totalLoanRepaymentAmount(loanIds, address(creditPermit));
        creditPermit.mint(borrower, 4 * FIXED_INTEREST_AMOUNT);
        vm.prank(borrower);
        creditPermit.approve(address(deployment.config), totalAmount);
    }

    function test_loanMetadataUri() external view {
        string memory uri = deployment.config.loanMetadataUri();
        assertEq(uri, "");
    }

    function test_shouldFail_claimLOAN_CallerNotLoanTokenHolder() external {
        bytes memory proposalSpec = _createERC20Proposal();

        // Mint initial state & approve credit
        credit.mint(lender, INITIAL_CREDIT_BALANCE);
        vm.prank(lender);
        credit.approve(address(deployment.config), CREDIT_LIMIT);

        // Lender: creates the loan
        vm.prank(lender);
        uint256 loanId =
            deployment.config.createLOAN({ proposalData: proposalSpec, lenderSpec: _buildLenderSpec(false), extra: "" });

        vm.startPrank(borrower);
        // Borrower approvals for credit token
        credit.mint(borrower, FIXED_INTEREST_AMOUNT); // helper step: mint fixed interest amount for the borrower
        credit.approve(address(deployment.config), CREDIT_AMOUNT + FIXED_INTEREST_AMOUNT);
        vm.stopPrank();

        // Transfer loanToken to this address
        vm.prank(lender);
        deployment.loanToken.transferFrom(lender, address(this), loanId);

        // Borrower: repays loan
        vm.prank(borrower);
        deployment.config.repayLOAN(loanId, "");

        // Initial lender repays loan
        vm.startPrank(lender);
        vm.expectRevert(ISproErrors.CallerNotLOANTokenHolder.selector);
        deployment.config.claimLOAN(loanId);
    }

    function test_shouldFail_claimLOAN_RunningAndExpired() external {
        bytes memory proposalSpec = _createERC20Proposal();

        // Mint initial state & approve credit
        credit.mint(lender, INITIAL_CREDIT_BALANCE);
        vm.prank(lender);
        credit.approve(address(deployment.config), CREDIT_LIMIT);

        // Lender: creates the loan
        vm.prank(lender);
        uint256 loanId =
            deployment.config.createLOAN({ proposalData: proposalSpec, lenderSpec: _buildLenderSpec(true), extra: "" });

        // Borrower approvals for credit token
        vm.startPrank(borrower);
        credit.mint(borrower, FIXED_INTEREST_AMOUNT); // helper step: mint fixed interest amount for the borrower
        credit.approve(address(deployment.config), CREDIT_LIMIT + FIXED_INTEREST_AMOUNT);
        vm.stopPrank();

        // Transfer loanToken to this address
        vm.prank(lender);
        deployment.loanToken.transferFrom(lender, address(this), loanId);

        vm.warp(100 days); // loan should be expired

        // loan token holder claims the expired loan
        deployment.config.claimLOAN(loanId);

        assertEq(t20.balanceOf(address(this)), proposal.collateralAmount); // collateral amount transferred to loan
        // token holder
        assertEq(deployment.loanToken.balanceOf(address(this)), 0); // loanToken balance should be zero now
    }

    function test_shouldFail_claimLOAN_LoanRunning() external {
        bytes memory proposalSpec = _createERC20Proposal();

        // Mint initial state & approve credit
        credit.mint(lender, INITIAL_CREDIT_BALANCE);
        vm.prank(lender);
        credit.approve(address(deployment.config), CREDIT_LIMIT);

        // Lender: creates the loan
        vm.prank(lender);
        uint256 loanId =
            deployment.config.createLOAN({ proposalData: proposalSpec, lenderSpec: _buildLenderSpec(false), extra: "" });

        vm.startPrank(borrower);
        // Borrower approvals for credit token
        credit.mint(borrower, FIXED_INTEREST_AMOUNT); // helper step: mint fixed interest amount for the borrower
        credit.approve(address(deployment.config), CREDIT_AMOUNT + FIXED_INTEREST_AMOUNT);
        vm.stopPrank();

        // Try to repay loan
        vm.startPrank(lender);
        vm.expectRevert(ISproErrors.LoanRunning.selector);
        deployment.config.claimLOAN(loanId);
    }

    function test_RepayToPool() external {
        // Setup repay to pool
        vm.mockCall(
            address(deployment.config),
            abi.encodeWithSignature("getPoolAdapter(address)", address(this)),
            abi.encode(IPoolAdapter(poolAdapter))
        );

        _createERC20Proposal();

        bytes memory proposalSpec = abi.encode(proposal);
        Spro.LenderSpec memory lenderSpec = _buildLenderSpec(true);
        lenderSpec.sourceOfFunds = address(this);

        // Mint to source of funds and approve pool adapter
        credit.mint(address(this), INITIAL_CREDIT_BALANCE);
        credit.approve(address(poolAdapter), CREDIT_LIMIT);

        vm.prank(deployment.protocolAdmin);
        deployment.config.registerPoolAdapter(address(this), address(poolAdapter));
        // Lender creates loan
        vm.startPrank(lender);
        credit.approve(address(deployment.config), CREDIT_LIMIT);
        uint256 id = deployment.config.createLOAN(proposalSpec, lenderSpec, "");
        vm.stopPrank();

        // Borrower approvals for credit token
        vm.startPrank(borrower);
        credit.mint(borrower, FIXED_INTEREST_AMOUNT); // helper step: mint fixed interest amount for the borrower
        credit.approve(address(deployment.config), CREDIT_LIMIT + FIXED_INTEREST_AMOUNT);

        // End of setup
        deployment.config.repayLOAN(id, "");

        // Assertions
        assertEq(credit.balanceOf(borrower), 0);
        assertEq(credit.balanceOf(lender), 0);
        assertEq(credit.balanceOf(address(this)), INITIAL_CREDIT_BALANCE + FIXED_INTEREST_AMOUNT);

        assertEq(t20.balanceOf(borrower), COLLATERAL_AMOUNT);
        assertEq(t20.balanceOf(address(deployment.config)), 0);
        assertEq(t20.balanceOf(lender), 0);

        assertEq(deployment.sdex.balanceOf(address(Constants.SINK)), deployment.config.fixFeeUnlisted());
        assertEq(deployment.sdex.balanceOf(borrower), INITIAL_SDEX_BALANCE - deployment.config.fixFeeUnlisted());
        assertEq(deployment.sdex.balanceOf(lender), INITIAL_SDEX_BALANCE);
    }

    function testFuzz_loanAccruedInterest(uint256 amount, uint256 apr, uint256 future) external {
        amount = bound(amount, ((500 * CREDIT_LIMIT) / 1e4), ((9500 * CREDIT_LIMIT) / 1e4));
        apr = bound(apr, 1, Constants.MAX_ACCRUING_INTEREST_APR);
        future = bound(future, 1 days, proposal.startTimestamp);

        proposal.accruingInterestAPR = uint24(apr);

        // Create the proposal
        vm.prank(borrower);
        bytes memory proposalSpec = _createERC20Proposal();

        // Mint initial state & approve credit
        credit.mint(lender, INITIAL_CREDIT_BALANCE);
        vm.startPrank(lender);
        credit.approve(address(deployment.config), CREDIT_LIMIT);

        // Create loan
        ISproTypes.LenderSpec memory lenderSpec =
            ISproTypes.LenderSpec({ sourceOfFunds: lender, creditAmount: amount, permitData: "" });

        uint256 loanId = deployment.config.createLOAN({ proposalData: proposalSpec, lenderSpec: lenderSpec, extra: "" });

        // skip to the future
        skip(future);

        (ISproTypes.LoanInfo memory loanInfo) = deployment.config.getLOAN(loanId);

        // Assertions
        uint256 accruingMinutes = (loanInfo.defaultTimestamp - loanInfo.startTimestamp) / 1 minutes;
        uint256 accruedInterest = Math.mulDiv(
            amount,
            uint256(loanInfo.accruingInterestAPR) * accruingMinutes,
            Constants.ACCRUING_INTEREST_APR_DENOMINATOR,
            Math.Rounding.Ceil
        );

        assertEq(deployment.config.loanRepaymentAmount(loanId), amount + loanInfo.fixedInterestAmount + accruedInterest);
    }
}
