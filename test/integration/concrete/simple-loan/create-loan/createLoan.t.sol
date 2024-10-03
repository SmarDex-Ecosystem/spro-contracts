// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { SDSimpleLoanProposal } from "pwn/loan/terms/simple/proposal/SDSimpleLoanProposal.sol";
import { Expired, AddressMissingHubTag } from "pwn/PWNErrors.sol";
import { SigUtils } from "test/utils/SigUtils.sol";
import { IPoolAdapter } from "test/helper/DummyPoolAdapter.sol";
import {
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
        proposal.startTimestamp = uint40(block.timestamp);
        proposal.defaultTimestamp = uint40(block.timestamp) + uint32(minDuration - 1);

        // Create proposal
        _createERC20Proposal();

        // Specs
        SDSimpleLoan.ProposalSpec memory proposalSpec = _buildProposalSpec(proposal);
        SDSimpleLoan.LenderSpec memory lenderSpec = _buildLenderSpec(true);

        vm.prank(lender);
        vm.expectRevert(
            abi.encodeWithSelector(
                SDSimpleLoan.InvalidDuration.selector, proposal.defaultTimestamp - proposal.startTimestamp, minDuration
            )
        );
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
        assertEq(deployment.sdex.balanceOf(address(deployment.config.SINK())), deployment.config.fixFeeUnlisted());
        assertEq(deployment.sdex.balanceOf(borrower), INITIAL_SDEX_BALANCE - deployment.config.fixFeeUnlisted());
        assertEq(deployment.sdex.balanceOf(lender), INITIAL_SDEX_BALANCE);

        (SDSimpleLoan.LoanInfo memory loanInfo) = deployment.simpleLoan.getLOAN(id);
        assertEq(loanInfo.status, 2);

        assertEq(credit.balanceOf(lender), INITIAL_CREDIT_BALANCE - lenderSpec.creditAmount);
        assertEq(credit.balanceOf(borrower), lenderSpec.creditAmount);
    }

    function test_CreateLoan_ERC20_LenderNotSourceOfFunds()
        external
        proposalContractHasTag
        whenLoanTermsValid
        whenERC20Collateral
    {
        vm.mockCall(
            address(deployment.config),
            abi.encodeWithSignature("getPoolAdapter(address)", address(this)),
            abi.encode(IPoolAdapter(poolAdapter))
        );

        _createERC20Proposal();

        SDSimpleLoan.ProposalSpec memory proposalSpec = _buildProposalSpec(proposal);
        SDSimpleLoan.LenderSpec memory lenderSpec = _buildLenderSpec(true);
        lenderSpec.sourceOfFunds = address(this);

        // Mint to source of funds and approve pool adapter
        credit.mint(address(this), INITIAL_CREDIT_BALANCE);
        credit.approve(address(poolAdapter), CREDIT_LIMIT);

        // Lender creates loan
        vm.startPrank(lender);
        credit.approve(address(deployment.simpleLoan), CREDIT_LIMIT);
        uint256 id = deployment.simpleLoan.createLOAN(proposalSpec, lenderSpec, "");
        vm.stopPrank();

        assertEq(deployment.loanToken.ownerOf(id), lender);
        assertEq(deployment.sdex.balanceOf(address(deployment.config.SINK())), deployment.config.fixFeeUnlisted());
        assertEq(deployment.sdex.balanceOf(borrower), INITIAL_SDEX_BALANCE - deployment.config.fixFeeUnlisted());
        assertEq(deployment.sdex.balanceOf(lender), INITIAL_SDEX_BALANCE);

        (SDSimpleLoan.LoanInfo memory loanInfo) = deployment.simpleLoan.getLOAN(id);
        assertEq(loanInfo.status, 2);

        assertEq(credit.balanceOf(address(this)), INITIAL_CREDIT_BALANCE - lenderSpec.creditAmount);
        assertEq(credit.balanceOf(lender), 0);
        assertEq(credit.balanceOf(borrower), lenderSpec.creditAmount);
    }

    function test_CreateLoan_ERC20_PermitData()
        external
        proposalContractHasTag
        whenLoanTermsValid
        whenERC20Collateral
    {
        // Change the credit asset address
        proposal.creditAddress = address(creditPermit);
        _createERC20Proposal();

        SDSimpleLoan.ProposalSpec memory proposalSpec = _buildProposalSpec(proposal);
        SDSimpleLoan.LenderSpec memory lenderSpec = _buildLenderSpec(true);

        // Construct permit data for the lender
        permit.asset = address(creditPermit);
        permit.owner = lender;
        permit.amount = CREDIT_LIMIT;
        permit.deadline = 1 days;

        SigUtils.Permit memory p = SigUtils.Permit({
            owner: permit.owner,
            spender: address(deployment.simpleLoan),
            value: permit.amount,
            nonce: creditPermit.nonces(lender),
            deadline: permit.deadline
        });

        bytes32 digest = sigUtils.getTypedDataHash(p);

        vm.startPrank(lender);
        // Mint initial credit permit balance for lender
        creditPermit.mint(lender, INITIAL_CREDIT_BALANCE);
        // sign the digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(lenderPK, digest);

        permit.v = v;
        permit.r = r;
        permit.s = s;

        // Zero the approvals before the repayment, tokens should be transferred via permit
        creditPermit.approve(address(deployment.simpleLoan), 0);

        // Set the permit data
        lenderSpec.permitData = abi.encode(permit);

        uint256 id = deployment.simpleLoan.createLOAN(proposalSpec, lenderSpec, "");
        vm.stopPrank();

        assertEq(deployment.loanToken.ownerOf(id), lender);
        assertEq(deployment.sdex.balanceOf(address(deployment.config.SINK())), deployment.config.fixFeeUnlisted());
        assertEq(deployment.sdex.balanceOf(borrower), INITIAL_SDEX_BALANCE - deployment.config.fixFeeUnlisted());
        assertEq(deployment.sdex.balanceOf(lender), INITIAL_SDEX_BALANCE);

        (SDSimpleLoan.LoanInfo memory loanInfo) = deployment.simpleLoan.getLOAN(id);
        assertEq(loanInfo.status, 2);

        assertEq(creditPermit.balanceOf(lender), INITIAL_CREDIT_BALANCE - lenderSpec.creditAmount);
        assertEq(creditPermit.balanceOf(borrower), lenderSpec.creditAmount);
    }
}
