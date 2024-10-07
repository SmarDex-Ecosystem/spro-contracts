// // SPDX-License-Identifier: GPL-3.0-only
// pragma solidity ^0.8.26;

// import {
//     SDBaseIntegrationTest,
//     Spro,
//     IPWNDeployer,
//     PWNLOAN,
//     PWNRevokedNonce
// } from "test/integration/SDBaseIntegrationTest.t.sol";

// import { ISproTypes } from "src/interfaces/ISproTypes.sol";
// import { ISproErrors } from "src/interfaces/ISproErrors.sol";

// contract AcceptProposal_SDSimpleLoanSimpleProposal_Integration_Concrete_Test is SDBaseIntegrationTest {
//     function test_RevertWhen_DataCannotBeDecoded() external {
//         bytes memory badData = abi.encode("cannot be decoded");

//         vm.expectRevert();
//         deployment.config.acceptProposal(lender, CREDIT_AMOUNT, badData);

//         bytes memory baseProposalData = abi.encode(
//             ISproTypes.ProposalBase({
//                 collateralAddress: address(t20),
//                 checkCollateralStateFingerprint: false,
//                 collateralStateFingerprint: bytes32(0),
//                 availableCreditLimit: CREDIT_LIMIT,
//                 startTimestamp: uint40(block.timestamp + 5 days),
//                 proposer: borrower,
//                 nonceSpace: 0,
//                 nonce: 0,
//                 loanContract: address(deployment.simpleLoan)
//             })
//         );

//         vm.expectRevert();
//         deployment.simpleLoanSimpleProposal.makeProposal(baseProposalData);
//     }

//     modifier whenProposalDataDecodes() {
//         _;
//     }

//     modifier loanContractIsCaller() {
//         _;
//     }

//     modifier loanContractHasHubTag() {
//         _;
//     }

//     function test_RevertWhen_ProposalNotMade()
//         external
//         whenProposalDataDecodes
//         loanContractIsCaller
//         loanContractHasHubTag
//     {
//         vm.prank(proposal.loanContract);
//         vm.expectRevert(ISproErrors.ProposalNotMade.selector);
//         deployment.simpleLoanSimpleProposal.acceptProposal(lender, CREDIT_AMOUNT, abi.encode(proposal));
//     }

//     modifier whenProposalMade() {
//         _;
//     }

//     function test_RevertWhen_AcceptorIsProposer()
//         external
//         whenProposalDataDecodes
//         loanContractIsCaller
//         loanContractHasHubTag
//         whenProposalMade
//     {
//         _createERC20Proposal();

//         vm.prank(proposal.loanContract);
//         vm.expectRevert(abi.encodeWithSelector(ISproErrors.AcceptorIsProposer.selector, borrower));
//         deployment.simpleLoanSimpleProposal.acceptProposal(borrower, CREDIT_AMOUNT, abi.encode(proposal));
//     }

//     modifier whenAcceptorNotProposer() {
//         _;
//     }

//     function test_RevertWhen_ProposalExpired()
//         external
//         whenProposalDataDecodes
//         loanContractIsCaller
//         loanContractHasHubTag
//         whenProposalMade
//         whenAcceptorNotProposer
//     {
//         _createERC20Proposal();

//         vm.warp(proposal.startTimestamp);

//         vm.prank(proposal.loanContract);
//         vm.expectRevert(abi.encodeWithSelector(ISproErrors.Expired.selector, block.timestamp,
// proposal.startTimestamp));
//         deployment.simpleLoanSimpleProposal.acceptProposal(lender, CREDIT_AMOUNT, abi.encode(proposal));
//     }

//     modifier whenProposalNotExpired() {
//         _;
//     }

//     function test_RevertWhen_NonceNotUsable()
//         external
//         whenProposalDataDecodes
//         loanContractIsCaller
//         loanContractHasHubTag
//         whenProposalMade
//         whenAcceptorNotProposer
//         whenProposalNotExpired
//     {
//         _createERC20Proposal();

//         vm.prank(proposal.proposer);
//         deployment.simpleLoanSimpleProposal.revokeNonce(proposal.nonceSpace, proposal.nonce);

