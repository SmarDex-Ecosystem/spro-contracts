// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import {MultiToken} from "MultiToken/MultiToken.sol";

import {SDSimpleLoan} from "pwn/loan/terms/simple/loan/SDSimpleLoan.sol";
import {SDSimpleLoanProposal} from "pwn/loan/terms/simple/proposal/SDSimpleLoanProposal.sol";
import {SDTransfer} from "pwn/loan/lib/SDTransfer.sol";
import {PWNHubTags} from "pwn/hub/PWNHubTags.sol";
import {AddressMissingHubTag} from "pwn/PWNErrors.sol";

/**
 * @title SD Simple Loan Simple Proposal
 * @notice Contract for creating and accepting simple loan proposals.
 */
contract SDSimpleLoanSimpleProposal is SDSimpleLoanProposal {
    using MultiToken for MultiToken.Asset;
    using SDTransfer for MultiToken.Asset;

    /* ------------------------------------------------------------ */
    /*  VARIABLES & CONSTANTS DEFINITIONS                        */
    /* ------------------------------------------------------------ */

    string public constant VERSION = "1.0";

    /**
     * @dev EIP-712 simple proposal struct type hash.
     */
    bytes32 public constant PROPOSAL_TYPEHASH = keccak256(
        "Proposal(uint8 collateralCategory,address collateralAddress,uint256 collateralId,uint256 collateralAmount,bool checkCollateralStateFingerprint,bytes32 collateralStateFingerprint,address creditAddress,uint256 availableCreditLimit,uint256 fixedInterestAmount,uint40 accruingInterestAPR,uint32 duration,uint40 expiration,address proposer,bytes32 proposerSpecHash,uint256 nonceSpace,uint256 nonce,address loanContract)"
    );

    /**
     * @notice Construct defining a simple proposal.
     * @param collateralCategory Category of an asset used as a collateral (0 == ERC20, 1 == ERC721, 2 == ERC1155).
     * @param collateralAddress Address of an asset used as a collateral.
     * @param collateralId Token id of an asset used as a collateral, in case of ERC20 should be 0.
     * @param collateralAmount Amount of tokens used as a collateral, in case of ERC721 should be 0.
     * @param checkCollateralStateFingerprint If true, the collateral state fingerprint will be checked during proposal acceptance.
     * @param collateralStateFingerprint Fingerprint of a collateral state defined by ERC5646.
     * @param creditAddress Address of an asset which is lended to a borrower.
     * @param availableCreditLimit Available credit limit for the proposal. It is the maximum amount of tokens which can be borrowed using the proposal. If non-zero, proposal can be accepted more than once, until the credit limit is reached.
     * @param fixedInterestAmount Fixed interest amount in credit tokens. It is the minimum amount of interest which has to be paid by a borrower.
     * @param accruingInterestAPR Accruing interest APR with 2 decimals.
     * @param duration Loan duration in seconds.
     * @param expiration Proposal expiration timestamp in seconds.
     * @param proposer Address of a proposal signer. If `isOffer` is true, the proposer is the lender. If `isOffer` is false, the proposer is the borrower.
     * @param proposerSpecHash Hash of a proposer specific data, which must be provided during a loan creation.
     * @param nonceSpace Nonce space of a proposal nonce. All nonces in the same space can be revoked at once.
     * @param nonce Additional value to enable identical proposals in time. Without it, it would be impossible to make again proposal, which was once revoked. Can be used to create a group of proposals, where accepting one proposal will make other proposals in the group revoked.
     * @param loanContract Address of a loan contract that will create a loan from the proposal.
     */
    struct Proposal {
        MultiToken.Category collateralCategory;
        address collateralAddress;
        uint256 collateralId;
        uint256 collateralAmount;
        bool checkCollateralStateFingerprint;
        bytes32 collateralStateFingerprint;
        address creditAddress;
        uint256 availableCreditLimit;
        uint256 fixedInterestAmount;
        uint24 accruingInterestAPR;
        uint32 duration;
        uint40 expiration;
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
    mapping(bytes32 => MultiToken.Asset) public withdrawableCollateral;

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

    /* ------------------------------------------------------------ */
    /*                          CONSTRUCTOR                         */
    /* ------------------------------------------------------------ */

    constructor(address _hub, address _revokedNonce, address _config)
        SDSimpleLoanProposal(_hub, _revokedNonce, _config, "SDSimpleLoanSimpleProposal", VERSION)
    {}

    /* ------------------------------------------------------------ */
    /*                          EXTERNALS                           */
    /* ------------------------------------------------------------ */

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
     * @inheritdoc SDSimpleLoanProposal
     */
    function makeProposal(bytes calldata proposalData)
        external
        override
        returns (address proposer, MultiToken.Asset memory collateral, address creditAddress, uint256 creditLimit)
    {
        // Decode proposal data
        Proposal memory proposal = decodeProposalData(proposalData);

        // Make proposal hash
        bytes32 proposalHash = _getProposalHash(PROPOSAL_TYPEHASH, abi.encode(proposal));

        // Try to make proposal
        _makeProposal(proposalHash, proposal.loanContract);

        collateral = MultiToken.Asset({
            category: proposal.collateralCategory,
            assetAddress: proposal.collateralAddress,
            id: proposal.collateralId,
            amount: proposal.collateralAmount
        });
        withdrawableCollateral[proposalHash] = collateral;
        creditAddress = proposal.creditAddress;
        creditLimit = proposal.availableCreditLimit;

        emit ProposalMade(proposalHash, proposer = proposal.proposer, proposal);
    }

    /**
     * @inheritdoc SDSimpleLoanProposal
     */
    function acceptProposal(address acceptor, uint256 creditAmount, bytes calldata proposalData)
        external
        override
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
                collateralId: proposal.collateralId,
                checkCollateralStateFingerprint: proposal.checkCollateralStateFingerprint,
                collateralStateFingerprint: proposal.collateralStateFingerprint,
                availableCreditLimit: proposal.availableCreditLimit,
                expiration: proposal.expiration,
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
            duration: proposal.duration,
            collateral: MultiToken.Asset({
                category: proposal.collateralCategory,
                assetAddress: proposal.collateralAddress,
                id: proposal.collateralId,
                amount: collateralUsed_
            }),
            credit: MultiToken.ERC20({assetAddress: proposal.creditAddress, amount: creditAmount}),
            fixedInterestAmount: proposal.fixedInterestAmount,
            accruingInterestAPR: proposal.accruingInterestAPR,
            lenderSpecHash: bytes32(0),
            borrowerSpecHash: proposal.proposerSpecHash
        });

        if (proposal.collateralCategory == MultiToken.Category.ERC20) {
            withdrawableCollateral[proposalHash].amount -= collateralUsed_;
        } else if (proposal.collateralCategory == MultiToken.Category.ERC721) {
            _checkCompleteLoan(creditAmount, proposal.availableCreditLimit);

            withdrawableCollateral[proposalHash].amount = type(uint256).max; // requirement: has to be non-zero
        } else if (proposal.collateralCategory == MultiToken.Category.ERC1155) {
            if (proposal.collateralAmount == 1) {
                _checkCompleteLoan(creditAmount, proposal.availableCreditLimit);
            }

            withdrawableCollateral[proposalHash].amount -= collateralUsed_;
        }
    }

    /**
     * @notice Cancels a proposal and resets withdrawable collateral.
     * @dev Revokes the nonce if still usable and block.timestamp is < proposal expiration.
     * @param proposalData Encoded proposal data.
     * @return proposer Address of the borrower/proposer.
     * @return collateral Collateral token/s as a MultiToken.Asset struct.
     */
    function cancelProposal(bytes calldata proposalData)
        external
        override
        returns (address proposer, MultiToken.Asset memory collateral)
    {
        // Decode proposal data
        Proposal memory proposal = decodeProposalData(proposalData);

        // Caller must be valid loan contract
        if (msg.sender != proposal.loanContract) {
            revert CallerNotLoanContract({caller: msg.sender, loanContract: proposal.loanContract});
        }
        if (!hub.hasTag(proposal.loanContract, PWNHubTags.ACTIVE_LOAN)) {
            revert AddressMissingHubTag({addr: proposal.loanContract, tag: PWNHubTags.ACTIVE_LOAN});
        }

        // Make proposal hash
        bytes32 proposalHash = _getProposalHash(PROPOSAL_TYPEHASH, abi.encode(proposal));

        proposer = proposal.proposer;
        collateral = withdrawableCollateral[proposalHash];
        delete withdrawableCollateral[proposalHash];

        // Revokes nonce if nonce is still usable
        if (block.timestamp < proposal.expiration) {
            if (revokedNonce.isNonceUsable(proposal.proposer, proposal.nonceSpace, proposal.nonce)) {
                revokedNonce.revokeNonce(proposal.proposer, proposal.nonceSpace, proposal.nonce);
            }
        }
    }

    /* ------------------------------------------------------------ */
    /*                          INTERNALS                           */
    /* ------------------------------------------------------------ */

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
