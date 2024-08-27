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
import {Expired, AddressMissingHubTag} from "pwn/PWNErrors.sol";

contract CreateLoan_SDSimpleLoan_Integration_Concrete_Test is SDBaseIntegrationTest {
    function test_RevertWhen_NoProposalLoanTag() external {
        _createERC20Proposal();

        // Remove LOAN_PROPOSAL tag for proposal contract
        address[] memory addrs = new address[](1);
        addrs[0] = address(deployment.simpleLoanSimpleProposal);
        bytes32[] memory tags = new bytes32[](1);
        tags[0] = PWNHubTags.LOAN_PROPOSAL;

        vm.prank(deployment.protocolAdmin);
        deployment.hub.setTags(addrs, tags, false);

        SDSimpleLoan.ProposalSpec memory proposalSpec = _buildProposalSpec(proposal);
        SDSimpleLoan.LenderSpec memory lenderSpec = _buildLenderSpec(true);

        vm.prank(lender);
        vm.expectRevert(
            abi.encodeWithSelector(
                AddressMissingHubTag.selector, address(deployment.simpleLoanSimpleProposal), PWNHubTags.LOAN_PROPOSAL
            )
        );
        deployment.simpleLoan.createLOAN(proposalSpec, lenderSpec, "");
    }

    modifier proposalContractHasTag() {
        _;
    }

    function test_RevertWhen_InvalidLoanDuration() external proposalContractHasTag {
        // Set bad duration value
        uint256 minDuration = deployment.simpleLoan.MIN_LOAN_DURATION();
        proposal.duration = uint32(minDuration - 1);

        // Create proposal
        _createERC20Proposal();

        // Specs
        SDSimpleLoan.ProposalSpec memory proposalSpec = _buildProposalSpec(proposal);
        SDSimpleLoan.LenderSpec memory lenderSpec = _buildLenderSpec(true);

        vm.prank(lender);
        vm.expectRevert(abi.encodeWithSelector(SDSimpleLoan.InvalidDuration.selector, proposal.duration, minDuration));
        deployment.simpleLoan.createLOAN(proposalSpec, lenderSpec, "");
    }

    function test_RevertWhen_InvalidMaxApr() external proposalContractHasTag {
        // Set bad max accruing interest apr
        uint256 maxApr = deployment.simpleLoan.MAX_ACCRUING_INTEREST_APR();
        proposal.accruingInterestAPR = uint24(maxApr + 1);

        // Create proposal
        SDSimpleLoan.ProposalSpec memory proposalSpec = _createERC20Proposal();

        // Specs
        SDSimpleLoan.LenderSpec memory lenderSpec = _buildLenderSpec(true);

        vm.prank(lender);
        vm.expectRevert(
            abi.encodeWithSelector(SDSimpleLoan.InterestAPROutOfBounds.selector, proposal.accruingInterestAPR, maxApr)
        );
        deployment.simpleLoan.createLOAN(proposalSpec, lenderSpec, "");
    }

    modifier whenLoanTermsValid() {
        _;
    }

    modifier whenERC20Collateral() {
        _;
    }

    modifier whenERC721Collateral() {
        _;
    }

    modifier whenERC1155Collateral() {
        _;
    }

    function test_CreateLoan_ERC20() external proposalContractHasTag whenLoanTermsValid whenERC20Collateral {
        _createERC20Proposal();

        SDSimpleLoan.ProposalSpec memory proposalSpec = _buildProposalSpec(proposal);
        SDSimpleLoan.LenderSpec memory lenderSpec = _buildLenderSpec(true);

        vm.startPrank(lender);
        credit.mint(lender, INITIAL_CREDIT_BALANCE);
        credit.approve(address(deployment.simpleLoan), CREDIT_LIMIT);

        uint256 id = deployment.simpleLoan.createLOAN(proposalSpec, lenderSpec, "");
        vm.stopPrank();

        assertEq(deployment.loanToken.ownerOf(id), lender);
        assertEq(deployment.sdex.balanceOf(address(deployment.sink)), deployment.config.unlistedFee());
        assertEq(deployment.sdex.balanceOf(borrower), INITIAL_SDEX_BALANCE - deployment.config.unlistedFee());
        assertEq(deployment.sdex.balanceOf(lender), INITIAL_SDEX_BALANCE);

        (uint8 status,,,,,,,,,,,) = deployment.simpleLoan.getLOAN(id);
        assertEq(status, 2);

        assertEq(credit.balanceOf(lender), INITIAL_CREDIT_BALANCE - lenderSpec.creditAmount);
        assertEq(credit.balanceOf(borrower), lenderSpec.creditAmount);
    }

    function test_CreateLoan_ERC721() external proposalContractHasTag whenLoanTermsValid whenERC721Collateral {
        _createERC721Proposal();

        SDSimpleLoan.ProposalSpec memory proposalSpec = _buildProposalSpec(proposal);
        SDSimpleLoan.LenderSpec memory lenderSpec = _buildLenderSpec(true);

        vm.startPrank(lender);
        credit.mint(lender, INITIAL_CREDIT_BALANCE);
        credit.approve(address(deployment.simpleLoan), CREDIT_LIMIT);

        uint256 id = deployment.simpleLoan.createLOAN(proposalSpec, lenderSpec, "");
        vm.stopPrank();

        assertEq(deployment.loanToken.ownerOf(id), lender);
        assertEq(deployment.sdex.balanceOf(address(deployment.sink)), deployment.config.unlistedFee());
        assertEq(deployment.sdex.balanceOf(borrower), INITIAL_SDEX_BALANCE - deployment.config.unlistedFee());
        assertEq(deployment.sdex.balanceOf(lender), INITIAL_SDEX_BALANCE);

        (uint8 status,,,,,,,,,,,) = deployment.simpleLoan.getLOAN(id);
        assertEq(status, 2);

        assertEq(credit.balanceOf(lender), INITIAL_CREDIT_BALANCE - lenderSpec.creditAmount);
        assertEq(credit.balanceOf(borrower), lenderSpec.creditAmount);
    }

    function test_CreateLoan_ERC1155() external proposalContractHasTag whenLoanTermsValid whenERC1155Collateral {
        _createFungibleERC1155Proposal();

        SDSimpleLoan.ProposalSpec memory proposalSpec = _buildProposalSpec(proposal);
        SDSimpleLoan.LenderSpec memory lenderSpec = _buildLenderSpec(true);

        vm.startPrank(lender);
        credit.mint(lender, INITIAL_CREDIT_BALANCE);
        credit.approve(address(deployment.simpleLoan), CREDIT_LIMIT);

        uint256 id = deployment.simpleLoan.createLOAN(proposalSpec, lenderSpec, "");
        vm.stopPrank();

        assertEq(deployment.loanToken.ownerOf(id), lender);
        assertEq(deployment.sdex.balanceOf(address(deployment.sink)), deployment.config.unlistedFee());
        assertEq(deployment.sdex.balanceOf(borrower), INITIAL_SDEX_BALANCE - deployment.config.unlistedFee());
        assertEq(deployment.sdex.balanceOf(lender), INITIAL_SDEX_BALANCE);

        (uint8 status,,,,,,,,,,,) = deployment.simpleLoan.getLOAN(id);
        assertEq(status, 2);

        assertEq(credit.balanceOf(lender), INITIAL_CREDIT_BALANCE - lenderSpec.creditAmount);
        assertEq(credit.balanceOf(borrower), lenderSpec.creditAmount);
    }
}