//         vm.prank(proposal.loanContract);
//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 PWNRevokedNonce.NonceNotUsable.selector, borrower, proposal.nonceSpace, proposal.nonce
//             )
//         );
//         deployment.simpleLoanSimpleProposal.acceptProposal(lender, CREDIT_AMOUNT, abi.encode(proposal));
//     }

//     modifier whenNonceUsable() {
//         _;
//     }

//     function test_RevertWhen_ZeroCreditLimit()
//         external
//         whenProposalDataDecodes
//         loanContractIsCaller
//         loanContractHasHubTag
//         whenProposalMade
//         whenAcceptorNotProposer
//         whenProposalNotExpired
//         whenNonceUsable
//     {
//         proposal.availableCreditLimit = 0;
//         _createERC20Proposal();

//         vm.prank(proposal.loanContract);
//         vm.expectRevert(abi.encodeWithSelector(ISproErrors.AvailableCreditLimitZero.selector));
//         deployment.simpleLoanSimpleProposal.acceptProposal(lender, CREDIT_AMOUNT, abi.encode(proposal));
//     }

//     modifier whenCreditLimitGtZero() {
//         _;
//     }

//     function test_RevertWhen_CreditUsedAndAmountGtLimit()
//         external
//         whenProposalDataDecodes
//         loanContractIsCaller
//         loanContractHasHubTag
//         whenProposalMade
//         whenAcceptorNotProposer
//         whenProposalNotExpired
//         whenNonceUsable
//         whenCreditLimitGtZero
//     {
//         bytes32 proposalHash = deployment.simpleLoanSimpleProposal.getProposalHash(proposal);
//         uint256 creditUsedValue = 55e18;

//         vm.store(
//             address(deployment.simpleLoanSimpleProposal),
//             keccak256(abi.encode(proposalHash, SLOT_CREDIT_USED)),
//             bytes32(creditUsedValue)
//         );

//         _createERC20Proposal();

//         vm.prank(proposal.loanContract);
//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 ISproErrors.AvailableCreditLimitExceeded.selector, creditUsedValue + CREDIT_AMOUNT, CREDIT_LIMIT
//             )
//         );
//         deployment.simpleLoanSimpleProposal.acceptProposal(lender, CREDIT_AMOUNT, abi.encode(proposal));
//     }

//     modifier whenCreditUsedAndAmountBelowLimit() {
//         _;
//     }

//     function test_RevertWhen_CreditAmountBelowMinimum()
//         external
//         whenProposalDataDecodes
//         loanContractIsCaller
//         loanContractHasHubTag
//         whenProposalMade
//         whenAcceptorNotProposer
//         whenProposalNotExpired
//         whenNonceUsable
//         whenCreditLimitGtZero
//         whenCreditUsedAndAmountBelowLimit
//     {
//         _createERC20Proposal();

//         vm.prank(proposal.loanContract);
//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 ISproErrors.CreditAmountTooSmall.selector, 1, (proposal.availableCreditLimit * 500) / 1e4
//             )
//         );
//         deployment.simpleLoanSimpleProposal.acceptProposal(lender, 1, abi.encode(proposal));
//     }

//     modifier whenCreditAmountAboveMinimum() {
//         _;
//     }

//     function test_AcceptProposal_IncrementCreditUsed()
//         external
//         whenProposalDataDecodes
//         loanContractIsCaller
//         loanContractHasHubTag
//         whenProposalMade
//         whenAcceptorNotProposer
//         whenProposalNotExpired
//         whenNonceUsable
//         whenCreditLimitGtZero
//         whenCreditUsedAndAmountBelowLimit
//         whenCreditAmountAboveMinimum
//     {
//         _createERC20Proposal();

//         bytes32 proposalHash = deployment.simpleLoanSimpleProposal.getProposalHash(proposal);
//         bytes32 slot = keccak256(abi.encode(proposalHash, SLOT_CREDIT_USED));

//         uint256 creditUsed = uint256(vm.load(address(deployment.simpleLoanSimpleProposal), slot));
//         assertEq(creditUsed, 0, "credit used before accept proposal");

//         vm.prank(proposal.loanContract);
//         deployment.simpleLoanSimpleProposal.acceptProposal(lender, CREDIT_AMOUNT, abi.encode(proposal));

//         creditUsed = uint256(vm.load(address(deployment.simpleLoanSimpleProposal), slot));
//         assertEq(creditUsed, CREDIT_AMOUNT, "credit used after accept proposal");
//     }

