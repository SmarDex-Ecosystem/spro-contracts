// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import {
    MultiToken,
    MultiTokenCategoryRegistry,
    SDBaseIntegrationTest,
    SDConfig,
    IPWNDeployer,
    PWNHub,
    PWNHubTags,
    SDSimpleLoan,
    SDSimpleLoanSimpleProposal,
    PWNLOAN,
    PWNRevokedNonce
} from "test/integration/SDBaseIntegrationTest.t.sol";
import {SDSimpleLoanProposal} from "pwn/loan/terms/simple/proposal/SDSimpleLoanProposal.sol";

contract SDSimpleLoanIntegrationTest is SDBaseIntegrationTest {
    function test_shouldCreateERC20Proposal_shouldCreatePartialLoan_shouldWithdrawRemainingCollateral() external {
        // Create the proposal
        vm.prank(borrower);
        SDSimpleLoan.ProposalSpec memory proposalSpec = _createERC20Proposal();

        // Create the loan
        vm.prank(lender);
        uint256 loanId = _createLoan(proposalSpec, "");

        // Borrower withdraws remaining collateral
        vm.startPrank(borrower);
        deployment.simpleLoanSimpleProposal.revokeNonce(proposal.nonceSpace, proposal.nonce);
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
            credit.balanceOf(address(deployment.simpleLoan)), 0, "3: credit token balance of loan contract should be 0"
        );
        // collateral token
        assertEq(t20.balanceOf(lender), 0, "4: ERC20 collateral token balance of lender should be 0");
        assertEq(
            t20.balanceOf(borrower),
            COLLATERAL_AMOUNT - (CREDIT_AMOUNT * COLLATERAL_AMOUNT) / CREDIT_LIMIT,
            "5: ERC20 collateral token balance of borrower should be unused collateral"
        );
        assertEq(
            t20.balanceOf(address(deployment.simpleLoan)),
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
        assertEq(
            deployment.loanToken.loanContract(loanId),
            address(deployment.simpleLoan),
            "8: loan contract should be mapped to loanId"
        );
        // sdex fees
        assertEq(
            deployment.sdex.balanceOf(address(deployment.sink)),
            deployment.config.unlistedFee(),
            "9: sink should contain the sdex unlisted fee"
        );
    }

    function test_shouldCreateERC721Proposal_shouldCreateLoan_cannotWithdrawCollateral() external {
        // Create the proposal
        vm.prank(borrower);
        SDSimpleLoan.ProposalSpec memory proposalSpec = _createERC721Proposal();

        // Create the loan
        vm.prank(lender);
        uint256 loanId = _createLoan(proposalSpec, "");

        // Borrower withdraws remaining collateral
        vm.prank(borrower);
        vm.expectRevert(
            abi.encodeWithSelector(
                SDSimpleLoan.InvalidMultiTokenAsset.selector,
                uint8(proposal.collateralCategory),
                proposal.collateralAddress,
                proposal.collateralId,
                type(uint256).max
            )
        );
        _cancelProposal(proposal);

        // ASSERTIONS
        // loan token
        assertEq(deployment.loanToken.ownerOf(loanId), lender, "0: loanToken owner should be lender");
        // credit token
        assertEq(
            credit.balanceOf(lender),
            INITIAL_CREDIT_BALANCE - CREDIT_LIMIT,
            "1: initial credit token balance reduced by credit limit (== credit amount)"
        );
        assertEq(credit.balanceOf(borrower), CREDIT_LIMIT, "2: credit token balance of borrower should be CREDIT_LIMIT");
        assertEq(
            credit.balanceOf(address(deployment.simpleLoan)), 0, "3: credit token balance of loan contract should be 0"
        );
        // collateral token
        assertEq(t721.balanceOf(lender), 0, "4: ERC721 collateral token balance of lender should be 0");
        assertEq(t721.balanceOf(borrower), 0, "5: ERC721 collateral token balance of borrower should be 0");
        assertEq(
            t721.balanceOf(address(deployment.simpleLoan)),
            1,
            "6: ERC721 collateral token balance of loan contract should be used collateral"
        );
        // nonce
        assertEq(
            deployment.revokedNonce.isNonceUsable(borrower, proposal.nonceSpace, proposal.nonce),
            false,
            "7: nonce for borrower should not be usable"
        );
        // loan id
        assertEq(
            deployment.loanToken.loanContract(loanId),
            address(deployment.simpleLoan),
            "8: loan contract should be mapped to loanId"
        );
        // sdex fees
        assertEq(
            deployment.sdex.balanceOf(address(deployment.sink)),
            deployment.config.unlistedFee(),
            "9: sink should contain the sdex unlisted fee"
        );
    }

    function test_shouldCreateERC721Proposal_withdrawCollateral() external {
        // Create the proposal
        vm.prank(borrower);
        _createERC721Proposal();

        // Borrower withdraws remaining collateral
        vm.startPrank(borrower);
        _cancelProposal(proposal);

        // ASSERTIONS
        // collateral token
        assertEq(t721.balanceOf(lender), 0, "0: ERC721 collateral token balance of lender should be 0");
        assertEq(t721.balanceOf(borrower), 1, "1: ERC721 collateral token balance of borrower should be 1");
        assertEq(
            t721.balanceOf(address(deployment.simpleLoan)),
            0,
            "2: ERC721 collateral token balance of loan contract should be 0"
        );
        // nonce
        assertEq(
            deployment.revokedNonce.isNonceUsable(borrower, proposal.nonceSpace, proposal.nonce),
            false,
            "3: nonce for borrower should not be usable"
        );
    }

    function test_shouldCreateFungibleERC1155Proposal_shouldCreateLoan_canWithdrawRemainingCollateral() external {
        // Create the proposal
        vm.prank(borrower);
        SDSimpleLoan.ProposalSpec memory proposalSpec = _createFungibleERC1155Proposal();

        // Create the loan
        vm.prank(lender);
        uint256 loanId = _createLoan(proposalSpec, "");

        // Borrower withdraws remaining collateral
        vm.startPrank(borrower);
        _cancelProposal(proposal);

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
            credit.balanceOf(address(deployment.simpleLoan)), 0, "3: credit token balance of loan contract should be 0"
        );
        // collateral token
        assertEq(t1155.balanceOf(lender, COLLATERAL_ID), 0, "4: ERC1155 collateral token balance of lender should be 0");
        assertEq(
            t1155.balanceOf(borrower, COLLATERAL_ID),
            COLLATERAL_AMOUNT - (CREDIT_AMOUNT * COLLATERAL_AMOUNT) / CREDIT_LIMIT,
            "5: ERC1155 collateral token balance of borrower should be unused collateral"
        );
        assertEq(
            t1155.balanceOf(address(deployment.simpleLoan), COLLATERAL_ID),
            (CREDIT_AMOUNT * COLLATERAL_AMOUNT) / CREDIT_LIMIT,
            "6: ERC1155 collateral token balance of loan contract should be used collateral"
        );
        // nonce
        assertEq(
            deployment.revokedNonce.isNonceUsable(borrower, proposal.nonceSpace, proposal.nonce),
            false,
            "7: nonce for borrower should not be usable"
        );
        // loan id
        assertEq(
            deployment.loanToken.loanContract(loanId),
            address(deployment.simpleLoan),
            "8: loan contract should be mapped to loanId"
        );
        // sdex fees
        assertEq(
            deployment.sdex.balanceOf(address(deployment.sink)),
            deployment.config.unlistedFee(),
            "9: sink should contain the sdex unlisted fee"
        );
    }

    function test_shouldCreateNonFungibleERC1155Proposal_shouldCreateLoan_cannotWithdrawCollateral() external {
        // Create the proposal
        vm.prank(borrower);
        SDSimpleLoan.ProposalSpec memory proposalSpec = _createNonFungibleERC1155Proposal();

        // Create the loan
        vm.prank(lender);
        uint256 loanId = _createLoan(proposalSpec, "");

        // Borrower attempts to withdraw remaining collateral. Expect revert for ERC1155 amount == 0.
        vm.startPrank(borrower);
        vm.expectRevert(
            abi.encodeWithSelector(
                SDSimpleLoan.InvalidMultiTokenAsset.selector,
                uint8(proposal.collateralCategory),
                proposal.collateralAddress,
                proposal.collateralId,
                0
            )
        );
        _cancelProposal(proposal);

        // ASSERTIONS
        // loan token
        assertEq(deployment.loanToken.ownerOf(loanId), lender, "0: loanToken owner should be lender");
        // credit token
        assertEq(
            credit.balanceOf(lender),
            INITIAL_CREDIT_BALANCE - CREDIT_LIMIT,
            "1: initial credit token balance reduced by credit amount"
        );
        assertEq(credit.balanceOf(borrower), CREDIT_LIMIT, "2: credit token balance of borrower should be CREDIT_LIMIT");
        assertEq(
            credit.balanceOf(address(deployment.simpleLoan)), 0, "3: credit token balance of loan contract should be 0"
        );
        // collateral token
        assertEq(t1155.balanceOf(lender, COLLATERAL_ID), 0, "4: ERC1155 collateral token balance of lender should be 0");
        assertEq(
            t1155.balanceOf(borrower, COLLATERAL_ID), 0, "5: ERC1155 collateral token balance of borrower should be 0"
        );
        assertEq(
            t1155.balanceOf(address(deployment.simpleLoan), COLLATERAL_ID),
            1,
            "6: ERC1155 collateral token balance of loan contract should be 1"
        );
        // nonce
        assertEq(
            deployment.revokedNonce.isNonceUsable(borrower, proposal.nonceSpace, proposal.nonce),
            false,
            "7: nonce for borrower should not be usable"
        );
        // loan id
        assertEq(
            deployment.loanToken.loanContract(loanId),
            address(deployment.simpleLoan),
            "8: loan contract should be mapped to loanId"
        );
        // sdex fees
        assertEq(
            deployment.sdex.balanceOf(address(deployment.sink)),
            deployment.config.unlistedFee(),
            "9: sink should contain the sdex unlisted fee"
        );
    }

    function test_PartialLoan_ERC20Collateral_CancelProposal_RepayLoan() external {
        // Borrower: creates proposal
        SDSimpleLoan.ProposalSpec memory proposalSpec = _createERC20Proposal();

        // Mint initial state & approve credit
        credit.mint(lender, INITIAL_CREDIT_BALANCE);
        vm.prank(lender);
        credit.approve(address(deployment.simpleLoan), CREDIT_LIMIT);

        // Lender: creates the loan
        vm.prank(lender);
        uint256 loanId = deployment.simpleLoan.createLOAN({
            proposalSpec: proposalSpec,
            lenderSpec: _buildLenderSpec(false),
            extra: ""
        });

        // Borrower: cancels proposal, withdrawing unused collateral
        vm.startPrank(borrower);
        deployment.simpleLoan.cancelProposal(proposalSpec);

        // Warp ahead, just before loan default
        vm.warp(proposal.duration - 1);

        // Borrower approvals for credit token
        credit.mint(borrower, FIXED_INTEREST_AMOUNT); // helper step: mint fixed interest amount for the borrower
        credit.approve(address(deployment.simpleLoan), CREDIT_AMOUNT + FIXED_INTEREST_AMOUNT);

        // Borrower: repays loan
        deployment.simpleLoan.repayLOAN(loanId, "");

        // Assertions
        assertEq(credit.balanceOf(borrower), 0);
        assertEq(credit.balanceOf(lender), INITIAL_CREDIT_BALANCE + FIXED_INTEREST_AMOUNT);

        assertEq(t20.balanceOf(borrower), COLLATERAL_AMOUNT);
        assertEq(t20.balanceOf(address(deployment.simpleLoan)), 0);
        assertEq(t20.balanceOf(lender), 0);

        assertEq(deployment.sdex.balanceOf(address(deployment.sink)), deployment.config.unlistedFee());
        assertEq(deployment.sdex.balanceOf(borrower), INITIAL_SDEX_BALANCE - deployment.config.unlistedFee());
        assertEq(deployment.sdex.balanceOf(lender), INITIAL_SDEX_BALANCE);
    }

    function test_CompleteLoan_ERC721Collateral_RepayLoan() external {
        // Borrower: creates proposal
        SDSimpleLoan.ProposalSpec memory proposalSpec = _createERC721Proposal();

        // Mint initial state & approve credit
        credit.mint(lender, INITIAL_CREDIT_BALANCE);
        vm.prank(lender);
        credit.approve(address(deployment.simpleLoan), CREDIT_LIMIT);

        // Lender: creates the loan
        vm.prank(lender);
        uint256 loanId = deployment.simpleLoan.createLOAN({
            proposalSpec: proposalSpec,
            lenderSpec: _buildLenderSpec(true),
            extra: ""
        });

        // Warp ahead, just before loan default
        vm.warp(proposal.duration - 1);

        vm.startPrank(borrower);
        // Borrower approvals for credit token
        credit.mint(borrower, FIXED_INTEREST_AMOUNT); // helper step: mint fixed interest amount for the borrower
        credit.approve(address(deployment.simpleLoan), CREDIT_LIMIT + FIXED_INTEREST_AMOUNT);

        // Borrower: repays loan
        deployment.simpleLoan.repayLOAN(loanId, "");

        // Assertions
        assertEq(credit.balanceOf(borrower), 0);
        assertEq(credit.balanceOf(lender), INITIAL_CREDIT_BALANCE + FIXED_INTEREST_AMOUNT);

        assertEq(t721.balanceOf(borrower), 1);
        assertEq(t721.balanceOf(address(deployment.simpleLoan)), 0);
        assertEq(t721.balanceOf(lender), 0);

        assertEq(deployment.sdex.balanceOf(address(deployment.sink)), deployment.config.unlistedFee());
        assertEq(deployment.sdex.balanceOf(borrower), INITIAL_SDEX_BALANCE - deployment.config.unlistedFee());
        assertEq(deployment.sdex.balanceOf(lender), INITIAL_SDEX_BALANCE);
    }

    function test_PartialLoan_FungibleERC1155Collateral_CancelProposal_RepayLoan() external {
        // Borrower: creates proposal
        SDSimpleLoan.ProposalSpec memory proposalSpec = _createFungibleERC1155Proposal();

        // Mint initial state & approve credit
        credit.mint(lender, INITIAL_CREDIT_BALANCE);
        vm.prank(lender);
        credit.approve(address(deployment.simpleLoan), CREDIT_LIMIT);

        // Lender: creates the loan
        vm.prank(lender);
        uint256 loanId = deployment.simpleLoan.createLOAN({
            proposalSpec: proposalSpec,
            lenderSpec: _buildLenderSpec(false),
            extra: ""
        });

        // Warp ahead, just before loan default
        vm.warp(proposal.duration - 1);

        // Borrower: cancels proposal, withdrawing unused collateral
        vm.startPrank(borrower);
        deployment.simpleLoan.cancelProposal(proposalSpec);

        // Borrower approvals for credit token
        credit.mint(borrower, FIXED_INTEREST_AMOUNT); // helper step: mint fixed interest amount for the borrower
        credit.approve(address(deployment.simpleLoan), CREDIT_AMOUNT + FIXED_INTEREST_AMOUNT);

        // Borrower: repays loan
        deployment.simpleLoan.repayLOAN(loanId, "");

        // Assertions
        assertEq(credit.balanceOf(borrower), 0);
        assertEq(credit.balanceOf(lender), INITIAL_CREDIT_BALANCE + FIXED_INTEREST_AMOUNT);

        assertEq(t1155.balanceOf(borrower, COLLATERAL_ID), COLLATERAL_AMOUNT);
        assertEq(t1155.balanceOf(address(deployment.simpleLoan), COLLATERAL_ID), 0);
        assertEq(t1155.balanceOf(lender, COLLATERAL_ID), 0);

        assertEq(deployment.sdex.balanceOf(address(deployment.sink)), deployment.config.unlistedFee());
        assertEq(deployment.sdex.balanceOf(borrower), INITIAL_SDEX_BALANCE - deployment.config.unlistedFee());
        assertEq(deployment.sdex.balanceOf(lender), INITIAL_SDEX_BALANCE);
    }

    function test_PartialLoan_GtCreditThreshold() external {
        // Create the proposal
        vm.prank(borrower);
        SDSimpleLoan.ProposalSpec memory proposalSpec = _createERC20Proposal();

        // 97% of available credit limit
        uint256 amount = 9700 * CREDIT_LIMIT / 1e4;

        // Mint initial state & approve credit
        credit.mint(lender, INITIAL_CREDIT_BALANCE);
        vm.startPrank(lender);
        credit.approve(address(deployment.simpleLoan), CREDIT_LIMIT);

        SDSimpleLoan.LenderSpec memory lenderSpec =
            SDSimpleLoan.LenderSpec({sourceOfFunds: lender, creditAmount: amount, permitData: ""});

        // Create loan
        deployment.simpleLoan.createLOAN({proposalSpec: proposalSpec, lenderSpec: lenderSpec, extra: ""});
        vm.stopPrank();

        // Borrower cancels remaining 3% of the proposal
        vm.prank(borrower);
        _cancelProposal(proposal);

        // Assertions

        // Nonce should not be usable (greater than threshold)
        assertEq(
            deployment.revokedNonce.isNonceUsable(borrower, proposal.nonceSpace, proposal.nonce),
            false,
            "7: nonce for borrower should not be usable"
        );

        // Credit used and credit remaining
        (uint256 used, uint256 remaining) = deployment.simpleLoanSimpleProposal.getProposalCreditStatus(proposal);
        assertEq(used, amount);
        assertEq(remaining, 300 * CREDIT_LIMIT / 1e4);

        // Borrower can withdraw remaining 3% collateral
        assertEq(t20.balanceOf(borrower), proposal.collateralAmount * 300 / 1e4);
    }

    function test_RevertWhen_CreateAlreadyMadeProposal() external {
        // Create the proposal
        _createERC20Proposal();
        // Mint initial state & approve collateral
        t20.mint(borrower, proposal.collateralAmount);
        vm.prank(borrower);
        t20.approve(address(deployment.simpleLoan), proposal.collateralAmount);

        // Create the proposal
        SDSimpleLoan.ProposalSpec memory proposalSpec = _buildProposalSpec(proposal);

        vm.expectRevert(SDSimpleLoanProposal.ProposalAlreadyExists.selector);
        vm.prank(borrower);
        deployment.simpleLoan.createProposal(proposalSpec);
    }

    function test_RevertWhen_InvalidCollateralAsset() external {
        proposal.collateralCategory = MultiToken.Category.ERC721;
        proposal.collateralAddress = address(t721);
        proposal.collateralId = COLLATERAL_ID;
        proposal.collateralAmount = 2; // this is invalid

        // Mint initial state & approve collateral
        t721.mint(borrower, COLLATERAL_ID);
        vm.prank(borrower);
        t721.approve(address(deployment.simpleLoan), COLLATERAL_ID);

        SDSimpleLoan.ProposalSpec memory proposalSpec = _buildProposalSpec(proposal);

        vm.startPrank(borrower);

        vm.expectRevert(
            abi.encodeWithSelector(
                SDSimpleLoan.InvalidMultiTokenAsset.selector,
                uint8(proposal.collateralCategory),
                proposal.collateralAddress,
                proposal.collateralId,
                proposal.collateralAmount
            )
        );
        deployment.simpleLoan.createProposal(proposalSpec);
    }
}
