// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { IAllowanceTransfer } from "permit2/src/interfaces/IAllowanceTransfer.sol";

import { SproConstantsLibrary as Constants } from "src/libraries/SproConstantsLibrary.sol";
import { ISpro } from "src/interfaces/ISpro.sol";
import { SproLoan } from "src/spro/SproLoan.sol";
import { SproVault } from "src/spro/SproVault.sol";
import { SproStorage } from "src/spro/SproStorage.sol";

contract Spro is SproVault, SproStorage, ISpro, Ownable2Step, ReentrancyGuard {
    using SafeCast for uint256;

    /**
     * @dev Data structure for the {repayMultipleLoans} function.
     * @param loanId Id of a loan.
     * @param loan Loan struct.
     */
    struct LoadWithId {
        uint256 loanId;
        Loan loan;
    }

    /* ------------------------------------------------------------ */
    /*                          CONSTRUCTOR                         */
    /* ------------------------------------------------------------ */

    /**
     * @param sdex Address of SDEX token.
     * @param permit2 Address of the Permit2 contract.
     * @param fee Fee in SDEX.
     * @param percentage Partial position percentage.
     */
    constructor(address sdex, address permit2, uint256 fee, uint16 percentage) Ownable(msg.sender) {
        if (sdex == address(0) || permit2 == address(0)) {
            revert ZeroAddress();
        }
        if (percentage == 0 || percentage > Constants.BPS_DIVISOR / 2) {
            revert IncorrectPercentageValue(percentage);
        }

        PERMIT2 = IAllowanceTransfer(permit2);
        SDEX = sdex;
        _loanToken = new SproLoan(address(this));
        _fee = fee;
        _partialPositionBps = percentage;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   SETTER                                   */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ISpro
    function setFee(uint256 newFee) external onlyOwner {
        if (newFee > Constants.MAX_SDEX_FEE) {
            revert ExcessiveFee(newFee);
        }
        _fee = newFee;
        emit FeeUpdated(newFee);
    }

    /// @inheritdoc ISpro
    function setPartialPositionPercentage(uint16 percentage) external onlyOwner {
        if (percentage == 0) {
            revert ZeroPercentageValue();
        }
        if (percentage > Constants.BPS_DIVISOR / 2) {
            revert IncorrectPercentageValue(percentage);
        }
        _partialPositionBps = percentage;
        emit PartialPositionBpsUpdated(percentage);
    }

    /// @inheritdoc ISpro
    function setLoanMetadataUri(string memory newMetadataUri) external onlyOwner {
        _loanToken.setLoanMetadataUri(newMetadataUri);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   GETTER                                   */
    /* -------------------------------------------------------------------------- */

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
            revert ProposalNotMade();
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
    function getProposalHash(Proposal calldata proposal) external pure returns (bytes32) {
        return keccak256(abi.encode(proposal));
    }

    /* -------------------------------------------------------------------------- */
    /*                                    VIEW                                    */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ISpro
    function totalLoanRepaymentAmount(uint256[] calldata loanIds, address creditAddress)
        external
        view
        returns (uint256 amount_)
    {
        for (uint256 i; i < loanIds.length; ++i) {
            uint256 loanId = loanIds[i];
            Loan memory loan = _loans[loanId];
            _checkLoanCreditAddress(loan.credit, creditAddress);
            // Check non-existent loan
            if (loan.status == LoanStatus.NONE) return 0;

            // Add loan principal with accrued interest
            amount_ += loan.principalAmount + loan.fixedInterestAmount;
        }
    }

    /* ------------------------------------------------------------ */
    /*                      CREATE PROPOSAL                         */
    /* ------------------------------------------------------------ */

    /// @inheritdoc ISpro
    function createProposal(Proposal calldata proposal, bytes calldata permit2Data) external nonReentrant {
        // Make the proposal
        (address collateral, uint256 collateralAmount) = _makeProposal(proposal);

        // Execute permit2Data for the caller
        if (permit2Data.length > 0) {
            (IAllowanceTransfer.PermitBatch memory permitBatch, bytes memory data) =
                abi.decode(permit2Data, (IAllowanceTransfer.PermitBatch, bytes));
            PERMIT2.permit(msg.sender, permitBatch, data);
            PERMIT2.transferFrom(msg.sender, address(this), collateralAmount.toUint160(), collateral);
            // Fees to address(0xdead)(burned)
            if (_fee > 0) {
                PERMIT2.transferFrom(msg.sender, address(0xdead), _fee.toUint160(), address(SDEX));
            }
        } else {
            // Transfer collateral to Vault
            _pushFrom(collateral, collateralAmount, msg.sender, address(this));
            // Fees to address(0xdead)(burned)
            if (_fee > 0) {
                _pushFrom(SDEX, _fee, msg.sender, address(0xdead));
            }
        }
    }

    /* ------------------------------------------------------------ */
    /*        CANCEL PROPOSAL AND WITHDRAW UNUSED COLLATERAL        */
    /* ------------------------------------------------------------ */

    /// @inheritdoc ISpro
    function cancelProposal(Proposal calldata proposal) external nonReentrant {
        Proposal memory newProposal = _cancelProposal(proposal);

        // The caller must be the proposer
        if (msg.sender != newProposal.proposer) {
            revert CallerNotProposer();
        }

        // Transfers withdrawable collateral to the proposer/borrower
        _push(newProposal.collateralAddress, newProposal.collateralAmount, newProposal.proposer);
    }

    /* ------------------------------------------------------------ */
    /*                          CREATE LOAN                         */
    /* ------------------------------------------------------------ */

    /// @inheritdoc ISpro
    function createLoan(Proposal calldata proposal, uint256 creditAmount, bytes calldata permit2Data)
        external
        nonReentrant
        returns (uint256 loanId_)
    {
        // Accept proposal and get loan terms
        (bytes32 proposalHash, Terms memory loanTerms) = _acceptProposal(msg.sender, creditAmount, proposal);

        // Create a new loan
        loanId_ = _createLoan(loanTerms);

        emit LoanCreated(loanId_, proposalHash, loanTerms);

        // Execute permit2Data for the caller
        if (permit2Data.length > 0) {
            _permit2Workflows(permit2Data, loanTerms.creditAmount.toUint160(), loanTerms.credit);
        } else {
            // Transfer credit to borrower
            _pushFrom(loanTerms.credit, loanTerms.creditAmount, loanTerms.lender, loanTerms.borrower);
        }
    }

    /* ------------------------------------------------------------ */
    /*                          REPAY LOAN                          */
    /* ------------------------------------------------------------ */

    /// @inheritdoc ISpro
    function repayLoan(uint256 loanId, bytes calldata permit2Data) external nonReentrant {
        Loan memory loan = _loans[loanId];

        if (!_isLoanRepayable(loan.status, loan.loanExpiration)) {
            revert LoanCannotBeRepaid();
        }

        // Update loan to repaid state and get the repayment amount
        uint256 repaymentAmount = _updateRepaidLoan(loanId);

        // Execute permit2Data for the caller
        if (permit2Data.length > 0) {
            _permit2Workflows(permit2Data, repaymentAmount.toUint160(), loan.credit);
        } else {
            // Transfer the repaid credit to the Vault
            _pushFrom(loan.credit, repaymentAmount, msg.sender, address(this));
        }

        // Transfer collateral back to borrower
        _push(loan.collateral, loan.collateralAmount, loan.borrower);

        // Try to repay directly
        try this.tryClaimRepaidLoan(loanId, repaymentAmount, _loanToken.ownerOf(loanId)) { }
        catch {
            // Note: Safe transfer can fail. In that case leave the Loan token in repaid state and wait for the Loan
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
        LoadWithId[] memory loansToRepay = new LoadWithId[](loanIds.length);
        uint256 numLoansToRepay;

        // Filter loans that can be repaid
        for (uint256 i; i < loanIds.length; ++i) {
            uint256 loanId = loanIds[i];
            Loan memory loan = _loans[loanId];

            // Checks: loan can be repaid & credit address is the same for all loanIds
            if (_isLoanRepayable(loan.status, loan.loanExpiration)) {
                _checkLoanCreditAddress(loan.credit, creditAddress);
                // Update loan to repaid state and increment the total repayment amount
                totalRepaymentAmount += _updateRepaidLoan(loanId);
                loansToRepay[numLoansToRepay] = LoadWithId(loanId, loan);
                numLoansToRepay++;
            }
        }

        // Transfer the repaid credit to the Vault
        if (permit2Data.length > 0) {
            _permit2Workflows(permit2Data, totalRepaymentAmount.toUint160(), creditAddress);
        } else {
            // Transfer the repaid credit to the vault
            _pushFrom(creditAddress, totalRepaymentAmount, msg.sender, address(this));
        }

        for (uint256 i; i < numLoansToRepay; ++i) {
            LoadWithId memory loanData = loansToRepay[i];
            Loan memory loan = loanData.loan;
            uint256 loanId = loanData.loanId;

            // Transfer collateral back to the borrower
            _push(loan.collateral, loan.collateralAmount, loan.borrower);

            // Try to repay directly (for each loanId)
            try this.tryClaimRepaidLoan(
                loanId, loan.principalAmount + loan.fixedInterestAmount, _loanToken.ownerOf(loanId)
            ) { } catch {
                // Note: Safe transfer can fail. In that case leave the Loan token in repaid state and wait for the Loan
                // token owner to claim the repaid credit. Otherwise lender would be able to prevent borrower from
                // repaying the loan.
            }
        }
    }

    /* ------------------------------------------------------------ */
    /*                          CLAIM LOAN                          */
    /* ------------------------------------------------------------ */

    /// @inheritdoc ISpro
    function claimLoan(uint256 loanId) public {
        Loan memory loan = _loans[loanId];

        // Check that caller is Loan token holder
        if (_loanToken.ownerOf(loanId) != msg.sender) {
            revert CallerNotLoanTokenHolder();
        }

        if (loan.status == LoanStatus.NONE) {
            // Loan is not existing or from a different loan contract
            revert NonExistingLoan();
        } else if (loan.status == LoanStatus.PAID_BACK) {
            // Loan has been paid back
            _settleLoanClaim(loanId, msg.sender, false);
        } else if (loan.status == LoanStatus.RUNNING && loan.loanExpiration <= block.timestamp) {
            // Loan is running but expired
            _settleLoanClaim(loanId, msg.sender, true);
        }
        // Loan is in wrong state
        else {
            revert LoanRunning();
        }
    }

    /// @inheritdoc ISpro
    function claimMultipleLoans(uint256[] calldata loanIds) external {
        uint256 l = loanIds.length;
        for (uint256 i; i < l; ++i) {
            claimLoan(loanIds[i]);
        }
    }

    /// @inheritdoc ISpro
    function tryClaimRepaidLoan(uint256 loanId, uint256 creditAmount, address loanOwner) external {
        if (msg.sender != address(this)) {
            revert CallerNotVault();
        }

        Loan memory loan = _loans[loanId];

        if (loan.status != LoanStatus.PAID_BACK) return;

        // If current loan owner is not original lender, the loan cannot be repaid directly, return without revert.
        if (loan.lender != loanOwner) return;

        // Delete loan data & burn Loan token before calling safe transfer
        _deleteLoan(loanId);

        emit LoanClaimed(loanId, false);

        // End here if the credit amount is zero
        if (creditAmount == 0) return;

        // Note: Zero credit amount can happen when the loan is refinanced by the original lender.

        // Repay the original lender
        _push(loan.credit, creditAmount, loanOwner);

        // Note: If the transfer fails, the Loan token will remain in repaid state and the Loan token owner
        // will be able to claim the repaid credit. Otherwise lender would be able to prevent borrower from
        // repaying the loan.
    }

    /**
     * @notice Settle the loan claim.
     * @param loanId Id of a loan that is being claimed.
     * @param loanOwner Address of the Loan token holder.
     * @param defaulted If the loan is defaulted.
     */
    function _settleLoanClaim(uint256 loanId, address loanOwner, bool defaulted) private {
        Loan memory loan = _loans[loanId];

        // Store in memory before deleting the loan
        address asset = defaulted ? loan.collateral : loan.credit;
        uint256 assetAmount = defaulted ? loan.collateralAmount : loan.principalAmount + loan.fixedInterestAmount;

        // Delete loan data & burn Loan token before calling safe transfer
        _deleteLoan(loanId);

        emit LoanClaimed(loanId, defaulted);

        // Transfer asset to current Loan token owner
        _push(asset, assetAmount, loanOwner);
    }

    /**
     * @notice Delete loan data and burn Loan token.
     * @param loanId Id of a loan that is being deleted.
     */
    function _deleteLoan(uint256 loanId) private {
        _loanToken.burn(loanId);
        delete _loans[loanId];
    }

    /**
     * @notice Return a Loan status associated with a loan id.
     * @param loanId Id of a loan in question.
     * @return status Loan status.
     */
    function _getLoanStatus(uint256 loanId) private view returns (LoanStatus) {
        Loan memory loan = _loans[loanId];
        return (loan.status == LoanStatus.RUNNING && loan.loanExpiration <= block.timestamp)
            ? LoanStatus.EXPIRED
            : loan.status;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  INTERNAL                                  */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Check that the loan credit address matches the expected credit address
     * @param loanCreditAddress Loan credit address.
     * @param expectedCreditAddress Expected credit address.
     */
    function _checkLoanCreditAddress(address loanCreditAddress, address expectedCreditAddress) internal pure {
        if (loanCreditAddress != expectedCreditAddress) {
            revert DifferentCreditAddress(loanCreditAddress, expectedCreditAddress);
        }
    }

    /**
     * @notice Check if the loan can be repaid.
     * @param status Loan status.
     * @param loanExpiration Loan default timestamp.
     * @return canBeRepaid_ True if the loan can be repaid.
     */
    function _isLoanRepayable(LoanStatus status, uint40 loanExpiration) internal view returns (bool canBeRepaid_) {
        // Check that loan is running
        if (status != LoanStatus.RUNNING) {
            return canBeRepaid_;
        }
        // Check that loan is not defaulted
        if (loanExpiration <= block.timestamp) {
            return canBeRepaid_;
        }
        return true;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   PRIVATE                                  */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Make an on-chain proposal.
     * @dev Function will mark a proposal hash as proposed.
     * @param proposal Proposal struct.
     * @return collateral_ Address of the collateral token.
     * @return collateralAmount_ Amount of the collateral token.
     */
    function _makeProposal(Proposal memory proposal) private returns (address collateral_, uint256 collateralAmount_) {
        // Decode proposal data
        if (proposal.startTimestamp >= proposal.loanExpiration) {
            revert InvalidDurationStartTime();
        }

        if (proposal.availableCreditLimit == 0) {
            revert AvailableCreditLimitZero();
        }

        // Check minimum loan duration
        if (proposal.loanExpiration - proposal.startTimestamp < Constants.MIN_LOAN_DURATION) {
            revert InvalidDuration(proposal.loanExpiration - proposal.startTimestamp, Constants.MIN_LOAN_DURATION);
        }

        proposal.partialPositionBps = _partialPositionBps;
        proposal.proposer = msg.sender;

        // Make proposal hash
        bytes32 proposalHash = keccak256(abi.encode(proposal));

        // Try to make proposal
        _makeProposal(proposalHash);

        collateral_ = proposal.collateralAddress;
        collateralAmount_ = proposal.collateralAmount;
        _withdrawableCollateral[proposalHash] = collateralAmount_;

        emit ProposalMade(proposalHash, proposal.proposer, proposal);
    }

    /**
     * @notice Accept a proposal and create new loan terms.
     * @param acceptor Address of a proposal acceptor.
     * @param creditAmount Amount of credit to lend.
     * @param proposal Proposal struct.
     * @return proposalHash_ Proposal hash.
     * @return loanTerms_ Loan terms.
     */
    function _acceptProposal(address acceptor, uint256 creditAmount, Proposal memory proposal)
        private
        returns (bytes32 proposalHash_, Terms memory loanTerms_)
    {
        // Make proposal hash
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
     * @notice Cancels a proposal and resets withdrawable collateral.
     * @param proposal Proposal struct.
     * @return proposal_ Proposal struct.
     */
    function _cancelProposal(Proposal memory proposal) private returns (Proposal memory proposal_) {
        proposal_ = proposal;

        // Make proposal hash
        bytes32 proposalHash = keccak256(abi.encode(proposal_));

        proposal_.collateralAmount = _withdrawableCollateral[proposalHash];
        delete _withdrawableCollateral[proposalHash];

        _proposalsMade[proposalHash] = false;

        emit ProposalCanceled(proposalHash);
    }

    /**
     * @notice Make an on-chain proposal.
     * @dev Function will mark a proposal hash as proposed.
     * @param proposalHash Proposal hash.
     */
    function _makeProposal(bytes32 proposalHash) private {
        if (_proposalsMade[proposalHash]) {
            revert ProposalAlreadyExists();
        }

        _proposalsMade[proposalHash] = true;
    }

    /**
     * @notice Try to accept proposal base.
     * @param acceptor Address of a proposal acceptor.
     * @param creditAmount Amount of credit to lend.
     * @param proposalHash Proposal hash.
     * @param proposal Proposal base struct.
     */
    function _acceptProposal(address acceptor, uint256 creditAmount, bytes32 proposalHash, ProposalBase memory proposal)
        private
    {
        // Check that the proposal was made on-chain
        if (!_proposalsMade[proposalHash]) {
            revert ProposalNotMade();
        }

        // Check proposer is not acceptor
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
            uint256 minAmount =
                Math.mulDiv(proposal.availableCreditLimit, proposal.partialPositionBps, Constants.BPS_DIVISOR);
            if (creditAmount < minAmount) {
                revert CreditAmountTooSmall(creditAmount, minAmount);
            }
            if (proposal.availableCreditLimit - minAmount < used + creditAmount) {
                revert CreditAmountRemainingBelowMinimum(creditAmount, minAmount);
            }
        } else if (used + creditAmount > proposal.availableCreditLimit) {
            // Revert, credit limit is exceeded
            revert AvailableCreditLimitExceeded(used + creditAmount, proposal.availableCreditLimit);
        }

        // Apply increase if credit amount checks pass
        _creditUsed[proposalHash] += creditAmount;
    }

    /**
     * @notice Mint Loan token and store loan data under loan id.
     * @param loanTerms Loan terms struct.
     * @return loanId_ Id of the created Loan token.
     */
    function _createLoan(Terms memory loanTerms) private returns (uint256 loanId_) {
        // Mint Loan token for lender
        loanId_ = _loanToken.mint(loanTerms.lender);

        // Store loan data under loan id
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
     * @notice Update loan to repaid state.
     * @param loanId Id of a loan that is being repaid.
     * @return repaidAmount_ Amount of the repaid loan.
     */
    function _updateRepaidLoan(uint256 loanId) private returns (uint256 repaidAmount_) {
        Loan storage loan = _loans[loanId];

        // Move loan to repaid state and wait for the loan owner to claim the repaid credit
        loan.status = LoanStatus.PAID_BACK;

        emit LoanPaidBack(loanId);
        return loan.principalAmount + loan.fixedInterestAmount;
    }

    /**
     * @notice Permit2 workflows for the caller.
     * @param permit2Data Permit data.
     * @param amount Amount of an asset to transfer.
     * @param token Address of an asset to transfer.
     */
    function _permit2Workflows(bytes memory permit2Data, uint160 amount, address token) private {
        (IAllowanceTransfer.PermitSingle memory permitSign, bytes memory data) =
            abi.decode(permit2Data, (IAllowanceTransfer.PermitSingle, bytes));
        PERMIT2.permit(msg.sender, permitSign, data);
        PERMIT2.transferFrom(msg.sender, address(this), amount, token);
    }
}
