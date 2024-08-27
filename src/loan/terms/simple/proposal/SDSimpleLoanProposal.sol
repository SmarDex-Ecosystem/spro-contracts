// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import {MultiToken} from "MultiToken/MultiToken.sol";
import {ERC165Checker} from "openzeppelin/utils/introspection/ERC165Checker.sol";
import {Math} from "openzeppelin/utils/math/Math.sol";

import {SDConfig, IStateFingerprintComputer} from "pwn/config/SDConfig.sol";
import {PWNHub} from "pwn/hub/PWNHub.sol";
import {PWNHubTags} from "pwn/hub/PWNHubTags.sol";
import {IERC5646} from "pwn/interfaces/IERC5646.sol";
import {SDSimpleLoan} from "pwn/loan/terms/simple/loan/SDSimpleLoan.sol";
import {PWNRevokedNonce} from "pwn/nonce/PWNRevokedNonce.sol";
import {Expired, AddressMissingHubTag} from "pwn/PWNErrors.sol";

/**
 * @title PWN Simple Loan Proposal Base Contract
 * @notice Base contract of loan proposals that builds a simple loan terms.
 */
abstract contract SDSimpleLoanProposal {
    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    bytes32 public immutable DOMAIN_SEPARATOR;

    PWNHub public immutable hub;
    PWNRevokedNonce public immutable revokedNonce;
    SDConfig public immutable config;

    uint256 public constant MINIMUM_PERCENTAGE_POSITION = 500; // In basis points, 100% == 1e4.
    uint256 public constant THRESHOLD_PERCENTAGE_POSITION = 9500; // In basis points, 100% == 1e4.
    uint256 internal constant PERCENTAGE = 1e4;

    struct ProposalBase {
        address collateralAddress;
        uint256 collateralId;
        bool checkCollateralStateFingerprint;
        bytes32 collateralStateFingerprint;
        uint256 availableCreditLimit;
        uint40 expiration;
        address proposer;
        uint256 nonceSpace;
        uint256 nonce;
        address loanContract;
    }

    /**
     * @dev Mapping of proposals made via on-chain transactions.
     *      (proposal hash => is made)
     */
    mapping(bytes32 => bool) public proposalsMade;

    /**
     * @dev Mapping of credit used by a proposal with defined available credit limit.
     *      (proposal hash => credit used)
     */
    mapping(bytes32 => uint256) public creditUsed;

    /*----------------------------------------------------------*|
    |*  # ERRORS DEFINITIONS                                    *|
    |*----------------------------------------------------------*/

    /**
     * @notice Thrown when a caller is missing a required hub tag.
     */
    error CallerNotLoanContract(address caller, address loanContract);

    /**
     * @notice Thrown when a state fingerprint computer is not registered.
     */
    error MissingStateFingerprintComputer();

    /**
     * @notice Thrown when a proposed collateral state fingerprint doesn't match the current state.
     */
    error InvalidCollateralStateFingerprint(bytes32 current, bytes32 proposed);

    /**
     * @notice Thrown when a caller is not a stated proposer.
     */
    error CallerIsNotStatedProposer(address addr);

    /**
     * @notice Thrown when proposal acceptor and proposer are the same.
     */
    error AcceptorIsProposer(address addr);

    /**
     * @notice Thrown when credit amount is below the minimum amount for the proposal.
     */
    error CreditAmountTooSmall(uint256 amount, uint256 minimum);

    /**
     * @notice Thrown when a proposal would exceed the available credit limit.
     */
    error AvailableCreditLimitExceeded(uint256 used, uint256 limit);

    /**
     * @notice Thrown when a proposal would exceed the available credit limit.
     */
    error AvailableCreditLimitZero();

    /**
     * @notice Thrown when caller is not allowed to accept a proposal.
     */
    error CallerNotAllowedAcceptor(address current, address allowed);

    /**
     * @notice Thrown when the proposal already exists.
     */
    error ProposalAlreadyExists();

    /**
     * @notice Thrown when the proposal has not been made.
     */
    error ProposalNotMade();

    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR                                           *|
    |*----------------------------------------------------------*/

    constructor(address _hub, address _revokedNonce, address _config, string memory name, string memory version) {
        hub = PWNHub(_hub);
        revokedNonce = PWNRevokedNonce(_revokedNonce);
        config = SDConfig(_config);

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(abi.encodePacked(name)),
                keccak256(abi.encodePacked(version)),
                block.chainid,
                address(this)
            )
        );
    }

    /*----------------------------------------------------------*|
    |*  # EXTERNALS                                             *|
    |*----------------------------------------------------------*/

    /**
     * @notice Helper function for revoking a proposal nonce on behalf of a caller.
     * @param nonceSpace Nonce space of a proposal nonce to be revoked.
     * @param nonce Proposal nonce to be revoked.
     */
    function revokeNonce(uint256 nonceSpace, uint256 nonce) external {
        revokedNonce.revokeNonce(msg.sender, nonceSpace, nonce);
    }

    /**
     * @notice Accept a proposal and create new loan terms.
     * @dev Function can be called only by a loan contract with appropriate PWN Hub tag.
     * @param acceptor Address of a proposal acceptor.
     * @param creditAmount Amount of credit to lend.
     * @param proposalData Encoded proposal data with signature.
     * @return proposalHash Proposal hash.
     * @return loanTerms Loan terms.
     */
    function acceptProposal(address acceptor, uint256 creditAmount, bytes calldata proposalData)
        external
        virtual
        returns (bytes32 proposalHash, SDSimpleLoan.Terms memory loanTerms);

    /**
     * @notice Make an on-chain proposal.
     * @dev Function will mark a proposal hash as proposed.
     * @param proposalData Encoded proposal data.
     * @return proposer Address of the borrower/proposer
     * @return collateral Collateral token as a MultiToken.Asset struct.
     * @return creditAddress Address of the credit token.
     * @return creditLimit Credit limit.
     */
    function makeProposal(bytes calldata proposalData)
        external
        virtual
        returns (address proposer, MultiToken.Asset memory collateral, address creditAddress, uint256 creditLimit);

    /**
     * @notice Cancel a proposal and withdraw unused collateral.
     * @dev Function can be called only by a loan contract with appropriate PWN Hub tag.
     * @param proposalData Encoded proposal data.
     * @return proposer Address of the borrower/proposer.
     * @return collateral Collateral token as a MultiToken.Asset struct.
     */
    function cancelProposal(bytes calldata proposalData)
        external
        virtual
        returns (address proposer, MultiToken.Asset memory collateral);

    /*----------------------------------------------------------*|
    |*  # INTERNALS                                             *|
    |*----------------------------------------------------------*/

    /**
     * @notice Get a proposal hash according to EIP-712.
     * @param encodedProposal Encoded proposal struct.
     * @return Struct hash.
     */
    function _getProposalHash(bytes32 proposalTypehash, bytes memory encodedProposal) internal view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                hex"1901", DOMAIN_SEPARATOR, keccak256(abi.encodePacked(proposalTypehash, encodedProposal))
            )
        );
    }

    /**
     * @notice Make an on-chain proposal.
     * @dev Function will mark a proposal hash as proposed.
     * @param proposalHash Proposal hash.
     * @param loanContract Address of the loan contract for the proposal.
     */
    function _makeProposal(bytes32 proposalHash, address loanContract) internal {
        if (msg.sender != loanContract) {
            revert CallerNotLoanContract({caller: msg.sender, loanContract: loanContract});
        }

        if (proposalsMade[proposalHash]) revert ProposalAlreadyExists();

        proposalsMade[proposalHash] = true;
    }

    /**
     * @notice Try to accept proposal base.
     * @param acceptor Address of a proposal acceptor.
     * @param proposalHash Proposal hash.
     * @param proposal Proposal base struct.
     */
    function _acceptProposal(address acceptor, uint256 creditAmount, bytes32 proposalHash, ProposalBase memory proposal)
        internal
    {
        // Check loan contract
        if (msg.sender != proposal.loanContract) {
            revert CallerNotLoanContract({caller: msg.sender, loanContract: proposal.loanContract});
        }
        if (!hub.hasTag(proposal.loanContract, PWNHubTags.ACTIVE_LOAN)) {
            revert AddressMissingHubTag({addr: proposal.loanContract, tag: PWNHubTags.ACTIVE_LOAN});
        }

        // Check that the proposal was made on-chain
        if (!proposalsMade[proposalHash]) revert ProposalNotMade();

        // Check proposer is not acceptor
        if (proposal.proposer == acceptor) {
            revert AcceptorIsProposer({addr: acceptor});
        }

        // Check proposal is not expired
        if (block.timestamp >= proposal.expiration) {
            revert Expired({current: block.timestamp, expiration: proposal.expiration});
        }

        // Check proposal is not revoked
        if (!revokedNonce.isNonceUsable(proposal.proposer, proposal.nonceSpace, proposal.nonce)) {
            revert PWNRevokedNonce.NonceNotUsable({
                addr: proposal.proposer,
                nonceSpace: proposal.nonceSpace,
                nonce: proposal.nonce
            });
        }

        if (proposal.availableCreditLimit == 0) {
            revert AvailableCreditLimitZero();
        } else if (creditUsed[proposalHash] + creditAmount <= proposal.availableCreditLimit) {
            uint256 minCreditAmount =
                Math.mulDiv(proposal.availableCreditLimit, MINIMUM_PERCENTAGE_POSITION, PERCENTAGE);

            if (creditAmount >= minCreditAmount) {
                // Increase used credit if credit limit is not exceeded
                creditUsed[proposalHash] += creditAmount;

                // Revoke nonce if credit used is greater than 95% of the credit limit.
                // Minimum credit amount can never be satisfied then.
                if (
                    creditUsed[proposalHash]
                        > Math.mulDiv(proposal.availableCreditLimit, THRESHOLD_PERCENTAGE_POSITION, PERCENTAGE)
                ) {
                    revokedNonce.revokeNonce(proposal.proposer, proposal.nonceSpace, proposal.nonce);
                }
            } else {
                revert CreditAmountTooSmall({amount: creditAmount, minimum: minCreditAmount});
            }
        } else {
            // Revert if credit limit is exceeded
            revert AvailableCreditLimitExceeded({
                used: creditUsed[proposalHash] + creditAmount,
                limit: proposal.availableCreditLimit
            });
        }

        // Check collateral state fingerprint if needed
        if (proposal.checkCollateralStateFingerprint) {
            bytes32 currentFingerprint;
            IStateFingerprintComputer computer = config.getStateFingerprintComputer(proposal.collateralAddress);
            if (address(computer) != address(0)) {
                // Asset has registered computer
                currentFingerprint = computer.computeStateFingerprint({
                    token: proposal.collateralAddress,
                    tokenId: proposal.collateralId
                });
            } else if (ERC165Checker.supportsInterface(proposal.collateralAddress, type(IERC5646).interfaceId)) {
                // Asset implements ERC5646
                currentFingerprint = IERC5646(proposal.collateralAddress).getStateFingerprint(proposal.collateralId);
            } else {
                // Asset is not implementing ERC5646 and no computer is registered
                revert MissingStateFingerprintComputer();
            }

            if (proposal.collateralStateFingerprint != currentFingerprint) {
                // Fingerprint mismatch
                revert InvalidCollateralStateFingerprint({
                    current: currentFingerprint,
                    proposed: proposal.collateralStateFingerprint
                });
            }
        }
    }
}
