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

contract SDSimpleLoanIntegrationTest is SDBaseIntegrationTest {
    // Create LOAN

    function test_shouldCreateLOAN_fromSimpleProposal() external {
        uint256 CREDIT_LIMIT = 100e18;

        SDSimpleLoanSimpleProposal.Proposal memory proposal = SDSimpleLoanSimpleProposal.Proposal({
            collateralCategory: MultiToken.Category.ERC1155,
            collateralAddress: address(t1155),
            collateralId: 42,
            collateralAmount: COLLATERAL_AMOUNT,
            checkCollateralStateFingerprint: false,
            collateralStateFingerprint: bytes32(0),
            creditAddress: address(credit),
            creditAmount: CREDIT_AMOUNT,
            availableCreditLimit: CREDIT_LIMIT,
            fixedInterestAmount: 10e18,
            accruingInterestAPR: 0,
            duration: 7 days,
            expiration: uint40(block.timestamp + 1 days),
            allowedAcceptor: borrower,
            proposer: lender,
            proposerSpecHash: deployment.simpleLoan.getLenderSpecHash(SDSimpleLoan.LenderSpec(lender)),
            isOffer: true,
            refinancingLoanId: 0,
            nonceSpace: 0,
            nonce: 0,
            loanContract: address(deployment.simpleLoan)
        });

        // Mint initial state
        t1155.mint(borrower, 42, COLLATERAL_AMOUNT);

        // Approve collateral
        vm.prank(borrower);
        t1155.setApprovalForAll(address(deployment.simpleLoan), true);

        // Sign proposal
        bytes memory signature = _sign(lenderPK, deployment.simpleLoanSimpleProposal.getProposalHash(proposal));

        // Mint initial state
        credit.mint(lender, CREDIT_AMOUNT);

        // Approve loan asset
        vm.prank(lender);
        credit.approve(address(deployment.simpleLoan), CREDIT_AMOUNT);

        // Mint and Approve sdex
        deployment.sdex.mint(lender, type(uint256).max);
        vm.prank(lender);
        deployment.sdex.approve(address(deployment.simpleLoan), type(uint256).max);

        // Proposal data (need for vm.prank to work properly when creating a loan)
        bytes memory proposalData = deployment.simpleLoanSimpleProposal.encodeProposalData(proposal);

        // Create LOAN
        vm.prank(borrower);
        uint256 loanId = deployment.simpleLoan.createLOAN({
            proposalSpec: SDSimpleLoan.ProposalSpec({
                proposalContract: address(deployment.simpleLoanSimpleProposal),
                proposalData: proposalData,
                proposalInclusionProof: new bytes32[](0),
                signature: signature
            }),
            lenderSpec: SDSimpleLoan.LenderSpec({sourceOfFunds: lender}),
            callerSpec: SDSimpleLoan.CallerSpec({refinancingLoanId: 0, revokeNonce: false, nonce: 0, permitData: ""}),
            extra: ""
        });

        // Assert final state
        assertEq(deployment.loanToken.ownerOf(loanId), lender, "0: loanToken ownwer should be lender");

        assertEq(credit.balanceOf(lender), 0, "1: credit token balance of lender should be 0");
        assertEq(
            credit.balanceOf(borrower), CREDIT_AMOUNT, "2: credit token balance of borrower should be CREDIT_AMOUNT"
        );
        assertEq(
            credit.balanceOf(address(deployment.simpleLoan)), 0, "3: credit token balance of loan contract should be 0"
        );

        assertEq(t1155.balanceOf(lender, 42), 0, "4: ERC1155 id 42 balance of lender should be 0");
        assertEq(t1155.balanceOf(borrower, 42), 0, "5: ERC1155 id 42 balance of borrower should be 0");
        assertEq(
            t1155.balanceOf(address(deployment.simpleLoan), 42),
            COLLATERAL_AMOUNT,
            "6: ERC1155 id 42 balance of loan contract should be COLLATERAL_AMOUNT"
        );

        assertEq(
            deployment.revokedNonce.isNonceRevoked(lender, proposal.nonceSpace, proposal.nonce),
            true,
            "7: nonce for lender should not be revoked for partial lending (revoked == true)"
        );
        assertEq(
            deployment.loanToken.loanContract(loanId),
            address(deployment.simpleLoan),
            "8: loan contract should be mapped to loanId"
        );

        assertEq(
            deployment.sdex.balanceOf(address(deployment.sink)),
            deployment.config.unlistedFee(),
            "9: sink should contain the sdex unlisted fee"
        );
    }
}
