// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { SDConfig, IStateFingerprintComputer } from "spro/SDConfig.sol";
import { IERC5646 } from "src/interfaces/IERC5646.sol";
import { SDSimpleLoan } from "spro/SDSimpleLoan.sol";
import { PWNRevokedNonce } from "spro/PWNRevokedNonce.sol";
import { ISproErrors } from "src/interfaces/ISproErrors.sol";
import { ISproEvents } from "src/interfaces/ISproEvents.sol";
import { SproConstantsLibrary as Constants } from "src/libraries/SproConstantsLibrary.sol";

/**
 * @title SD Simple Loan Simple Proposal
 * @notice Contract for creating and accepting simple loan proposals.
 */
contract SDSimpleLoanSimpleProposal is ISproErrors, ISproEvents {
    /**
     * @dev Mapping of proposals to the borrower's withdrawable collateral tokens
     *      (proposal hash => amount of collateral tokens)
     */
    mapping(bytes32 => uint256) public withdrawableCollateral;

    /* ------------------------------------------------------------ */
    /*              VARIABLES & CONSTANTS DEFINITIONS               */
    /* ------------------------------------------------------------ */

    bytes32 public immutable DOMAIN_SEPARATOR = keccak256(
        abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(abi.encodePacked("SDSimpleLoanSimpleProposal")),
            keccak256(abi.encodePacked(Constants.VERSION)),
            block.chainid,
            address(this)
        )
    );

    PWNRevokedNonce public immutable revokedNonce;
    SDConfig public immutable config;

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
    /*                          CONSTRUCTOR                         */
    /* ------------------------------------------------------------ */

    constructor(address _revokedNonce, address _config) {
        revokedNonce = PWNRevokedNonce(_revokedNonce);
        config = SDConfig(_config);
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
        return _getProposalHash(Constants.PROPOSAL_TYPEHASH, abi.encode(proposal));
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
            revert InvalidDurationStartTime();
        }

        // Make proposal hash
        bytes32 proposalHash = _getProposalHash(Constants.PROPOSAL_TYPEHASH, abi.encode(proposal));

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
        returns (bytes32 proposalHash, Terms memory loanTerms)
    {
        // Decode proposal data
        Proposal memory proposal = decodeProposalData(proposalData);

        // Make proposal hash
        proposalHash = _getProposalHash(Constants.PROPOSAL_TYPEHASH, abi.encode(proposal));

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

        loanTerms = Terms({
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
        bytes32 proposalHash = _getProposalHash(Constants.PROPOSAL_TYPEHASH, abi.encode(proposal));

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
                Math.mulDiv(proposal.availableCreditLimit, config.partialPositionPercentage(), Constants.PERCENTAGE);
            if (creditAmount < minCreditAmount) {
                revert CreditAmountTooSmall({ amount: creditAmount, minimum: minCreditAmount });
            }

            uint256 maxCreditAmount = Math.mulDiv(
                proposal.availableCreditLimit,
                (Constants.PERCENTAGE - config.partialPositionPercentage()),
                Constants.PERCENTAGE
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
