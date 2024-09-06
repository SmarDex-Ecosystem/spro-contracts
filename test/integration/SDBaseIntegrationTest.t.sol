// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import {MultiToken} from "MultiToken/MultiToken.sol";
import {Permit} from "pwn/loan/vault/Permit.sol";
import {SigUtils} from "test/utils/SigUtils.sol";
import {CreditPermit} from "test/helper/CreditPermit.sol";
import {DummyPoolAdapter} from "test/helper/DummyPoolAdapter.sol";
import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";
import {IERC5646} from "pwn/loan/terms/simple/proposal/SDSimpleLoanProposal.sol";
import {T20} from "test/helper/T20.sol";
import {T721} from "test/helper/T721.sol";
import {T1155} from "test/helper/T1155.sol";
import {Events} from "test/utils/Events.sol";
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

abstract contract SDBaseIntegrationTest is SDDeploymentTest, Events {
    T20 t20;
    T721 t721;
    T1155 t1155;
    T20 credit;

    uint256 lenderPK = uint256(777);
    address lender = vm.addr(lenderPK);
    uint256 borrowerPK = uint256(888);
    address borrower = vm.addr(borrowerPK);
    SDSimpleLoanSimpleProposal.Proposal proposal;
    Permit permit;

    address public stateFingerprintComputer = makeAddr("stateFingerprintComputer");
    bytes32 public collateralStateFingerprint = keccak256("some state fingerprint");

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

    uint16 public constant DEFAULT_MIN_THRESHOLD = 500;
    uint16 public constant DEFAULT_MAX_THRESHOLD = 9500;

    function setUp() public virtual override {
        super.setUp();

        // Deploy tokens
        t20 = new T20();
        t721 = new T721();
        t1155 = new T1155();
        credit = new T20();

        // Permit
        creditPermit = new CreditPermit();
        sigUtils = new SigUtils(creditPermit.DOMAIN_SEPARATOR());

        // Pool adapter
        poolAdapter = new DummyPoolAdapter();
        vm.label(address(poolAdapter), "poolAdapter");

        // Deploy protocol contracts
        proposal = SDSimpleLoanSimpleProposal.Proposal({
            collateralCategory: MultiToken.Category.ERC20,
            collateralAddress: address(t20),
            collateralId: 0,
            collateralAmount: COLLATERAL_AMOUNT,
            checkCollateralStateFingerprint: false,
            collateralStateFingerprint: bytes32(0),
            creditAddress: address(credit),
            availableCreditLimit: CREDIT_LIMIT,
            fixedInterestAmount: FIXED_INTEREST_AMOUNT,
            accruingInterestAPR: 0,
            duration: 5 days,
            expiration: uint40(block.timestamp + 7 days),
            proposer: borrower,
            proposerSpecHash: keccak256(abi.encode(borrower)),
            nonceSpace: 0,
            nonce: 0,
            loanContract: address(deployment.simpleLoan)
        });

        // Mint and approve SDEX
        deployment.sdex.mint(lender, INITIAL_SDEX_BALANCE);
        vm.prank(lender);
        deployment.sdex.approve(address(deployment.simpleLoan), type(uint256).max);
        deployment.sdex.mint(borrower, INITIAL_SDEX_BALANCE);
        vm.prank(borrower);
        deployment.sdex.approve(address(deployment.simpleLoan), type(uint256).max);

        // Set thresholds in config
        vm.startPrank(deployment.protocolAdmin);
        SDConfig(deployment.config).setMaximumPartialPositionPercentage(DEFAULT_MAX_THRESHOLD);
        SDConfig(deployment.config).setMinimumPartialPositionPercentage(DEFAULT_MIN_THRESHOLD);
        vm.stopPrank();

        // Add labels
        vm.label(lender, "lender");
        vm.label(borrower, "borrower");
        vm.label(address(credit), "credit");
        vm.label(address(t20), "t20");
        vm.label(address(t721), "t721");
        vm.label(address(t1155), "t1155");

        // Setup & label new lender addresses
        (alice, aliceKey) = makeAddrAndKey("alice");
        vm.label(alice, "alice");
        bob = makeAddr("bob");
        vm.label(bob, "bob");
        charlee = makeAddr("charlee");
        vm.label(charlee, "charlee");

        // Mock state fingerprint calls
        vm.mockCall(
            address(deployment.config),
            abi.encodeWithSignature("getStateFingerprintComputer(address)"),
            abi.encode(stateFingerprintComputer)
        );
        vm.mockCall(
            stateFingerprintComputer,
            abi.encodeWithSignature("computeStateFingerprint(address,uint256)"),
            abi.encode(collateralStateFingerprint)
        );
    }

    // Make the proposal
    function _createERC20Proposal() internal returns (SDSimpleLoan.ProposalSpec memory proposalSpec) {
        // Mint initial state & approve collateral
        t20.mint(borrower, proposal.collateralAmount);
        vm.prank(borrower);
        t20.approve(address(deployment.simpleLoan), proposal.collateralAmount);

        // Create the proposal
        proposalSpec = _buildProposalSpec(proposal);

        vm.prank(borrower);
        deployment.simpleLoan.createProposal(proposalSpec);
    }

    function _createERC721Proposal() internal returns (SDSimpleLoan.ProposalSpec memory proposalSpec) {
        // Adjust base proposal
        proposal.collateralCategory = MultiToken.Category.ERC721;
        proposal.collateralAddress = address(t721);
        proposal.collateralId = COLLATERAL_ID;
        proposal.collateralAmount = 0;

        // Mint initial state & approve collateral
        t721.mint(borrower, COLLATERAL_ID);
        vm.prank(borrower);
        t721.approve(address(deployment.simpleLoan), COLLATERAL_ID);

        // Create the proposal
        proposalSpec = _buildProposalSpec(proposal);

        vm.prank(borrower);
        deployment.simpleLoan.createProposal(proposalSpec);
    }

    function _createFungibleERC1155Proposal() internal returns (SDSimpleLoan.ProposalSpec memory proposalSpec) {
        // Adjust base proposal
        proposal.collateralCategory = MultiToken.Category.ERC1155;
        proposal.collateralAddress = address(t1155);
        proposal.collateralId = COLLATERAL_ID;
        proposal.collateralAmount = COLLATERAL_AMOUNT;

        // Mint initial state & approve collateral
        t1155.mint(borrower, COLLATERAL_ID, COLLATERAL_AMOUNT);
        vm.prank(borrower);
        t1155.setApprovalForAll(address(deployment.simpleLoan), true);

        // Create the proposal
        proposalSpec = _buildProposalSpec(proposal);

        vm.prank(borrower);
        deployment.simpleLoan.createProposal(proposalSpec);
    }

    function _createNonFungibleERC1155Proposal() internal returns (SDSimpleLoan.ProposalSpec memory proposalSpec) {
        // Adjust base proposal
        proposal.collateralCategory = MultiToken.Category.ERC1155;
        proposal.collateralAddress = address(t1155);
        proposal.collateralId = COLLATERAL_ID;
        proposal.collateralAmount = 1;

        // Mint initial state & approve collateral
        t1155.mint(borrower, COLLATERAL_ID, 1);
        vm.prank(borrower);
        t1155.setApprovalForAll(address(deployment.simpleLoan), true);

        // Create the proposal
        proposalSpec = _buildProposalSpec(proposal);

        vm.prank(borrower);
        deployment.simpleLoan.createProposal(proposalSpec);
    }

    function _createLoan(SDSimpleLoan.ProposalSpec memory proposalSpec, bytes memory revertData)
        internal
        returns (uint256 loanId)
    {
        // Mint initial state & approve credit
        credit.mint(lender, INITIAL_CREDIT_BALANCE);
        vm.prank(lender);
        credit.approve(address(deployment.simpleLoan), CREDIT_LIMIT);

        // Create LOAN
        if (keccak256(revertData) != keccak256("")) {
            vm.expectRevert(revertData);
        }

        vm.prank(lender);
        if (
            proposal.collateralCategory == MultiToken.Category.ERC721
                || (proposal.collateralCategory == MultiToken.Category.ERC1155 && proposal.collateralAmount == 1)
        ) {
            return deployment.simpleLoan.createLOAN({
                proposalSpec: proposalSpec,
                lenderSpec: _buildLenderSpec(true),
                extra: ""
            });
        } else {
            return deployment.simpleLoan.createLOAN({
                proposalSpec: proposalSpec,
                lenderSpec: _buildLenderSpec(false),
                extra: ""
            });
        }
    }

    function _cancelProposal(SDSimpleLoanSimpleProposal.Proposal memory _proposal) internal {
        deployment.simpleLoan.cancelProposal(_buildProposalSpec(_proposal));
    }

    function _buildLenderSpec(bool complete) internal view returns (SDSimpleLoan.LenderSpec memory lenderSpec) {
        lenderSpec = complete
            ? SDSimpleLoan.LenderSpec({sourceOfFunds: lender, creditAmount: CREDIT_LIMIT, permitData: ""})
            : SDSimpleLoan.LenderSpec({sourceOfFunds: lender, creditAmount: CREDIT_AMOUNT, permitData: ""});
    }

    function _buildProposalSpec(SDSimpleLoanSimpleProposal.Proposal memory _proposal)
        internal
        view
        returns (SDSimpleLoan.ProposalSpec memory proposalSpec)
    {
        return SDSimpleLoan.ProposalSpec({
            proposalContract: address(deployment.simpleLoanSimpleProposal),
            proposalData: abi.encode(_proposal)
        });
    }

    function _mockERC5646Support(address asset, bool result) internal {
        _mockERC165Call(asset, type(IERC165).interfaceId, true);
        _mockERC165Call(asset, hex"ffffffff", false);
        _mockERC165Call(asset, type(IERC5646).interfaceId, result);
    }

    function _mockERC165Call(address asset, bytes4 interfaceId, bool result) internal {
        vm.mockCall(asset, abi.encodeWithSignature("supportsInterface(bytes4)", interfaceId), abi.encode(result));
    }
}
