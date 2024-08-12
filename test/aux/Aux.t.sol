// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import {Fuzzers} from "test/aux/utils/Fuzzers.sol";

import {MultiToken} from "MultiToken/MultiToken.sol";
import {T20} from "test/helper/T20.sol";
import {T721} from "test/helper/T721.sol";
import {T1155} from "test/helper/T1155.sol";

import {
    SDDeploymentTest,
    SDConfig,
    IPWNDeployer,
    PWNHub,
    PWNHubTags,
    SDSimpleLoan,
    SDSimpleLoanSimpleProposal,
    PWNLOAN,
    PWNRevokedNonce,
    MultiTokenCategoryRegistry
} from "test/SDDeploymentTest.t.sol";

contract AuxTest is Fuzzers, SDDeploymentTest {
    // Tokens
    T20 t20;
    T721 t721;
    T1155 t1155;
    T20 credit;

    // Lender/Borrower
    uint256 lenderPK = uint256(777);
    address lender = vm.addr(lenderPK);
    uint256 borrowerPK = uint256(888);
    address borrower = vm.addr(borrowerPK);

    // Nonce
    uint256 nonce_;
    uint256 createLoanNonce;

    // Refinancing loan id
    uint256 refinancingLoanId_;

    function setUp() public override {
        super.setUp();

        // Deploy tokens
        t20 = new T20();
        t721 = new T721();
        t1155 = new T1155();
        credit = new T20();

        // Labels
        vm.label(address(t20), "t20");
        vm.label(address(t721), "t721");
        vm.label(address(t1155), "t1155");
        vm.label(address(credit), "credit");
        vm.label(lender, "lender");
        vm.label(borrower, "borrower");

        // Mint and Approve sdex
        deployment.sdex.mint(lender, type(uint256).max);
        vm.prank(lender);
        deployment.sdex.approve(address(deployment.simpleLoan), type(uint256).max);
    }

    // Tests: fuzzed proposal creation + create loan (for unlisted credit token)
    function testFuzz_createERC20Loan_UnlistedCredit(uint256) external {
        SDSimpleLoanSimpleProposal.Proposal memory p = _createNewERC20Proposal(0, false);
        uint256 loanId = _createLOAN(p, "");
        _assertStateAfterLoanCreation(loanId, p);
    }

    function testFuzz_createERC721Loan_UnlistedCredit(uint256) external {
        SDSimpleLoanSimpleProposal.Proposal memory p = _createNewERC721Proposal(0, false);
        uint256 loanId = _createLOAN(p, "");
        _assertStateAfterLoanCreation(loanId, p);
    }

    function testFuzz_createERC1155Loan_UnlistedCredit(uint256) external {
        SDSimpleLoanSimpleProposal.Proposal memory p = _createNewERC1155Proposal(0, false);
        uint256 loanId = _createLOAN(p, "");
        _assertStateAfterLoanCreation(loanId, p);
    }

    // Tests: fuzzed proposal creation + create loan (for listed credit token)
    function testFuzz_createERC20Loan_ListedCredit(uint256 factor) external {
        factor = bound(factor, 1e13, 1e26);

        SDSimpleLoanSimpleProposal.Proposal memory p = _createNewERC20Proposal(0, false);

        // Call config.setListedToken from admin address
        vm.prank(deployment.protocolAdmin);
        deployment.config.setListedToken(p.creditAddress, factor);

        uint256 loanId = _createLOAN(p, "");
        _assertStateAfterLoanCreation(loanId, p);
    }

    function testFuzz_createERC721Loan_ListedCredit(uint256 factor) external {
        factor = bound(factor, 1e13, 1e26);

        SDSimpleLoanSimpleProposal.Proposal memory p = _createNewERC721Proposal(0, false);

        // Call config.setListedToken from admin address
        vm.prank(deployment.protocolAdmin);
        deployment.config.setListedToken(p.creditAddress, factor);

        uint256 loanId = _createLOAN(p, "");
        _assertStateAfterLoanCreation(loanId, p);
    }

    function testFuzz_createERC1155Loan_ListedCredit(uint256 factor) external {
        factor = bound(factor, 1e13, 1e26);

        SDSimpleLoanSimpleProposal.Proposal memory p = _createNewERC1155Proposal(0, false);

        // Call config.setListedToken from admin address
        vm.prank(deployment.protocolAdmin);
        deployment.config.setListedToken(p.creditAddress, factor);

        uint256 loanId = _createLOAN(p, "");
        _assertStateAfterLoanCreation(loanId, p);
    }

    // Tests: cancel an unaccepted order before the expiration via `revokeNonce`

    function testFuzz_shouldFail_cancelAnUnacceptedOrderBeforeExpiration_ERC20Collateral(uint256) external {
        SDSimpleLoanSimpleProposal.Proposal memory p = _createNewERC20Proposal(0, false);

        // Revoke nonce in nonce space for the proposer
        vm.warp(p.expiration - 1);
        vm.prank(p.proposer);
        deployment.simpleLoanSimpleProposal.revokeNonce(p.nonceSpace, p.nonce);

        bytes memory revertData =
            abi.encodeWithSelector(PWNRevokedNonce.NonceNotUsable.selector, p.proposer, p.nonceSpace, p.nonce);

        _createLOAN(p, revertData);
    }

    function testFuzz_shouldFail_cancelAnUnacceptedOrderBeforeExpiration_ERC721Collateral(uint256) external {
        SDSimpleLoanSimpleProposal.Proposal memory p = _createNewERC721Proposal(0, false);

        // Revoke nonce in nonce space for the proposer
        vm.warp(p.expiration - 1);
        vm.prank(p.proposer);
        deployment.simpleLoanSimpleProposal.revokeNonce(p.nonceSpace, p.nonce);

        bytes memory revertData =
            abi.encodeWithSelector(PWNRevokedNonce.NonceNotUsable.selector, p.proposer, p.nonceSpace, p.nonce);

        _createLOAN(p, revertData);
    }

    function testFuzz_shouldFail_cancelAnUnacceptedOrderBeforeExpiration_ERC1155Collateral(uint256) external {
        SDSimpleLoanSimpleProposal.Proposal memory p = _createNewERC1155Proposal(0, false);

        // Revoke nonce in nonce space for the proposer
        vm.warp(p.expiration - 1);
        vm.prank(p.proposer);
        deployment.simpleLoanSimpleProposal.revokeNonce(p.nonceSpace, p.nonce);

        bytes memory revertData =
            abi.encodeWithSelector(PWNRevokedNonce.NonceNotUsable.selector, p.proposer, p.nonceSpace, p.nonce);

        _createLOAN(p, revertData);
    }

    // Tests: cancel the unaccepted part of a partially accepted order

    function testFuzz_shouldFail_cancelUnacceptedPortionOfAPartiallyAcceptedProposal_ERC20Collateral(
        uint256 minAvailableCreditLimit
    ) external {
        minAvailableCreditLimit = bound(minAvailableCreditLimit, 1e18, type(uint128).max - 1); // @note to avoid min > max

        // availableCreditLimit != 0 && nonces remain usable after first loan creation
        SDSimpleLoanSimpleProposal.Proposal memory p = _createNewERC20Proposal(minAvailableCreditLimit, true);
        uint256 loanId = _createLOAN(p, "");

        _assertStateAfterLoanCreation(loanId, p);
        assertEq(deployment.revokedNonce.isNonceUsable(p.proposer, p.nonceSpace, p.nonce), true); // Nonce should still be usable
        assertEq(
            deployment.simpleLoanSimpleProposal.creditUsed(deployment.simpleLoanSimpleProposal.getProposalHash(p)),
            p.creditAmount
        ); // creditUsed for this proposal should be updated to creditAmount

        vm.prank(p.proposer);
        deployment.simpleLoanSimpleProposal.revokeNonce(p.nonceSpace, p.nonce);

        bytes memory revertData =
            abi.encodeWithSelector(PWNRevokedNonce.NonceNotUsable.selector, p.proposer, p.nonceSpace, p.nonce);

        _createLOAN(p, revertData);
    }

    function testFuzz_shouldFail_cancelUnacceptedPortionOfAPartiallyAcceptedProposal_ERC721Collateral(
        uint256 minAvailableCreditLimit
    ) external {
        minAvailableCreditLimit = bound(minAvailableCreditLimit, 1e18, type(uint128).max - 1);

        // availableCreditLimit != 0 && nonces remain usable
        SDSimpleLoanSimpleProposal.Proposal memory p = _createNewERC721Proposal(minAvailableCreditLimit, true);
        _createLOAN(p, "");

        assertEq(deployment.revokedNonce.isNonceUsable(p.proposer, p.nonceSpace, p.nonce), true); // Nonce should still be usable
        assertEq(
            deployment.simpleLoanSimpleProposal.creditUsed(deployment.simpleLoanSimpleProposal.getProposalHash(p)),
            p.creditAmount
        ); // creditUsed for this proposal should be updated to creditAmount

        vm.prank(p.proposer);
        deployment.simpleLoanSimpleProposal.revokeNonce(p.nonceSpace, p.nonce);

        bytes memory revertData =
            abi.encodeWithSelector(PWNRevokedNonce.NonceNotUsable.selector, p.proposer, p.nonceSpace, p.nonce);

        _createLOAN(p, revertData);
    }

    function testFuzz_shouldFail_cancelUnacceptedPortionOfAPartiallyAcceptedProposal_ERC1155Collateral(
        uint256 minAvailableCreditLimit
    ) external {
        minAvailableCreditLimit = bound(minAvailableCreditLimit, 1e18, type(uint128).max - 1);

        // availableCreditLimit != 0 && nonces remain usable
        SDSimpleLoanSimpleProposal.Proposal memory p = _createNewERC1155Proposal(minAvailableCreditLimit, true);
        _createLOAN(p, "");

        assertEq(deployment.revokedNonce.isNonceUsable(p.proposer, p.nonceSpace, p.nonce), true); // Nonce should still be usable
        assertEq(
            deployment.simpleLoanSimpleProposal.creditUsed(deployment.simpleLoanSimpleProposal.getProposalHash(p)),
            p.creditAmount
        ); // creditUsed for this proposal should be updated to creditAmount

        vm.prank(p.proposer);
        deployment.simpleLoanSimpleProposal.revokeNonce(p.nonceSpace, p.nonce);

        bytes memory revertData =
            abi.encodeWithSelector(PWNRevokedNonce.NonceNotUsable.selector, p.proposer, p.nonceSpace, p.nonce);

        _createLOAN(p, revertData);
    }

    // Tests: repay a running loan (partial) when the unaccepted portion has been cancelled

    function testFuzz_shouldRepayRunningPartialLoan_unacceptedPortionCancelled_ERC20Collateral(
        uint256 minAvailableCreditLimit,
        uint256 timestamp
    ) external {
        minAvailableCreditLimit = bound(minAvailableCreditLimit, 1e18, type(uint128).max - 1);

        // availableCreditLimit != 0 && nonces remain usable
        SDSimpleLoanSimpleProposal.Proposal memory p = _createNewERC20Proposal(minAvailableCreditLimit, true);
        uint256 loanId = _createLOAN(p, "");

        // Proposer cancels the unaccepted portion
        vm.prank(p.proposer);
        deployment.simpleLoanSimpleProposal.revokeNonce(p.nonceSpace, p.nonce);

        // Warp sometime into the future, but less than the default timestamp
        timestamp = bound(timestamp, getBlockTimestamp() + 1, getBlockTimestamp() + p.duration - 1);
        vm.warp(timestamp);

        // Lender repays
        uint256 loanRepaymentAmount = deployment.simpleLoan.loanRepaymentAmount(loanId);
        credit.mint(borrower, loanRepaymentAmount);

        vm.startPrank(borrower);
        credit.approve(address(deployment.simpleLoan), loanRepaymentAmount);
        deployment.simpleLoan.repayLOAN(loanId, "");
        vm.stopPrank();

        // Assertions
        vm.expectRevert();
        deployment.loanToken.ownerOf(loanId); // token should be burned
        assertEq(credit.balanceOf(lender), loanRepaymentAmount);
        assertEq(t20.balanceOf(borrower), p.collateralAmount);
    }

    function testFuzz_shouldRepayRunningPartialLoan_unacceptedPortionCancelled_ERC721Collateral(
        uint256 minAvailableCreditLimit,
        uint256 timestamp
    ) external {
        minAvailableCreditLimit = bound(minAvailableCreditLimit, 1e18, type(uint128).max - 1);

        // availableCreditLimit != 0 && nonces remain usable
        SDSimpleLoanSimpleProposal.Proposal memory p = _createNewERC721Proposal(minAvailableCreditLimit, true);
        uint256 loanId = _createLOAN(p, "");

        // Proposer cancels the unaccepted portion
        vm.prank(p.proposer);
        deployment.simpleLoanSimpleProposal.revokeNonce(p.nonceSpace, p.nonce);

        // Warp sometime into the future, but less than the default timestamp
        timestamp = bound(timestamp, getBlockTimestamp() + 1, getBlockTimestamp() + p.duration - 1);
        vm.warp(timestamp);

        // Lender repays
        uint256 loanRepaymentAmount = deployment.simpleLoan.loanRepaymentAmount(loanId);
        credit.mint(borrower, loanRepaymentAmount);

        vm.startPrank(borrower);
        credit.approve(address(deployment.simpleLoan), loanRepaymentAmount);
        deployment.simpleLoan.repayLOAN(loanId, "");
        vm.stopPrank();

        // Assertions
        vm.expectRevert();
        deployment.loanToken.ownerOf(loanId); // token should be burned
        assertEq(credit.balanceOf(lender), loanRepaymentAmount);
        assertEq(t721.balanceOf(borrower), 1);
    }

    function testFuzz_shouldRepayRunningPartialLoan_unacceptedPortionCancelled_ERC1155Collateral(
        uint256 minAvailableCreditLimit,
        uint256 timestamp
    ) external {
        minAvailableCreditLimit = bound(minAvailableCreditLimit, 1e18, type(uint128).max - 1);

        // availableCreditLimit != 0 && nonces remain usable
        SDSimpleLoanSimpleProposal.Proposal memory p = _createNewERC1155Proposal(minAvailableCreditLimit, true);
        uint256 loanId = _createLOAN(p, "");

        // Proposer cancels the unaccepted portion
        vm.prank(p.proposer);
        deployment.simpleLoanSimpleProposal.revokeNonce(p.nonceSpace, p.nonce);

        // Warp sometime into the future, but less than the default timestamp
        timestamp = bound(timestamp, getBlockTimestamp() + 1, getBlockTimestamp() + p.duration - 1);
        vm.warp(timestamp);

        // Lender repays
        uint256 loanRepaymentAmount = deployment.simpleLoan.loanRepaymentAmount(loanId);
        credit.mint(borrower, loanRepaymentAmount);

        vm.startPrank(borrower);
        credit.approve(address(deployment.simpleLoan), loanRepaymentAmount);
        deployment.simpleLoan.repayLOAN(loanId, "");
        vm.stopPrank();

        // Assertions
        vm.expectRevert();
        deployment.loanToken.ownerOf(loanId); // token should be burned
        assertEq(credit.balanceOf(lender), loanRepaymentAmount);
        assertEq(t1155.balanceOf(borrower, p.collateralId), p.collateralAmount);
    }

    // Tests: refinancing loans

    function testFuzz_refinance_surplus(uint256 refinanceCreditAmount, uint256 timestamp) external {
        SDSimpleLoanSimpleProposal.Proposal memory p = _createNewERC20Proposal(0, false);
        uint256 loanId = _createLOAN(p, "");
        refinancingLoanId_ = loanId; // Set refinancingLoanId_ as loan created

        // Warp sometime into the future, but less than the default timestamp
        timestamp = bound(timestamp, getBlockTimestamp() + 1, getBlockTimestamp() + p.duration - 1);
        vm.warp(timestamp);

        // Setting up refinance (surplus)
        uint256 loanRepaymentAmount = deployment.simpleLoan.loanRepaymentAmount(loanId);
        vm.assume(refinanceCreditAmount > loanRepaymentAmount);
        p.creditAmount = refinanceCreditAmount;
        p.nonce = nonce_++;
        p.expiration = getBlockTimestamp() + 20 days;

        bytes memory signature = p.isOffer
            ? _sign(lenderPK, deployment.simpleLoanSimpleProposal.getProposalHash(p))
            : _sign(borrowerPK, deployment.simpleLoanSimpleProposal.getProposalHash(p));

        uint256 surplus = refinanceCreditAmount - loanRepaymentAmount;

        // Mint and approve surplus
        credit.mint(lender, surplus);
        vm.prank(lender);
        credit.approve(address(deployment.simpleLoan), type(uint256).max);

        bytes memory proposalData = deployment.simpleLoanSimpleProposal.encodeProposalData(p);

        uint256 id;
        if (p.isOffer) {
            vm.prank(borrower);
            id = deployment.simpleLoan.createLOAN({
                proposalSpec: SDSimpleLoan.ProposalSpec({
                    proposalContract: address(deployment.simpleLoanSimpleProposal),
                    proposalData: proposalData,
                    proposalInclusionProof: new bytes32[](0),
                    signature: signature
                }),
                lenderSpec: SDSimpleLoan.LenderSpec({sourceOfFunds: lender}),
                callerSpec: SDSimpleLoan.CallerSpec({
                    refinancingLoanId: refinancingLoanId_,
                    revokeNonce: false,
                    nonce: 0,
                    permitData: ""
                }),
                extra: ""
            });
        } else {
            vm.prank(lender);
            id = deployment.simpleLoan.createLOAN({
                proposalSpec: SDSimpleLoan.ProposalSpec({
                    proposalContract: address(deployment.simpleLoanSimpleProposal),
                    proposalData: proposalData,
                    proposalInclusionProof: new bytes32[](0),
                    signature: signature
                }),
                lenderSpec: SDSimpleLoan.LenderSpec({sourceOfFunds: lender}),
                callerSpec: SDSimpleLoan.CallerSpec({
                    refinancingLoanId: refinancingLoanId_,
                    revokeNonce: false,
                    nonce: 0,
                    permitData: ""
                }),
                extra: ""
            });
        }
    }

    function testFuzz_refinance_shortage(uint256 refinanceCreditAmount, uint256 timestamp) external {
        SDSimpleLoanSimpleProposal.Proposal memory p = _createNewERC20Proposal(0, false);
        uint256 loanId = _createLOAN(p, "");
        refinancingLoanId_ = loanId; // Set refinancingLoanId_ as loan created

        // Warp sometime into the future, but less than the default timestamp
        timestamp = bound(timestamp, getBlockTimestamp() + 1, getBlockTimestamp() + p.duration - 1);
        vm.warp(timestamp);

        // Setting up refinance (surplus)
        uint256 loanRepaymentAmount = deployment.simpleLoan.loanRepaymentAmount(loanId);
        refinanceCreditAmount = bound(refinanceCreditAmount, 1, loanRepaymentAmount);
        p.creditAmount = refinanceCreditAmount;
        p.nonce = nonce_++;
        p.expiration = getBlockTimestamp() + 20 days;

        bytes memory signature = p.isOffer
            ? _sign(lenderPK, deployment.simpleLoanSimpleProposal.getProposalHash(p))
            : _sign(borrowerPK, deployment.simpleLoanSimpleProposal.getProposalHash(p));

        uint256 shortage = loanRepaymentAmount - refinanceCreditAmount;

        // Mint and approve surplus (for borrower in case of shortage)
        credit.mint(borrower, shortage);
        vm.prank(borrower);
        credit.approve(address(deployment.simpleLoan), type(uint256).max);

        bytes memory proposalData = deployment.simpleLoanSimpleProposal.encodeProposalData(p);

        uint256 id;
        if (p.isOffer) {
            vm.prank(borrower);
            id = deployment.simpleLoan.createLOAN({
                proposalSpec: SDSimpleLoan.ProposalSpec({
                    proposalContract: address(deployment.simpleLoanSimpleProposal),
                    proposalData: proposalData,
                    proposalInclusionProof: new bytes32[](0),
                    signature: signature
                }),
                lenderSpec: SDSimpleLoan.LenderSpec({sourceOfFunds: lender}),
                callerSpec: SDSimpleLoan.CallerSpec({
                    refinancingLoanId: refinancingLoanId_,
                    revokeNonce: false,
                    nonce: 0,
                    permitData: ""
                }),
                extra: ""
            });
        } else {
            vm.prank(lender);
            id = deployment.simpleLoan.createLOAN({
                proposalSpec: SDSimpleLoan.ProposalSpec({
                    proposalContract: address(deployment.simpleLoanSimpleProposal),
                    proposalData: proposalData,
                    proposalInclusionProof: new bytes32[](0),
                    signature: signature
                }),
                lenderSpec: SDSimpleLoan.LenderSpec({sourceOfFunds: lender}),
                callerSpec: SDSimpleLoan.CallerSpec({
                    refinancingLoanId: refinancingLoanId_,
                    revokeNonce: false,
                    nonce: 0,
                    permitData: ""
                }),
                extra: ""
            });
        }
    }

    // Helpers

    function _sign(uint256 pk, bytes32 digest) internal pure returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, digest);
        return abi.encodePacked(r, s, v);
    }

    function _createLOAN(SDSimpleLoanSimpleProposal.Proposal memory p, bytes memory revertData)
        internal
        returns (uint256)
    {
        if (createLoanNonce++ == 0) {
            // Mint initial state and set approvals for the borrower
            if (p.collateralCategory == MultiToken.Category.ERC20) {
                t20.mint(borrower, p.collateralAmount);
                vm.prank(borrower);
                t20.approve(address(deployment.simpleLoan), type(uint256).max);
            } else if (p.collateralCategory == MultiToken.Category.ERC721) {
                t721.mint(borrower, p.collateralId);
                vm.prank(borrower);
                t721.approve(address(deployment.simpleLoan), p.collateralId);
            } else if (p.collateralCategory == MultiToken.Category.ERC1155) {
                t1155.mint(borrower, p.collateralId, p.collateralAmount);
                vm.prank(borrower);
                t1155.setApprovalForAll(address(deployment.simpleLoan), true);
            }
        }

        // Sign proposal
        bytes memory signature = p.isOffer
            ? _sign(lenderPK, deployment.simpleLoanSimpleProposal.getProposalHash(p))
            : _sign(borrowerPK, deployment.simpleLoanSimpleProposal.getProposalHash(p));

        // Mint initial state
        credit.mint(lender, p.creditAmount);

        // Approve loan asset
        vm.prank(lender);
        credit.approve(address(deployment.simpleLoan), p.creditAmount);

        // Proposal data (need for vm.prank to work properly when creating a loan)
        bytes memory proposalData = deployment.simpleLoanSimpleProposal.encodeProposalData(p);

        if (keccak256(revertData) != keccak256("")) {
            vm.expectRevert(revertData);
        }

        // Create LOAN
        if (p.isOffer) {
            vm.prank(borrower);
            return deployment.simpleLoan.createLOAN({
                proposalSpec: SDSimpleLoan.ProposalSpec({
                    proposalContract: address(deployment.simpleLoanSimpleProposal),
                    proposalData: proposalData,
                    proposalInclusionProof: new bytes32[](0),
                    signature: signature
                }),
                lenderSpec: SDSimpleLoan.LenderSpec({sourceOfFunds: lender}),
                callerSpec: SDSimpleLoan.CallerSpec({
                    refinancingLoanId: refinancingLoanId_,
                    revokeNonce: false,
                    nonce: 0,
                    permitData: ""
                }),
                extra: ""
            });
        } else {
            vm.prank(lender);
            return deployment.simpleLoan.createLOAN({
                proposalSpec: SDSimpleLoan.ProposalSpec({
                    proposalContract: address(deployment.simpleLoanSimpleProposal),
                    proposalData: proposalData,
                    proposalInclusionProof: new bytes32[](0),
                    signature: signature
                }),
                lenderSpec: SDSimpleLoan.LenderSpec({sourceOfFunds: lender}),
                callerSpec: SDSimpleLoan.CallerSpec({
                    refinancingLoanId: refinancingLoanId_,
                    revokeNonce: false,
                    nonce: 0,
                    permitData: ""
                }),
                extra: ""
            });
        }
    }

    function _createNewERC20Proposal(uint256 minAvailableCreditLimit, bool isBelowThreshold)
        internal
        returns (SDSimpleLoanSimpleProposal.Proposal memory p)
    {
        p.collateralCategory = MultiToken.Category.ERC20;
        p.collateralAddress = address(t20);
        p.creditAddress = address(credit);
        p.loanContract = address(deployment.simpleLoan);
        p = fuzzProposal(p, minAvailableCreditLimit, isBelowThreshold);
        p.allowedAcceptor = p.isOffer ? borrower : address(0);
        p.proposer = p.isOffer ? lender : borrower;
        p.proposerSpecHash = deployment.simpleLoan.getLenderSpecHash(SDSimpleLoan.LenderSpec(p.proposer));
        p.nonce = nonce_++;
    }

    function _createNewERC721Proposal(uint256 minAvailableCreditLimit, bool isBelowThreshold)
        internal
        returns (SDSimpleLoanSimpleProposal.Proposal memory p)
    {
        p.collateralCategory = MultiToken.Category.ERC721;
        p.collateralAddress = address(t721);
        p.creditAddress = address(credit);
        p.loanContract = address(deployment.simpleLoan);
        p = fuzzProposal(p, minAvailableCreditLimit, isBelowThreshold);
        p.allowedAcceptor = p.isOffer ? borrower : address(0);
        p.proposer = p.isOffer ? lender : borrower;
        p.proposerSpecHash = deployment.simpleLoan.getLenderSpecHash(SDSimpleLoan.LenderSpec(p.proposer));
        p.nonce = nonce_++;
    }

    function _createNewERC1155Proposal(uint256 minAvailableCreditLimit, bool isBelowThreshold)
        internal
        returns (SDSimpleLoanSimpleProposal.Proposal memory p)
    {
        p.collateralCategory = MultiToken.Category.ERC1155;
        p.collateralAddress = address(t1155);
        p.creditAddress = address(credit);
        p.loanContract = address(deployment.simpleLoan);
        p = fuzzProposal(p, minAvailableCreditLimit, isBelowThreshold);
        p.allowedAcceptor = p.isOffer ? borrower : address(0);
        p.proposer = p.isOffer ? lender : borrower;
        p.proposerSpecHash = deployment.simpleLoan.getLenderSpecHash(SDSimpleLoan.LenderSpec(p.proposer));
        p.nonce = nonce_++;
    }

    function _assertStateAfterLoanCreation(uint256 _loanId, SDSimpleLoanSimpleProposal.Proposal memory p)
        internal
        view
    {
        assertEq(deployment.loanToken.ownerOf(_loanId), lender, "0: loanToken owner should be lender");
        assertEq(credit.balanceOf(lender), 0, "1: credit token balance of lender should be 0"); // @note minted on an 'as needed' basis and loaned out
        assertEq(
            credit.balanceOf(borrower), p.creditAmount, "2: credit token balance of borrower should be CREDIT_AMOUNT"
        );
        assertEq(
            credit.balanceOf(address(deployment.simpleLoan)), 0, "3: credit token balance of loan contract should be 0"
        );
        if (p.collateralCategory == MultiToken.Category.ERC20) {
            assertEq(t20.balanceOf(lender), 0, "4: ERC20 balance of lender should be 0");
            assertEq(t20.balanceOf(borrower), 0, "5: ERC20 balance of borrower should be 0");
            assertEq(
                t20.balanceOf(address(deployment.simpleLoan)),
                p.collateralAmount,
                "6: ERC20 balance of loan contract should be p.collateralAmount"
            );
        } else if (p.collateralCategory == MultiToken.Category.ERC721) {
            assertEq(t721.balanceOf(lender), 0, "4: ERC721 balance of lender should be 0");
            assertEq(t721.balanceOf(borrower), 0, "5: ERC721 balance of borrower should be 0");
            assertEq(
                t721.balanceOf(address(deployment.simpleLoan)), 1, "6: ERC721 balance of loan contract should be 1"
            );
        } else if (p.collateralCategory == MultiToken.Category.ERC1155) {
            assertEq(t1155.balanceOf(lender, p.collateralId), 0, "4: ERC1155 balance of lender should be 0");
            assertEq(t1155.balanceOf(borrower, p.collateralId), 0, "5: ERC1155 balance of borrower should be 0");
            assertEq(
                t1155.balanceOf(address(deployment.simpleLoan), p.collateralId),
                p.collateralAmount,
                "6: ERC1155 balance of loan contract should be p.collateralAmount"
            );
        }
        if (p.availableCreditLimit == 0) {
            assertEq(
                deployment.revokedNonce.isNonceRevoked(lender, p.nonceSpace, p.nonce),
                true,
                "7: nonce for lender should be revoked for partial lending (revoked == true)"
            );
        } else {
            assertEq(
                deployment.revokedNonce.isNonceRevoked(lender, p.nonceSpace, p.nonce),
                false,
                "7: nonce for lender should not be revoked for partial lending (revoked == true)"
            );
        }
        assertEq(
            deployment.loanToken.loanContract(_loanId),
            address(deployment.simpleLoan),
            "8: loan contract should be mapped to loanId"
        );
        if (deployment.config.tokenFactors(p.creditAddress) == 0) {
            assertEq(
                deployment.sdex.balanceOf(address(deployment.sink)),
                deployment.config.unlistedFee(),
                "9: sink should contain the sdex unlisted fee"
            );
        } else {
            uint256 expectedFee = deployment.config.listedFee()
                + (
                    ((deployment.config.variableFactor() * deployment.config.tokenFactors(p.creditAddress)) / 1e18)
                        * p.creditAmount
                ) / 1e18;
            assertEq(
                deployment.sdex.balanceOf(address(deployment.sink)),
                expectedFee,
                "9: sink should contain the sdex unlisted fee"
            );
        }
    }
}