//     function test_AcceptProposal_CreditUsedAboveThreshold()
//         external
//         whenProposalDataDecodes
//         loanContractIsCaller
//         loanContractHasHubTag
//         whenProposalMade
//         whenAcceptorNotProposer
//         whenProposalNotExpired
//         whenNonceUsable
//         whenCreditLimitGtZero
//         whenCreditUsedAndAmountBelowLimit
//         whenCreditAmountAboveMinimum
//     {
//         _createERC20Proposal();

//         vm.prank(proposal.loanContract);
//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 ISproErrors.CreditAmountLeavesTooLittle.selector,
//                 (CREDIT_LIMIT * 9501) / 1e4,
//                 (PERCENTAGE - DEFAULT_THRESHOLD) * CREDIT_LIMIT / 1e4
//             )
//         );
//         deployment.simpleLoanSimpleProposal.acceptProposal(lender, (CREDIT_LIMIT * 9501) / 1e4,
// abi.encode(proposal));

//         assertEq(
//             deployment.revokedNonce.isNonceUsable(borrower, proposal.nonceSpace, proposal.nonce),
//             true,
//             "nonce should still be usable"
//         );
//     }

//     modifier whenNoFingerprintChecks() {
//         _;
//     }

//     function test_AcceptProposal_LoanTermsCorrectness()
//         external
//         whenProposalDataDecodes
//         loanContractIsCaller
//         loanContractHasHubTag
//         whenProposalMade
//         whenAcceptorNotProposer
//         whenProposalNotExpired
//         whenNonceUsable
//         whenCreditLimitGtZero
//         whenCreditUsedAndAmountBelowLimit
//         whenCreditAmountAboveMinimum
//         whenNoFingerprintChecks
//     {
//         _createERC20Proposal();

//         vm.prank(proposal.loanContract);
//         (, Spro.Terms memory loanTerms) =
//             deployment.simpleLoanSimpleProposal.acceptProposal(lender, CREDIT_AMOUNT, abi.encode(proposal));

//         uint256 collateralUsed = (CREDIT_AMOUNT * COLLATERAL_AMOUNT) / CREDIT_LIMIT;
//         assertEq(loanTerms.collateralAmount, collateralUsed, "collateral amount != collateralUsed");
//         assertEq(loanTerms.creditAmount, CREDIT_AMOUNT, "credit amount incorrect");
//     }

//     modifier whenERC20Collateral() {
//         _;
//     }

//     modifier whenERC721Collateral() {
//         _;
//     }

//     modifier whenFungibleERC1155Collateral() {
//         _;
//     }

//     modifier whenNonFungibleERC1155Collateral() {
//         _;
//     }

//     function test_AcceptProposal_Partial_ERC20()
//         external
//         whenProposalDataDecodes
//         loanContractIsCaller
//         loanContractHasHubTag
//         whenProposalMade
//         whenAcceptorNotProposer
//         whenProposalNotExpired
//         whenNonceUsable
//         whenCreditLimitGtZero
//         whenCreditUsedAndAmountBelowLimit
//         whenCreditAmountAboveMinimum
//         whenNoFingerprintChecks
//         whenERC20Collateral
//     {
//         _createERC20Proposal();

//         bytes32 proposalHash = deployment.simpleLoanSimpleProposal.getProposalHash(proposal);
//         bytes32 slot = keccak256(abi.encode(proposalHash, SLOT_WITHDRAWABLE_COLLATERAL));
//         bytes32 wc = vm.load(address(deployment.simpleLoanSimpleProposal), slot);
//         assertEq(
//             uint256(vm.load(address(deployment.simpleLoanSimpleProposal), bytes32(uint256(slot)))),
//             proposal.collateralAmount,
//             "withdrawableCollateral: collateral amount not set"
//         );

//         vm.expectCall({
//             callee: address(deployment.config),
//             data: abi.encodeWithSignature("getStateFingerprintComputer(address)"),
//             count: 0
//         });
//         vm.prank(proposal.loanContract);
//         deployment.simpleLoanSimpleProposal.acceptProposal(lender, CREDIT_AMOUNT, abi.encode(proposal));

