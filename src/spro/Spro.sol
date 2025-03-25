// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IAllowanceTransfer } from "permit2/src/interfaces/IAllowanceTransfer.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { ISpro } from "src/interfaces/ISpro.sol";
import { SproLoan } from "src/spro/SproLoan.sol";
import { SproStorage } from "src/spro/SproStorage.sol";

contract Spro is SproStorage, ISpro, Ownable2Step, ReentrancyGuard {
    using SafeERC20 for IERC20Metadata;
    using SafeCast for uint256;

    /**
     * @dev Data structure for the {repayMultipleLoans} function.
     * @param loanId The Id of a loan.
     * @param loan The loan structure.
     */
    struct LoanWithId {
        uint256 loanId;
        Loan loan;
    }

    /**
     * @param sdex The SDEX token address.
     * @param permit2 The permit2 contract address.
     * @param fee The fixed SDEX fee value.
     * @param partialPositionBps The minimum usage ratio for partial lending (in basis points).
     */
    constructor(address sdex, address permit2, uint256 fee, uint16 partialPositionBps) Ownable(msg.sender) {
        if (sdex == address(0) || permit2 == address(0)) {
            revert ZeroAddress();
        }
        if (partialPositionBps == 0 || partialPositionBps > BPS_DIVISOR / 2) {
            revert IncorrectPercentageValue(partialPositionBps);
        }
        if (fee > MAX_SDEX_FEE) {
            revert ExcessiveFee(fee);
        }

        PERMIT2 = IAllowanceTransfer(permit2);
        SDEX = sdex;
        _loanToken = new SproLoan(address(this));
        _fee = fee;
        _partialPositionBps = partialPositionBps;
    }

    /* -------------------------------------------------------------------------- */
    /*                             External Functions                             */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ISpro
    function setFee(uint256 newFee) external onlyOwner {
        if (newFee > MAX_SDEX_FEE) {
            revert ExcessiveFee(newFee);
        }
        _fee = newFee;
        emit FeeUpdated(newFee);
    }

    /// @inheritdoc ISpro
    function setPartialPositionPercentage(uint16 newPartialPositionBps) external onlyOwner {
        if (newPartialPositionBps == 0 || newPartialPositionBps > BPS_DIVISOR / 2) {
            revert IncorrectPercentageValue(newPartialPositionBps);
        }
        _partialPositionBps = newPartialPositionBps;
        emit PartialPositionBpsUpdated(newPartialPositionBps);
    }

    /// @inheritdoc ISpro
    function setLoanMetadataUri(string memory newMetadataUri) external onlyOwner {
        _loanToken.setLoanMetadataUri(newMetadataUri);
    }

    /// @inheritdoc ISpro
    function getProposalCreditStatus(Proposal calldata proposal)
        external
        view
        returns (uint256 used_, uint256 remaining_)
    {
        bytes32 proposalHash = getProposalHash(proposal);
        if (_proposalsMade[proposalHash]) {
            used_ = _creditUsed[proposalHash];
            remaining_ = proposal.availableCreditLimit - used_;
        } else {
            revert ProposalDoesNotExists();
        }
    }

    /// @inheritdoc ISpro
    function getLoan(uint256 loanId) external view returns (Loan memory loan_) {
        loan_ = _loans[loanId];
    }

    /// @inheritdoc ISpro
    function totalLoanRepaymentAmount(uint256[] calldata loanIds) external view returns (uint256 amount_) {
        if (loanIds.length == 0) return 0;
        address firstCreditAddress = _loans[loanIds[0]].credit;
        for (uint256 i; i < loanIds.length; ++i) {
            uint256 loanId = loanIds[i];
            Loan memory loan = _loans[loanId];
            if (loan.credit != firstCreditAddress) {
                revert DifferentCreditAddress(loan.credit, firstCreditAddress);
            }

            if (loan.status == LoanStatus.NONE) return 0;
            amount_ += loan.principalAmount + loan.fixedInterestAmount;
        }
    }

    /// @inheritdoc ISpro
    function createProposal(Proposal memory proposal, bytes calldata permit2Data) external nonReentrant {
        _makeProposal(proposal);

        // Execute permit2Data for the caller
        if (permit2Data.length > 0) {
            (IAllowanceTransfer.PermitBatch memory permitBatch, bytes memory data) =
                abi.decode(permit2Data, (IAllowanceTransfer.PermitBatch, bytes));
            PERMIT2.permit(msg.sender, permitBatch, data);
            PERMIT2.transferFrom(
                msg.sender, address(this), proposal.collateralAmount.toUint160(), proposal.collateralAddress
            );
            if (_fee > 0) {
                PERMIT2.transferFrom(msg.sender, DEAD_ADDRESS, _fee.toUint160(), address(SDEX));
            }
        } else {
            IERC20Metadata(proposal.collateralAddress).safeTransferFrom(
                msg.sender, address(this), proposal.collateralAmount
            );
            if (_fee > 0) {
                IERC20Metadata(SDEX).safeTransferFrom(msg.sender, DEAD_ADDRESS, _fee);
            }
        }
    }

    /// @inheritdoc ISpro
    function cancelProposal(Proposal memory proposal) external nonReentrant {
        if (msg.sender != proposal.proposer) {
            revert CallerNotProposer();
        }

        bytes32 proposalHash = getProposalHash(proposal);
        if (!_proposalsMade[proposalHash]) {
            revert ProposalDoesNotExists();
        }
        proposal.collateralAmount = _withdrawableCollateral[proposalHash];
        _withdrawableCollateral[proposalHash] = 0;
        _proposalsMade[proposalHash] = false;

        IERC20Metadata(proposal.collateralAddress).safeTransfer(proposal.proposer, proposal.collateralAmount);
        emit ProposalCanceled(proposalHash);
    }

    /// @inheritdoc ISpro
    function createLoan(Proposal calldata proposal, uint256 creditAmount, bytes calldata permit2Data)
        external
        nonReentrant
        returns (uint256 loanId_)
    {
        // Accept proposal and get loan terms
        (bytes32 proposalHash, Terms memory loanTerms) = _acceptProposal(msg.sender, creditAmount, proposal);

        loanId_ = _createLoan(loanTerms);

        emit LoanCreated(loanId_, proposalHash, loanTerms);

        if (permit2Data.length > 0) {
            _permit2Workflows(permit2Data, loanTerms.creditAmount.toUint160(), loanTerms.credit);
        } else {
            IERC20Metadata(loanTerms.credit).safeTransferFrom(
                loanTerms.lender, loanTerms.borrower, loanTerms.creditAmount
            );
        }
    }

    /// @inheritdoc ISpro
    function repayLoan(uint256 loanId, bytes calldata permit2Data) external nonReentrant {
        Loan storage loan = _loans[loanId];

        if (!_isLoanRepayable(loan.status, loan.loanExpiration)) {
            revert LoanCannotBeRepaid();
        }

        uint256 repaymentAmount = loan.principalAmount + loan.fixedInterestAmount;
        if (permit2Data.length > 0) {
            _permit2Workflows(permit2Data, repaymentAmount.toUint160(), loan.credit);
        } else {
            IERC20Metadata(loan.credit).safeTransferFrom(msg.sender, address(this), repaymentAmount);
        }
        IERC20Metadata(loan.collateral).safeTransfer(loan.borrower, loan.collateralAmount);
        loan.status = LoanStatus.PAID_BACK;
        emit LoanPaidBack(loanId);

        address loanOwner = _loanToken.ownerOf(loanId);

        try this.tryClaimRepaidLoan(loanId, repaymentAmount, loan.credit, loanOwner) { }
        catch {
            // Safe transfer can fail. In that case leave the loan token in repaid state and wait for the Loan
            // token owner to claim the repaid credit. Otherwise lender would be able to prevent borrower from
            // repaying the loan
        }
    }

    /// @inheritdoc ISpro
    function repayMultipleLoans(uint256[] calldata loanIds, bytes calldata permit2Data) external nonReentrant {
        if (loanIds.length == 0) return;

        address creditAddress = _loans[loanIds[0]].credit;
        uint256 totalRepaymentAmount;
        LoanWithId[] memory loansToRepay = new LoanWithId[](loanIds.length);
        uint256 numLoansToRepay;

        // Filter loans that can be repaid
        for (uint256 i; i < loanIds.length; ++i) {
            uint256 loanId = loanIds[i];
            Loan storage loan = _loans[loanId];

            // Checks: loan can be repaid & credit address is the same for all loanIds
            if (_isLoanRepayable(loan.status, loan.loanExpiration)) {
                if (loan.credit != creditAddress) {
                    revert DifferentCreditAddress(loan.credit, creditAddress);
                }
                // Update loan to repaid state and increment the total repayment amount
                totalRepaymentAmount += loan.principalAmount + loan.fixedInterestAmount;
                loan.status = LoanStatus.PAID_BACK;
                emit LoanPaidBack(loanId);

                loansToRepay[numLoansToRepay] = LoanWithId(loanId, loan);
                numLoansToRepay++;
            }
        }

        // Transfer the repaid credit to the protocol
        if (permit2Data.length > 0) {
            _permit2Workflows(permit2Data, totalRepaymentAmount.toUint160(), creditAddress);
        } else {
            IERC20Metadata(creditAddress).safeTransferFrom(msg.sender, address(this), totalRepaymentAmount);
        }

        for (uint256 i; i < numLoansToRepay; ++i) {
            LoanWithId memory loanData = loansToRepay[i];
            Loan memory loan = loanData.loan;
            uint256 loanId = loanData.loanId;

            IERC20Metadata(loan.collateral).safeTransfer(loan.borrower, loan.collateralAmount);

            address loanOwner = _loanToken.ownerOf(loanId);
            // If current loan owner is not original lender, the loan cannot be repaid directly

            try this.tryClaimRepaidLoan(loanId, loan.principalAmount + loan.fixedInterestAmount, loan.credit, loanOwner)
            { } catch {
                // Safe transfer can fail. In that case leave the loan token in repaid state and wait for the loan
                // token owner to claim the repaid credit. Otherwise lender would be able to prevent borrower from
                // repaying the loan
            }
        }
    }

    /// @inheritdoc ISpro
    function tryClaimRepaidLoan(uint256 loanId, uint256 creditAmount, address creditAddress, address loanOwner)
        external
    {
        if (msg.sender != address(this)) {
            revert UnauthorizedCaller();
        }

        // Delete loan data & burn loan token
        _deleteLoan(loanId);
        IERC20Metadata(creditAddress).safeTransfer(loanOwner, creditAmount);
        emit LoanClaimed(loanId, false);
    }

    /// @inheritdoc ISpro
    function claimMultipleLoans(uint256[] calldata loanIds) external {
        uint256 l = loanIds.length;
        for (uint256 i; i < l; ++i) {
            claimLoan(loanIds[i]);
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                              Public Functions                              */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ISpro
    function getProposalHash(Proposal memory proposal) public pure returns (bytes32 proposalHash_) {
        return keccak256(abi.encode(proposal));
    }

    /// @inheritdoc ISpro
    function claimLoan(uint256 loanId) public {
        Loan memory loan = _loans[loanId];

        if (_loanToken.ownerOf(loanId) != msg.sender) {
            revert CallerNotLoanTokenHolder();
        }

        if (loan.status == LoanStatus.PAID_BACK) {
            // Loan has been paid back
            _settleLoanClaim(loanId, loan, msg.sender, false);
        } else if (loan.status == LoanStatus.RUNNING && loan.loanExpiration <= block.timestamp) {
            // Loan is running but expired
            _settleLoanClaim(loanId, loan, msg.sender, true);
        } else {
            revert LoanRunning();
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                             Internal Functions                             */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Check if the loan can be repaid.
     * @param status The loan status.
     * @param loanExpiration The loan expiration timestamp.
     * @return canBeRepaid_ True if the loan can be repaid.
     */
    function _isLoanRepayable(LoanStatus status, uint40 loanExpiration) internal view returns (bool canBeRepaid_) {
        if (status != LoanStatus.RUNNING) {
            return canBeRepaid_;
        }
        if (loanExpiration <= block.timestamp) {
            return canBeRepaid_;
        }
        return true;
    }

    /**
     * @notice Make a proposal.
     * @param proposal The proposal structure.
     */
    function _makeProposal(Proposal memory proposal) internal {
        if (proposal.startTimestamp >= proposal.loanExpiration) {
            revert InvalidDurationStartTime();
        }

        if (proposal.availableCreditLimit == 0) {
            revert AvailableCreditLimitZero();
        }

        // Check minimum loan duration
        if (proposal.loanExpiration - proposal.startTimestamp < MIN_LOAN_DURATION) {
            revert InvalidDuration(proposal.loanExpiration - proposal.startTimestamp, MIN_LOAN_DURATION);
        }

        proposal.partialPositionBps = _partialPositionBps;
        proposal.proposer = msg.sender;

        bytes32 proposalHash = getProposalHash(proposal);

        if (_proposalsMade[proposalHash]) {
            revert ProposalAlreadyExists();
        }

        _proposalsMade[proposalHash] = true;
        _withdrawableCollateral[proposalHash] = proposal.collateralAmount;

        emit ProposalCreated(proposalHash, proposal.proposer, proposal);
    }

    /**
     * @notice Accept a proposal and create new loan terms.
     * @param acceptor The address of the proposal acceptor.
     * @param creditAmount The amount of credit to lend.
     * @param proposal The proposal structure.
     * @return proposalHash_ The hash of the proposal.
     * @return loanTerms_ The terms of the loan.
     */
    function _acceptProposal(address acceptor, uint256 creditAmount, Proposal memory proposal)
        internal
        returns (bytes32 proposalHash_, Terms memory loanTerms_)
    {
        proposalHash_ = getProposalHash(proposal);

        // Try to accept proposal
        _acceptProposal(
            acceptor,
            creditAmount,
            proposalHash_,
            ProposalBase(
                proposal.collateralAddress,
                proposal.availableCreditLimit,
                proposal.startTimestamp,
                proposal.proposer,
                proposal.partialPositionBps
            )
        );

        // Create loan terms object
        uint256 collateralUsed_ = (creditAmount * proposal.collateralAmount) / proposal.availableCreditLimit;
        uint256 fixedInterestAmount =
            Math.mulDiv(creditAmount, proposal.fixedInterestAmount, proposal.availableCreditLimit, Math.Rounding.Ceil);

        loanTerms_ = Terms(
            acceptor,
            proposal.proposer,
            proposal.startTimestamp,
            proposal.loanExpiration,
            proposal.collateralAddress,
            collateralUsed_,
            proposal.creditAddress,
            creditAmount,
            fixedInterestAmount
        );

        _withdrawableCollateral[proposalHash_] -= collateralUsed_;
    }

    /**
     * @notice Accept a proposal and update credit used.
     * @param acceptor The address of the proposal acceptor.
     * @param creditAmount The amount of credit to lend.
     * @param proposalHash The hash of the proposal.
     * @param proposal The proposal structure.
     */
    function _acceptProposal(address acceptor, uint256 creditAmount, bytes32 proposalHash, ProposalBase memory proposal)
        internal
    {
        if (!_proposalsMade[proposalHash]) {
            revert ProposalDoesNotExists();
        }
        if (proposal.proposer == acceptor) {
            revert AcceptorIsProposer(acceptor);
        }
        // Check proposal is not expired
        if (block.timestamp >= proposal.startTimestamp) {
            revert Expired(block.timestamp, proposal.startTimestamp);
        }

        uint256 used = _creditUsed[proposalHash];
        uint256 total = used + creditAmount;
        if (total < proposal.availableCreditLimit) {
            // Credit may only be between min and max amounts if it is not exact
            uint256 minAmount = Math.mulDiv(proposal.availableCreditLimit, proposal.partialPositionBps, BPS_DIVISOR);
            if (creditAmount < minAmount) {
                revert CreditAmountTooSmall(creditAmount, minAmount);
            }
            if (proposal.availableCreditLimit - total < minAmount) {
                revert CreditAmountRemainingBelowMinimum(creditAmount, minAmount);
            }
        } else if (total > proposal.availableCreditLimit) {
            revert AvailableCreditLimitExceeded(proposal.availableCreditLimit - used);
        }

        _creditUsed[proposalHash] += creditAmount;
    }

    /**
     * @notice Create a new loan token and store loan data.
     * @param loanTerms The terms of the loan.
     * @return loanId_ The Id of the new loan.
     */
    function _createLoan(Terms memory loanTerms) internal returns (uint256 loanId_) {
        loanId_ = _loanToken.mint(loanTerms.lender);

        Loan storage loan = _loans[loanId_];
        loan.status = LoanStatus.RUNNING;
        loan.lender = loanTerms.lender;
        loan.borrower = loanTerms.borrower;
        loan.startTimestamp = loanTerms.startTimestamp;
        loan.loanExpiration = loanTerms.loanExpiration;
        loan.collateral = loanTerms.collateral;
        loan.collateralAmount = loanTerms.collateralAmount;
        loan.credit = loanTerms.credit;
        loan.principalAmount = loanTerms.creditAmount;
        loan.fixedInterestAmount = loanTerms.fixedInterestAmount;
    }

    /**
     * @notice Settle the loan claim.
     * @param loanId The Id of the loan to settle.
     * @param loan The loan structure.
     * @param loanOwner The owner of the loan token.
     * @param defaulted True if the loan was defaulted.
     */
    function _settleLoanClaim(uint256 loanId, Loan memory loan, address loanOwner, bool defaulted) internal {
        // Store in memory before deleting the loan
        address asset = defaulted ? loan.collateral : loan.credit;
        uint256 assetAmount = defaulted ? loan.collateralAmount : loan.principalAmount + loan.fixedInterestAmount;

        // Delete loan data & burn loan token before calling safe transfer
        _deleteLoan(loanId);
        emit LoanClaimed(loanId, defaulted);
        IERC20Metadata(asset).safeTransfer(loanOwner, assetAmount);
    }

    /**
     * @notice Delete a loan from the storage and burn the token.
     * @param loanId The Id of the loan to delete.
     */
    function _deleteLoan(uint256 loanId) internal {
        _loanToken.burn(loanId);
        delete _loans[loanId];
    }

    /**
     * @notice Transfer an asset amount to the protocol via permit2.
     * @param permit2Data The permit2 data.
     * @param amount The amount to transfer.
     * @param token The asset address.
     */
    function _permit2Workflows(bytes memory permit2Data, uint160 amount, address token) internal {
        (IAllowanceTransfer.PermitSingle memory permitSign, bytes memory data) =
            abi.decode(permit2Data, (IAllowanceTransfer.PermitSingle, bytes));
        PERMIT2.permit(msg.sender, permitSign, data);
        PERMIT2.transferFrom(msg.sender, address(this), amount, token);
    }
}
