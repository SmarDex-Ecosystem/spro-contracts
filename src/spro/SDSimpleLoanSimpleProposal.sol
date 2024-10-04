// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { SDConfig, IStateFingerprintComputer } from "spro/SDConfig.sol";
import { IERC5646 } from "src/interfaces/IERC5646.sol";
import { SDSimpleLoan } from "spro/SDSimpleLoan.sol";
import { PWNRevokedNonce } from "spro/PWNRevokedNonce.sol";
import { Expired, AddressMissingHubTag } from "src/PWNErrors.sol";

/**
 * @title SD Simple Loan Simple Proposal
 * @notice Contract for creating and accepting simple loan proposals.
 */
contract SDSimpleLoanSimpleProposal {
    /* ------------------------------------------------------------ */
    /*  VARIABLES & CONSTANTS DEFINITIONS                        */
    /* ------------------------------------------------------------ */

    string public constant VERSION = "1.0";

    /**
     * @dev EIP-712 simple proposal struct type hash.
     */
    bytes32 public constant PROPOSAL_TYPEHASH = keccak256(
        "Proposal(address collateralAddress,uint256 collateralAmount,bool checkCollateralStateFingerprint,bytes32 collateralStateFingerprint,address creditAddress,uint256 availableCreditLimit,uint256 fixedInterestAmount,uint40 accruingInterestAPR,uint32 duration,uint40 startTimestamp,address proposer,bytes32 proposerSpecHash,uint256 nonceSpace,uint256 nonce,address loanContract)"
    );

    /**
     * @notice Construct defining a simple proposal.
     * @param collateralAddress Address of an asset used as a collateral.
     * @param collateralAmount Amount of tokens used as a collateral, in case of ERC721 should be 0.
     * @param checkCollateralStateFingerprint If true, the collateral state fingerprint will be checked during proposal
     * acceptance.
     * @param collateralStateFingerprint Fingerprint of a collateral state defined by ERC5646.
     * @param creditAddress Address of an asset which is lended to a borrower.
     * @param availableCreditLimit Available credit limit for the proposal. It is the maximum amount of tokens which can
     * be borrowed using the proposal. If non-zero, proposal can be accepted more than once, until the credit limit is
     * reached.
     * @param fixedInterestAmount Fixed interest amount in credit tokens. It is the minimum amount of interest which has
     * to be paid by a borrower.
     * @param accruingInterestAPR Accruing interest APR with 2 decimals.
     * @param startTimestamp Proposal start timestamp in seconds.
     * @param defaultTimestamp Proposal default timestamp in seconds.
     * @param proposer Address of a proposal signer. If `isOffer` is true, the proposer is the lender. If `isOffer` is
     * false, the proposer is the borrower.
     * @param proposerSpecHash Hash of a proposer specific data, which must be provided during a loan creation.
     * @param nonceSpace Nonce space of a proposal nonce. All nonces in the same space can be revoked at once.
     * @param nonce Additional value to enable identical proposals in time. Without it, it would be impossible to make
     * again proposal, which was once revoked. Can be used to create a group of proposals, where accepting one proposal
     * will make other proposals in the group revoked.
     * @param loanContract Address of a loan contract that will create a loan from the proposal.
     */
    struct Proposal {
        address collateralAddress;
        uint256 collateralAmount;
        bool checkCollateralStateFingerprint;
        bytes32 collateralStateFingerprint;
        address creditAddress;
        uint256 availableCreditLimit;
        uint256 fixedInterestAmount;
        uint24 accruingInterestAPR;
        uint40 startTimestamp;
        uint40 defaultTimestamp;
        address proposer;
        bytes32 proposerSpecHash;
        uint256 nonceSpace;
        uint256 nonce;
        address loanContract;
    }

    /**
     * @dev Mapping of proposals to the borrower's withdrawable collateral tokens
     *      (proposal hash => amount of collateral tokens)
     */
    mapping(bytes32 => uint256) public withdrawableCollateral;

    /* ------------------------------------------------------------ */
    /*                      EVENTS DEFINITIONS                      */
    /* ------------------------------------------------------------ */

    /**
     * @notice Emitted when a proposal is made via an on-chain transaction.
     */
    event ProposalMade(bytes32 indexed proposalHash, address indexed proposer, Proposal proposal);

    /* ------------------------------------------------------------ */
    /*                      ERRORS DEFINITIONS                      */
    /* ------------------------------------------------------------ */

    /**
     * @notice Thrown when a partial loan is attempted for NFT collateral.
     */
    error OnlyCompleteLendingForNFTs(uint256 creditAmount, uint256 availableCreditLimit);

    /**
     * @notice Thrown when the start timestamp is greater than the default timestamp.
     */
    error InvalidDuration();

    /* ------------------------------------------------------------ */
    /*              VARIABLES & CONSTANTS DEFINITIONS               */
    /* ------------------------------------------------------------ */

    bytes32 public immutable DOMAIN_SEPARATOR;

    PWNRevokedNonce public immutable revokedNonce;
    SDConfig public immutable config;

    uint256 internal constant PERCENTAGE = 1e4;

    struct ProposalBase {
        address collateralAddress;
        bool checkCollateralStateFingerprint;
        bytes32 collateralStateFingerprint;
        uint256 availableCreditLimit;
        uint40 startTimestamp;
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

    /* ------------------------------------------------------------ */
    /*                      ERRORS DEFINITIONS                      */
    /* ------------------------------------------------------------ */

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
     * @notice Thrown when credit amount is above the maximum amount for the proposal, but not 100% of available
     */
    error CreditAmountLeavesTooLittle(uint256 amount, uint256 maximum);

    /**
     * @notice Thrown when a proposal would exceed the available credit limit.
     */
    error AvailableCreditLimitExceeded(uint256 used, uint256 limit);

    /**
     * @notice Thrown when a proposal has an available credit limit of zero.
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

    /* ------------------------------------------------------------ */
    /*                          CONSTRUCTOR                         */
    /* ------------------------------------------------------------ */

    constructor(address _revokedNonce, address _config) {
        revokedNonce = PWNRevokedNonce(_revokedNonce);
        config = SDConfig(_config);

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(abi.encodePacked("SDSimpleLoanSimpleProposal")),
                keccak256(abi.encodePacked(VERSION)),
                block.chainid,
                address(this)
            )
        );
    }

    /* ------------------------------------------------------------ */
    /*                          EXTERNALS                           */
    /* ------------------------------------------------------------ */

    /**
     * @notice Helper function for revoking a proposal nonce on behalf of a caller.
     * @param nonceSpace Nonce space of a proposal nonce to be revoked.
     * @param nonce Proposal nonce to be revoked.
     */
    function revokeNonce(uint256 nonceSpace, uint256 nonce) external {
        revokedNonce.revokeNonce(msg.sender, nonceSpace, nonce);
    }

    /**
     * @notice Get an proposal hash according to EIP-712
     * @param proposal Proposal struct to be hashed.
     * @return Proposal struct hash.
     */
    function getProposalHash(Proposal calldata proposal) public view returns (bytes32) {
        return _getProposalHash(PROPOSAL_TYPEHASH, abi.encode(proposal));
    }

    /**
     * @notice Encode proposal data.
     * @param proposal Proposal struct to be encoded.
     * @return Encoded proposal data.
     */
    function encodeProposalData(Proposal memory proposal) public pure returns (bytes memory) {
        return abi.encode(proposal);
    }

    /**
     * @notice Decode proposal data.
     * @param proposalData Encoded proposal data.
     * @return Decoded proposal struct.
     */
    function decodeProposalData(bytes memory proposalData) public pure returns (Proposal memory) {
        return abi.decode(proposalData, (Proposal));
    }

    /**
     * @notice Getter for credit used and credit remaining for a proposal.
     * @param proposal Proposal struct.
     * @return used Credit used for the proposal.
     * @return remaining Credit remaining for the proposal.
     */
    function getProposalCreditStatus(Proposal calldata proposal)
        external
        view
        returns (uint256 used, uint256 remaining)
    {
        bytes32 proposalHash = getProposalHash(proposal);
        if (proposalsMade[proposalHash]) {
            used = creditUsed[proposalHash];
            remaining = proposal.availableCreditLimit - used;
        } else {
            revert ProposalNotMade();
        }
    }

    /**
     * @notice Make an on-chain proposal.
     * @dev Function will mark a proposal hash as proposed.
     * @param proposalData Encoded proposal data.
     * @return proposer Address of the borrower/proposer
     * @return collateral Address of the collateral token.
     * @return collateralAmount Amount of the collateral token.
     * @return creditAddress Address of the credit token.
     * @return creditLimit Credit limit.
     */
    function makeProposal(bytes calldata proposalData)
        external
        returns (
            address proposer,
            address collateral,
            uint256 collateralAmount,
            address creditAddress,
            uint256 creditLimit
        )
    {
        // Decode proposal data
        Proposal memory proposal = decodeProposalData(proposalData);
        if (proposal.startTimestamp > proposal.defaultTimestamp) {
            revert InvalidDuration();
        }

        // Make proposal hash
        bytes32 proposalHash = _getProposalHash(PROPOSAL_TYPEHASH, abi.encode(proposal));

        // Try to make proposal
        _makeProposal(proposalHash);

        collateral = proposal.collateralAddress;
        collateralAmount = proposal.collateralAmount;
        withdrawableCollateral[proposalHash] = collateralAmount;
        creditAddress = proposal.creditAddress;
        creditLimit = proposal.availableCreditLimit;

        emit ProposalMade(proposalHash, proposer = proposal.proposer, proposal);
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
        returns (bytes32 proposalHash, SDSimpleLoan.Terms memory loanTerms)
    {
        // Decode proposal data
        Proposal memory proposal = decodeProposalData(proposalData);

        // Make proposal hash
        proposalHash = _getProposalHash(PROPOSAL_TYPEHASH, abi.encode(proposal));

        // Try to accept proposal
        _acceptProposal(
            acceptor,
            creditAmount,
            proposalHash,
            ProposalBase({
                collateralAddress: proposal.collateralAddress,
                checkCollateralStateFingerprint: proposal.checkCollateralStateFingerprint,
                collateralStateFingerprint: proposal.collateralStateFingerprint,
                availableCreditLimit: proposal.availableCreditLimit,
                startTimestamp: proposal.startTimestamp,
                proposer: proposal.proposer,
                nonceSpace: proposal.nonceSpace,
                nonce: proposal.nonce,
                loanContract: proposal.loanContract
            })
        );

        // Create loan terms object
        uint256 collateralUsed_ = (creditAmount * proposal.collateralAmount) / proposal.availableCreditLimit;

        loanTerms = SDSimpleLoan.Terms({
            lender: acceptor,
            borrower: proposal.proposer,
            startTimestamp: proposal.startTimestamp,
            defaultTimestamp: proposal.defaultTimestamp,
            collateral: proposal.collateralAddress,
            collateralAmount: collateralUsed_,
            credit: proposal.creditAddress,
            creditAmount: creditAmount,
            fixedInterestAmount: proposal.fixedInterestAmount,
            accruingInterestAPR: proposal.accruingInterestAPR,
            lenderSpecHash: bytes32(0),
            borrowerSpecHash: proposal.proposerSpecHash
        });

        withdrawableCollateral[proposalHash] -= collateralUsed_;
    }

    /**
     * @notice Cancels a proposal and resets withdrawable collateral.
     * @dev Revokes the nonce if still usable and block.timestamp is < proposal startTimestamp.
     * @param proposalData Encoded proposal data.
     * @return proposer Address of the borrower/proposer.
     * @return collateral Address or the token.
     * @return collateralAmount Amount of collateral tokens that can be withdrawn.
     */
    function cancelProposal(bytes calldata proposalData)
        external
        returns (address proposer, address collateral, uint256 collateralAmount)
    {
        // Decode proposal data
        Proposal memory proposal = decodeProposalData(proposalData);

        // Make proposal hash
        bytes32 proposalHash = _getProposalHash(PROPOSAL_TYPEHASH, abi.encode(proposal));

        proposer = proposal.proposer;
        collateral = proposal.collateralAddress;
        collateralAmount = withdrawableCollateral[proposalHash];
        delete withdrawableCollateral[proposalHash];

        // Revokes nonce if nonce is still usable
        if (block.timestamp < proposal.startTimestamp) {
            if (revokedNonce.isNonceUsable(proposal.proposer, proposal.nonceSpace, proposal.nonce)) {
                revokedNonce.revokeNonce(proposal.proposer, proposal.nonceSpace, proposal.nonce);
            }
        }
    }

    /* ------------------------------------------------------------ */
    /*                          INTERNALS                           */
    /* ------------------------------------------------------------ */

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
     */
    function _makeProposal(bytes32 proposalHash) internal {
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
        // Check that the proposal was made on-chain
        if (!proposalsMade[proposalHash]) revert ProposalNotMade();

        // Check proposer is not acceptor
        if (proposal.proposer == acceptor) {
            revert AcceptorIsProposer({ addr: acceptor });
        }

        // Check proposal is not expired
        if (block.timestamp >= proposal.startTimestamp) {
            revert Expired({ current: block.timestamp, expiration: proposal.startTimestamp });
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
        } else if (creditUsed[proposalHash] + creditAmount < proposal.availableCreditLimit) {
            // Credit may only be between min and max amounts if it is not exact
            uint256 minCreditAmount =
                Math.mulDiv(proposal.availableCreditLimit, config.partialPositionPercentage(), PERCENTAGE);
            if (creditAmount < minCreditAmount) {
                revert CreditAmountTooSmall({ amount: creditAmount, minimum: minCreditAmount });
            }

            uint256 maxCreditAmount = Math.mulDiv(
                proposal.availableCreditLimit, (PERCENTAGE - config.partialPositionPercentage()), PERCENTAGE
            );
            if (creditAmount > maxCreditAmount) {
                revert CreditAmountLeavesTooLittle({ amount: creditAmount, maximum: maxCreditAmount });
            }
        } else if (creditUsed[proposalHash] + creditAmount > proposal.availableCreditLimit) {
            // Revert, credit limit is exceeded
            revert AvailableCreditLimitExceeded({
                used: creditUsed[proposalHash] + creditAmount,
                limit: proposal.availableCreditLimit
            });
        }

        // Apply increase if credit amount checks pass
        creditUsed[proposalHash] += creditAmount;

        // Check collateral state fingerprint if needed
        if (proposal.checkCollateralStateFingerprint) {
            bytes32 currentFingerprint;
            IStateFingerprintComputer computer = config.getStateFingerprintComputer(proposal.collateralAddress);
            if (address(computer) != address(0)) {
                // Asset has registered computer
                currentFingerprint = computer.computeStateFingerprint({ token: proposal.collateralAddress, tokenId: 0 });
            } else if (ERC165Checker.supportsInterface(proposal.collateralAddress, type(IERC5646).interfaceId)) {
                // Asset implements ERC5646
                currentFingerprint = IERC5646(proposal.collateralAddress).getStateFingerprint(0);
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

    /**
     * @notice Checks for a complete loan with credit amount equal to available credit limit
     * @param _creditAmount Credit amount of the proposal.
     * @param _availableCreditLimit Available credit limit of the proposal.
     */
    function _checkCompleteLoan(uint256 _creditAmount, uint256 _availableCreditLimit) internal pure {
        if (_creditAmount != _availableCreditLimit) {
            revert OnlyCompleteLendingForNFTs(_creditAmount, _availableCreditLimit);
        }
    }
}