//         wc = vm.load(address(deployment.simpleLoanSimpleProposal), slot);
//         assertEq(
//             uint256(vm.load(address(deployment.simpleLoanSimpleProposal), bytes32(uint256(slot)))),
//             proposal.collateralAmount - ((CREDIT_AMOUNT * COLLATERAL_AMOUNT) / CREDIT_LIMIT),
//             "withdrawableCollateral: collateral amount decremented correctly"
//         );
//     }

//     function test_AcceptProposal_Complete_ERC20()
//         external
//         whenProposalDataDecodes
//         loanContractIsCaller
//         loanContractHasHubTag
//         whenProposalMade
//         whenAcceptorNotProposer
//         whenProposalNotExpired
//         whenNonceUsable
//         whenCreditLimitGtZero
//         whenCreditUsedAndAmountBelowLimit
//         whenCreditAmountAboveMinimum
//         whenNoFingerprintChecks
//         whenERC20Collateral
//     {
//         _createERC20Proposal();

//         bytes32 proposalHash = deployment.simpleLoanSimpleProposal.getProposalHash(proposal);
//         bytes32 slot = keccak256(abi.encode(proposalHash, SLOT_WITHDRAWABLE_COLLATERAL));
//         assertEq(
//             uint256(vm.load(address(deployment.simpleLoanSimpleProposal), bytes32(uint256(slot)))),
//             proposal.collateralAmount,
//             "withdrawableCollateral: collateral amount not set"
//         );

//         vm.expectCall({
//             callee: address(deployment.config),
//             data: abi.encodeWithSignature("getStateFingerprintComputer(address)"),
//             count: 0
//         });
//         vm.prank(proposal.loanContract);
//         deployment.simpleLoanSimpleProposal.acceptProposal(lender, CREDIT_LIMIT, abi.encode(proposal));

//         assertEq(
//             uint256(vm.load(address(deployment.simpleLoanSimpleProposal), bytes32(uint256(slot)))),
//             0,
//             "withdrawableCollateral: collateral amount decremented correctly"
//         );
//     }

//     modifier whenValidInputsAndCallers() {
//         _;
//     }

//     modifier whenStateFingerprintChecks() {
//         _;
//     }

//     function test_shouldPass_whenComputerReturnsMatchingFingerprint()
//         external
//         whenValidInputsAndCallers
//         whenStateFingerprintChecks
//     {
//         proposal.checkCollateralStateFingerprint = true;
//         proposal.collateralStateFingerprint = collateralStateFingerprint;

//         _createERC20Proposal();

//         bytes32 proposalHash = deployment.simpleLoanSimpleProposal.getProposalHash(proposal);
//         bytes32 slot = keccak256(abi.encode(proposalHash, SLOT_WITHDRAWABLE_COLLATERAL));
//         assertEq(
//             uint256(vm.load(address(deployment.simpleLoanSimpleProposal), bytes32(uint256(slot)))),
//             proposal.collateralAmount,
//             "withdrawableCollateral: collateral amount not set"
//         );

//         vm.expectCall(
//             address(deployment.config),
//             abi.encodeWithSignature("getStateFingerprintComputer(address)", proposal.collateralAddress)
//         );
//         vm.prank(proposal.loanContract);
//         deployment.simpleLoanSimpleProposal.acceptProposal(lender, CREDIT_LIMIT, abi.encode(proposal));

//         assertEq(
//             uint256(vm.load(address(deployment.simpleLoanSimpleProposal), bytes32(uint256(slot)))),
//             0,
//             "withdrawableCollateral: collateral amount decremented correctly"
//         );
//     }

//     function testFuzz_shouldFail_whenComputerReturnsDifferentStateFingerprint(bytes32 stateFp)
//         external
//         whenValidInputsAndCallers
//         whenStateFingerprintChecks
//     {
//         proposal.checkCollateralStateFingerprint = true;
//         proposal.collateralStateFingerprint = collateralStateFingerprint;
//         _createERC20Proposal();

//         vm.assume(stateFp != collateralStateFingerprint);
//         vm.mockCall(
//             stateFingerprintComputer,
//             abi.encodeWithSignature("computeStateFingerprint(address,uint256)", proposal.collateralAddress),
//             abi.encode(stateFp)
//         );
//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 ISproErrors.InvalidCollateralStateFingerprint.selector, stateFp, collateralStateFingerprint
//             )
//         );

