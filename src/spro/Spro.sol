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

        PERMIT2 = IAllowanceTransfer(permit2);
        SDEX = sdex;
        _loanToken = new SproLoan(address(this));
        _fee = fee;
        _partialPositionBps = partialPositionBps;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  EXTERNAL                                  */
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
        bytes32 proposalHash = keccak256(abi.encode(proposal));
        if (_proposalsMade[proposalHash]) {
            used_ = _creditUsed[proposalHash];
            remaining_ = proposal.availableCreditLimit - used_;
        } else {
            revert ProposalDoesNotExists();
        }
    }

    /// @inheritdoc ISpro
    function getLoan(uint256 loanId)
        external
        view
        returns (Loan memory loan_, uint256 repaymentAmount_, address loanOwner_)
    {
        loan_ = _loans[loanId];
        loanOwner_ = loan_.status != LoanStatus.NONE ? _loanToken.ownerOf(loanId) : address(0);
        repaymentAmount_ = loan_.principalAmount + loan_.fixedInterestAmount;
    }

    /// @inheritdoc ISpro
    function getProposalHash(Proposal calldata proposal) external pure returns (bytes32 proposalHash_) {
        return keccak256(abi.encode(proposal));
    }

    /// @inheritdoc ISpro
    function totalLoanRepaymentAmount(uint256[] calldata loanIds, address creditAddress)
        external
        view
        returns (uint256 amount_)
    {
        uint256 l = loanIds.length;
        for (uint256 i; i < l; ++i) {
            uint256 loanId = loanIds[i];
            Loan memory loan = _loans[loanId];
            _checkLoanCreditAddress(loan.credit, creditAddress);

            if (loan.status == LoanStatus.NONE) return 0;

            amount_ += loan.principalAmount + loan.fixedInterestAmount;
        }
    }

    /// @inheritdoc ISpro
    function createProposal(Proposal calldata proposal, bytes calldata permit2Data) external nonReentrant {
        (address collateral, uint256 collateralAmount) = _makeProposal(proposal);

        // Execute permit2Data for the caller
        if (permit2Data.length > 0) {
            (IAllowanceTransfer.PermitBatch memory permitBatch, bytes memory data) =
                abi.decode(permit2Data, (IAllowanceTransfer.PermitBatch, bytes));
            PERMIT2.permit(msg.sender, permitBatch, data);
            PERMIT2.transferFrom(msg.sender, address(this), collateralAmount.toUint160(), collateral);
            if (_fee > 0) {
                PERMIT2.transferFrom(msg.sender, DEAD_ADDRESS, _fee.toUint160(), address(SDEX));
            }
        } else {
            IERC20Metadata(collateral).safeTransferFrom(msg.sender, address(this), collateralAmount);
            if (_fee > 0) {
                IERC20Metadata(SDEX).safeTransferFrom(msg.sender, DEAD_ADDRESS, _fee);
            }
        }
    }

    /// @inheritdoc ISpro
    function cancelProposal(Proposal calldata proposal) external nonReentrant {
        Proposal memory newProposal = _cancelProposal(proposal);

        if (msg.sender != newProposal.proposer) {
            revert CallerNotProposer();
        }

        IERC20Metadata(newProposal.collateralAddress).safeTransfer(newProposal.proposer, newProposal.collateralAmount);
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
        Loan memory loan = _loans[loanId];

        if (!_isLoanRepayable(loan.status, loan.loanExpiration)) {
            revert LoanCannotBeRepaid();
        }

        uint256 repaymentAmount = _updateRepaidLoan(loanId);

        if (permit2Data.length > 0) {
            _permit2Workflows(permit2Data, repaymentAmount.toUint160(), loan.credit);
        } else {
            IERC20Metadata(loan.credit).safeTransferFrom(msg.sender, address(this), repaymentAmount);
        }
        IERC20Metadata(loan.collateral).safeTransfer(loan.borrower, loan.collateralAmount);

        // Try to repay directly
        try this.tryClaimRepaidLoan(loanId, repaymentAmount, _loanToken.ownerOf(loanId)) { }
        catch {
            // Note: Safe transfer can fail. In that case leave the loan token in repaid state and wait for the Loan
            // token owner to claim the repaid credit. Otherwise lender would be able to prevent borrower from
            // repaying the loan.
        }
    }

    /// @inheritdoc ISpro
    function repayMultipleLoans(uint256[] calldata loanIds, address creditAddress, bytes calldata permit2Data)
        external
        nonReentrant
    {
        uint256 totalRepaymentAmount;
        LoanWithId[] memory loansToRepay = new LoanWithId[](loanIds.length);
        uint256 numLoansToRepay;

        // Filter loans that can be repaid
        uint256 l = loanIds.length;
        for (uint256 i; i < l; ++i) {
            uint256 loanId = loanIds[i];
            Loan memory loan = _loans[loanId];

            // Checks: loan can be repaid & credit address is the same for all loanIds
            if (_isLoanRepayable(loan.status, loan.loanExpiration)) {
                _checkLoanCreditAddress(loan.credit, creditAddress);
                // Update loan to repaid state and increment the total repayment amount
                totalRepaymentAmount += _updateRepaidLoan(loanId);
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

            // Try to repay directly (for each loanId)
            try this.tryClaimRepaidLoan(
                loanId, loan.principalAmount + loan.fixedInterestAmount, _loanToken.ownerOf(loanId)
            ) { } catch {
                // Note: Safe transfer can fail. In that case leave the loan token in repaid state and wait for the Loan
                // token owner to claim the repaid credit. Otherwise lender would be able to prevent borrower from
                // repaying the loan.
            }
        }
    }

    /// @inheritdoc ISpro
    function tryClaimRepaidLoan(uint256 loanId, uint256 creditAmount, address loanOwner) external {
        if (msg.sender != address(this)) {
            revert UnauthorizedCaller();
        }

        Loan memory loan = _loans[loanId];

        if (loan.status != LoanStatus.PAID_BACK) return;

        // If current loan owner is not original lender, the loan cannot be repaid directly, return without revert.
        if (loan.lender != loanOwner) return;

        // Delete loan data & burn loan token before calling safe transfer
        _deleteLoan(loanId);

        emit LoanClaimed(loanId, false);

        // End here if the credit amount is zero
        if (creditAmount == 0) return;

        // Note: Zero credit amount can happen when the loan is refinanced by the original lender.

        IERC20Metadata(loan.credit).safeTransfer(loanOwner, creditAmount);

        // Note: If the transfer fails, the loan token will remain in repaid state and the loan token owner
        // will be able to claim the repaid credit. Otherwise lender would be able to prevent borrower from
        // repaying the loan.
    }

    /// @inheritdoc ISpro
    function claimMultipleLoans(uint256[] calldata loanIds) external {
        uint256 l = loanIds.length;
        for (uint256 i; i < l; ++i) {
            claimLoan(loanIds[i]);
        }
    }

    /// @inheritdoc ISpro
    function claimLoan(uint256 loanId) public {
        Loan memory loan = _loans[loanId];

        if (_loanToken.ownerOf(loanId) != msg.sender) {
            revert CallerNotLoanTokenHolder();
        }

        LoanStatus status = loan.status;
        if (status == LoanStatus.PAID_BACK) {
            // Loan has been paid back
            _settleLoanClaim(loanId, msg.sender, false);
        } else if (status == LoanStatus.RUNNING && loan.loanExpiration <= block.timestamp) {
            // Loan is running but expired
            _settleLoanClaim(loanId, msg.sender, true);
        } else {
            revert LoanRunning();
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                  INTERNAL                                  */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Check that the loan credit address matches the expected credit address.
     * @param loanCreditAddress The loan credit address.
     * @param expectedCreditAddress The expected credit address.
     */
    function _checkLoanCreditAddress(address loanCreditAddress, address expectedCreditAddress) internal pure {
        if (loanCreditAddress != expectedCreditAddress) {
            revert DifferentCreditAddress(loanCreditAddress, expectedCreditAddress);
        }
    }

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
     * @notice Return a Loan status associated with a loan id.
     * @param loanId The Id of a loan.
     * @return status_ The loan status.
     */
    function _getLoanStatus(uint256 loanId) internal view returns (LoanStatus status_) {
        Loan memory loan = _loans[loanId];
        return (loan.status == LoanStatus.RUNNING && loan.loanExpiration <= block.timestamp)
            ? LoanStatus.EXPIRED
            : loan.status;
    }

    /**
     * @notice Make a proposal.
     * @param proposal The proposal structure.
     * @return collateral_ The address of the collateral token.
     * @return collateralAmount_ The amount of collateral.
     */
    function _makeProposal(Proposal memory proposal)
        internal
        returns (address collateral_, uint256 collateralAmount_)
    {
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

        proposal.minAmountBorrowed = Math.mulDiv(proposal.availableCreditLimit, _partialPositionBps, BPS_DIVISOR);
        proposal.proposer = msg.sender;

        bytes32 proposalHash = keccak256(abi.encode(proposal));
        _makeProposal(proposalHash);

        collateral_ = proposal.collateralAddress;
        collateralAmount_ = proposal.collateralAmount;
        _withdrawableCollateral[proposalHash] = collateralAmount_;

        emit ProposalCreated(proposalHash, proposal.proposer, proposal);
    }

    /**
     * @notice Cancel a proposal.
     * @param proposal The proposal structure.
     * @return proposal_ The new proposal structure.
     */
    function _cancelProposal(Proposal memory proposal) internal returns (Proposal memory proposal_) {
        proposal_ = proposal;

        bytes32 proposalHash = keccak256(abi.encode(proposal_));
        proposal_.collateralAmount = _withdrawableCollateral[proposalHash];
        delete _withdrawableCollateral[proposalHash];

        _proposalsMade[proposalHash] = false;

        emit ProposalCanceled(proposalHash);
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
        proposalHash_ = keccak256(abi.encode(proposal));

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
                proposal.minAmountBorrowed
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
     * @notice Make an on-chain proposal.
     * @dev Function will mark a proposal hash as proposed.
     * @param proposalHash Proposal hash.
     */
    function _makeProposal(bytes32 proposalHash) internal {
        if (_proposalsMade[proposalHash]) {
            revert ProposalAlreadyExists();
        }

        _proposalsMade[proposalHash] = true;
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
        if (used + creditAmount < proposal.availableCreditLimit) {
            // Credit may only be between min and max amounts if it is not exact
            uint256 minAmountBorrowed = proposal.minAmountBorrowed;
            if (creditAmount < minAmountBorrowed) {
                revert CreditAmountTooSmall(creditAmount, minAmountBorrowed);
            }
            if (proposal.availableCreditLimit - minAmountBorrowed < used + creditAmount) {
                revert CreditAmountRemainingBelowMinimum(creditAmount, minAmountBorrowed);
            }
        } else if (used + creditAmount > proposal.availableCreditLimit) {
            revert AvailableCreditLimitExceeded(used + creditAmount, proposal.availableCreditLimit);
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
     * @notice Update loan status to repaid.
     * @param loanId The Id of the loan to update.
     * @return repaidAmount_ The repaid amount.
     */
    function _updateRepaidLoan(uint256 loanId) internal returns (uint256 repaidAmount_) {
        Loan storage loan = _loans[loanId];

        // Move loan to repaid state and wait for the loan owner to claim the repaid credit
        loan.status = LoanStatus.PAID_BACK;

        emit LoanPaidBack(loanId);
        return loan.principalAmount + loan.fixedInterestAmount;
    }

    /**
     * @notice Settle the loan claim.
     * @param loanId The Id of the loan to settle.
     * @param loanOwner The owner of the loan token.
     * @param defaulted True if the loan was defaulted.
     */
    function _settleLoanClaim(uint256 loanId, address loanOwner, bool defaulted) internal {
        Loan memory loan = _loans[loanId];

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
     * @param permit2Data The permit data.
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