//         vm.prank(proposal.loanContract);
//         deployment.simpleLoanSimpleProposal.acceptProposal(lender, CREDIT_LIMIT, abi.encode(proposal));
//     }

//     function test_shouldFail_whenNoComputerRegistered_whenAssetDoesNotImplementERC165()
//         external
//         whenValidInputsAndCallers
//         whenStateFingerprintChecks
//     {
//         proposal.checkCollateralStateFingerprint = true;
//         proposal.collateralStateFingerprint = collateralStateFingerprint;
//         _createERC20Proposal();

//         vm.mockCall(
//             address(deployment.config),
//             abi.encodeWithSignature("getStateFingerprintComputer(address)"),
//             abi.encode(address(0))
//         );
//         vm.mockCallRevert(
//             proposal.collateralAddress,
//             abi.encodeWithSignature("supportsInterface(bytes4)"),
//             abi.encode("not implementing ERC165")
//         );

//         vm.expectRevert(abi.encodeWithSelector(ISproErrors.MissingStateFingerprintComputer.selector));
//         vm.prank(proposal.loanContract);
//         deployment.simpleLoanSimpleProposal.acceptProposal(lender, CREDIT_LIMIT, abi.encode(proposal));
//     }

//     function test_shouldFail_whenNoComputerRegistered_whenAssetDoesNotImplementERC5646()
//         external
//         whenValidInputsAndCallers
//         whenStateFingerprintChecks
//     {
//         proposal.checkCollateralStateFingerprint = true;
//         proposal.collateralStateFingerprint = collateralStateFingerprint;
//         _createERC20Proposal();

//         vm.mockCall(
//             address(deployment.config),
//             abi.encodeWithSignature("getStateFingerprintComputer(address)"),
//             abi.encode(address(0))
//         );
//         _mockERC5646Support(proposal.collateralAddress, false);

//         vm.expectRevert(abi.encodeWithSelector(ISproErrors.MissingStateFingerprintComputer.selector));
//         vm.prank(proposal.loanContract);
//         deployment.simpleLoanSimpleProposal.acceptProposal(lender, CREDIT_LIMIT, abi.encode(proposal));
//     }

//     function testFuzz_shouldFail_whenAssetImplementsERC5646_whenComputerReturnsDifferentStateFingerprint(
//         bytes32 stateFp
//     ) external whenValidInputsAndCallers whenStateFingerprintChecks {
//         vm.assume(stateFp != collateralStateFingerprint);

//         proposal.checkCollateralStateFingerprint = true;
//         proposal.collateralStateFingerprint = collateralStateFingerprint;
//         _createERC20Proposal();

//         vm.mockCall(
//             address(deployment.config),
//             abi.encodeWithSignature("getStateFingerprintComputer(address)"),
//             abi.encode(address(0))
//         );
//         _mockERC5646Support(proposal.collateralAddress, true);
//         vm.mockCall(
//             proposal.collateralAddress, abi.encodeWithSignature("getStateFingerprint(uint256)"), abi.encode(stateFp)
//         );

//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 ISproErrors.InvalidCollateralStateFingerprint.selector, stateFp, collateralStateFingerprint
//             )
//         );
//         vm.prank(proposal.loanContract);
//         deployment.simpleLoanSimpleProposal.acceptProposal(lender, CREDIT_LIMIT, abi.encode(proposal));
//     }

//     function test_shouldPass_whenAssetImplementsERC5646_whenReturnsMatchingFingerprint()
//         external
//         whenValidInputsAndCallers
//         whenStateFingerprintChecks
//     {
//         proposal.checkCollateralStateFingerprint = true;
//         proposal.collateralStateFingerprint = collateralStateFingerprint;
//         _createERC20Proposal();

//         vm.mockCall(
//             address(deployment.config),
//             abi.encodeWithSignature("getStateFingerprintComputer(address)"),
//             abi.encode(address(0))
//         );
//         _mockERC5646Support(proposal.collateralAddress, true);
//         vm.mockCall(
//             proposal.collateralAddress,
//             abi.encodeWithSignature("getStateFingerprint(uint256)"),
//             abi.encode(collateralStateFingerprint)
//         );
//         vm.prank(proposal.loanContract);
//         deployment.simpleLoanSimpleProposal.acceptProposal(lender, CREDIT_LIMIT, abi.encode(proposal));
//     }
// }
