// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { IAllowanceTransfer } from "permit2/src/interfaces/IAllowanceTransfer.sol";

import { SproConstantsLibrary as Constants } from "src/libraries/SproConstantsLibrary.sol";
import { IPoolAdapter } from "src/interfaces/IPoolAdapter.sol";
import { ISproLoanMetadataProvider } from "src/interfaces/ISproLoanMetadataProvider.sol";
import { ISpro } from "src/interfaces/ISpro.sol";
import { SproLoan } from "src/spro/SproLoan.sol";
import { SproVault } from "src/spro/SproVault.sol";
import { SproStorage } from "src/spro/SproStorage.sol";

contract Spro is SproVault, SproStorage, ISpro, Ownable2Step, ISproLoanMetadataProvider {
    using SafeCast for uint256;
    /* ------------------------------------------------------------ */
    /*                          CONSTRUCTOR                         */
    /* ------------------------------------------------------------ */

    /**
     * @param _sdex Address of SDEX token.
     * @param _permit2 Address of the Permit2 contract.
     * @param _fee Fee in SDEX.
     * @param _percentage Partial position percentage.
     */
    constructor(address _sdex, address _permit2, uint256 _fee, uint16 _percentage) Ownable(msg.sender) {
        require(_sdex != address(0), "SDEX is zero address");
        require(
            _percentage > 0 && _percentage < Constants.BPS_DIVISOR / 2, "Partial percentage position value is invalid"
        );

        PERMIT2 = IAllowanceTransfer(_permit2);
        SDEX = _sdex;
        loanToken = new SproLoan(address(this));
        fee = _fee;
        partialPositionBps = _percentage;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   SETTER                                   */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ISpro
    function setFee(uint256 newFee) external onlyOwner {
        if (newFee > Constants.MAX_SDEX_FEE) {
            revert ExcessiveFee(newFee);
        }
        emit FeeUpdated(fee, newFee);
        fee = newFee;
    }

    /// @inheritdoc ISpro
    function setPartialPositionPercentage(uint16 percentage) external onlyOwner {
        if (percentage == 0) {
            revert ZeroPercentageValue();
        }
        if (percentage >= Constants.BPS_DIVISOR / 2) {
            revert ExcessivePercentageValue(percentage);
        }
        partialPositionBps = percentage;
    }

    /// @inheritdoc ISpro
    function setLoanMetadataUri(address loanContract, string memory metadataUri) external onlyOwner {
        if (loanContract == address(0)) {
            // address(0) is used as a default metadata uri. Use `setDefaultLoanMetadataUri` to set default metadata
            // uri.
            revert DefaultLoanContract();
        }

        _loanMetadataUri[loanContract] = metadataUri;
        emit LoanMetadataUriUpdated(loanContract, metadataUri);
    }

    /// @inheritdoc ISpro
    function setDefaultLoanMetadataUri(string memory metadataUri) external onlyOwner {
        _loanMetadataUri[address(0)] = metadataUri;
        emit DefaultLoanMetadataUriUpdated(metadataUri);
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
        if (proposalsMade[proposalHash]) {
            used_ = creditUsed[proposalHash];
            remaining_ = proposal.availableCreditLimit - used_;
        } else {
            revert ProposalNotMade();
        }
    }

    /// @inheritdoc ISpro
    function getLoan(uint256 loanId) external view returns (LoanInfo memory loanInfo_) {
        Loan storage loan = Loans[loanId];

        loanInfo_.status = _getLoanStatus(loanId);
        loanInfo_.startTimestamp = loan.startTimestamp;
        loanInfo_.loanExpiration = loan.loanExpiration;
        loanInfo_.borrower = loan.borrower;
        loanInfo_.originalLender = loan.originalLender;
        loanInfo_.loanOwner = loan.status != LoanStatus.NONE ? loanToken.ownerOf(loanId) : address(0);
        loanInfo_.accruingInterestAPR = loan.accruingInterestAPR;
        loanInfo_.fixedInterestAmount = loan.fixedInterestAmount;
        loanInfo_.credit = loan.creditAddress;
        loanInfo_.collateral = loan.collateral;
        loanInfo_.collateralAmount = loan.collateralAmount;
        loanInfo_.originalSourceOfFunds = loan.originalSourceOfFunds;
        loanInfo_.repaymentAmount = loanRepaymentAmount(loanId);
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
            Loan memory loan = Loans[loanId];
            _checkLoanCreditAddress(loan.creditAddress, creditAddress);
            // Check non-existent loan
            if (loan.status == LoanStatus.NONE) return 0;

            // Add loan principal with accrued interest
            amount_ += loan.principalAmount + _loanAccruedInterest(loan);
        }
    }

    /// @inheritdoc ISpro
    function loanMetadataUri(address loanContract) public view returns (string memory uri_) {
        uri_ = _loanMetadataUri[loanContract];
        // If there is no metadata uri for a loan contract, use default metadata uri.
        if (bytes(uri_).length == 0) uri_ = _loanMetadataUri[address(0)];
    }

    /// @inheritdoc ISpro
    function loanRepaymentAmount(uint256 loanId) public view returns (uint256) {
        Loan memory loan = Loans[loanId];

        // Check non-existent loan
        if (loan.status == LoanStatus.NONE) return 0;

        // Return loan principal with accrued interest
        return loan.principalAmount + _loanAccruedInterest(loan);
    }

    /* ------------------------------------------------------------ */
    /*                          POOL ADAPTER                        */
    /* ------------------------------------------------------------ */

    /// @inheritdoc ISpro
    function registerPoolAdapter(address pool, address adapter) external onlyOwner {
        _poolAdapterRegistry[pool] = adapter;
    }

    /// @inheritdoc ISpro
    function getPoolAdapter(address pool) public view returns (IPoolAdapter) {
        return IPoolAdapter(_poolAdapterRegistry[pool]);
    }

    /* ------------------------------------------------------------ */
    /*                      CREATE PROPOSAL                         */
    /* ------------------------------------------------------------ */

    /// @inheritdoc ISpro
    function createProposal(Proposal calldata proposal, bytes calldata permit2Data) external {
        // Make the proposal
        (address proposer, address collateral, uint256 collateralAmount) = _makeProposal(proposal);

        // Check caller is the proposer
        if (msg.sender != proposer) {
            revert CallerIsNotStatedProposer(proposer);
        }

        // Execute permit2Data for the caller
        if (permit2Data.length > 0) {
            (IAllowanceTransfer.PermitBatch memory permitBatch, bytes memory data) =
                abi.decode(permit2Data, (IAllowanceTransfer.PermitBatch, bytes));
            PERMIT2.permit(msg.sender, permitBatch, data);
            PERMIT2.transferFrom(msg.sender, address(this), collateralAmount.toUint160(), collateral);
            // Fees to address(0xdead)(burned)
            if (fee > 0) {
                PERMIT2.transferFrom(msg.sender, address(0xdead), fee.toUint160(), address(SDEX));
            }
        } else {
            // Transfer collateral to Vault
            _pushFrom(collateral, collateralAmount, proposer, address(this));
            // Fees to address(0xdead)(burned)
            if (fee > 0) {
                _pushFrom(SDEX, fee, msg.sender, address(0xdead));
            }
        }
    }

    /* ------------------------------------------------------------ */
    /*        CANCEL PROPOSAL AND WITHDRAW UNUSED COLLATERAL        */
    /* ------------------------------------------------------------ */

    /// @inheritdoc ISpro
    function cancelProposal(Proposal calldata proposal) external {
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
    function createLoan(
        Proposal calldata proposal,
        LenderSpec calldata lenderSpec,
        bytes calldata extra,
        bytes calldata permit2Data
    ) external returns (uint256 loanId_) {
        // Accept proposal and get loan terms
        (bytes32 proposalHash, Terms memory loanTerms) = _acceptProposal(msg.sender, lenderSpec.creditAmount, proposal);

        // Check minimum loan duration
        if (loanTerms.loanExpiration - loanTerms.startTimestamp < Constants.MIN_LOAN_DURATION) {
            revert InvalidDuration(loanTerms.loanExpiration - loanTerms.startTimestamp, Constants.MIN_LOAN_DURATION);
        }

        // Check maximum accruing interest APR
        if (loanTerms.accruingInterestAPR > Constants.MAX_ACCRUING_INTEREST_APR) {
            revert InterestAPROutOfBounds(loanTerms.accruingInterestAPR, Constants.MAX_ACCRUING_INTEREST_APR);
        }

        // Create a new loan
        loanId_ = _createLoan(loanTerms, lenderSpec);

        emit LoanCreated(loanId_, proposalHash, loanTerms, lenderSpec, extra);

        // Execute permit2Data for the caller
        if (permit2Data.length > 0) {
            _permit2Workflows(permit2Data, loanTerms.creditAmount.toUint160(), loanTerms.credit);
        } else {
            // Settle the loan - Transfer credit to borrower
            _settleNewLoan(loanTerms, lenderSpec.sourceOfFunds);
        }
    }

    /* ------------------------------------------------------------ */
    /*                          REPAY LOAN                          */
    /* ------------------------------------------------------------ */

    /// @inheritdoc ISpro
    function repayLoan(uint256 loanId, bytes calldata permit2Data) external {
        Loan memory loan = Loans[loanId];

        _checkLoanCanBeRepaid(loan.status, loan.loanExpiration);

        // Update loan to repaid state
        _updateRepaidLoan(loanId);

        uint256 repaymentAmount = loanRepaymentAmount(loanId);
        // Execute permit2Data for the caller
        if (permit2Data.length > 0) {
            _permit2Workflows(permit2Data, repaymentAmount.toUint160(), loan.creditAddress);
        } else {
            // Transfer the repaid credit to the Vault
            _pushFrom(loan.creditAddress, repaymentAmount, msg.sender, address(this));
        }

        // Transfer collateral back to borrower
        _push(loan.collateral, loan.collateralAmount, loan.borrower);

        // Try to repay directly
        try this.tryClaimRepaidLoan(loanId, repaymentAmount, loanToken.ownerOf(loanId)) { }
        catch {
            // Note: Safe transfer or supply to a pool can fail. In that case leave the Loan token in repaid state and
            // wait for the Loan token owner to claim the repaid credit. Otherwise lender would be able to prevent
            // borrower from repaying the loan.
        }
    }

    /// @inheritdoc ISpro
    function repayMultipleLoans(uint256[] calldata loanIds, address creditAddress, bytes calldata permit2Data)
        external
    {
        uint256 totalRepaymentAmount;

        for (uint256 i; i < loanIds.length; ++i) {
            uint256 loanId = loanIds[i];
            Loan memory loan = Loans[loanId];

            // Checks: loan can be repaid & credit address is the same for all loanIds
            _checkLoanCanBeRepaid(loan.status, loan.loanExpiration);
            _checkLoanCreditAddress(loan.creditAddress, creditAddress);

            // Update loan to repaid state
            _updateRepaidLoan(loanId);

            // Increment the total repayment amount
            totalRepaymentAmount += loanRepaymentAmount(loanId);
        }

        if (permit2Data.length > 0) {
            _permit2Workflows(permit2Data, totalRepaymentAmount.toUint160(), creditAddress);
        } else {
            // Transfer the repaid credit to the vault
            _pushFrom(creditAddress, totalRepaymentAmount, msg.sender, address(this));
        }

        for (uint256 i; i < loanIds.length; ++i) {
            uint256 loanId = loanIds[i];
            Loan memory loan = Loans[loanId];

            // Transfer collateral back to the borrower
            _push(loan.collateral, loan.collateralAmount, loan.borrower);

            // Try to repay directly (for each loanId)
            try this.tryClaimRepaidLoan(loanId, loanRepaymentAmount(loanId), loanToken.ownerOf(loanId)) { }
            catch {
                // Note: Safe transfer or supply to a pool can fail. In that case leave the Loan token in repaid state
                // and
                // wait for the Loan token owner to claim the repaid credit. Otherwise lender would be able to prevent
                // borrower from repaying the loan.
            }
        }
    }

    /* ------------------------------------------------------------ */
    /*                          CLAIM LOAN                          */
    /* ------------------------------------------------------------ */

    /// @inheritdoc ISpro
    function claimLoan(uint256 loanId) public {
        Loan memory loan = Loans[loanId];

        // Check that caller is Loan token holder
        if (loanToken.ownerOf(loanId) != msg.sender) {
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

        Loan memory loan = Loans[loanId];

        if (loan.status != LoanStatus.PAID_BACK) return;

        // If current loan owner is not original lender, the loan cannot be repaid directly, return without revert.
        if (loan.originalLender != loanOwner) return;

        // Note: The loan owner is the original lender at this point.

        address destinationOfFunds = loan.originalSourceOfFunds;
        address credit = loan.creditAddress;

        // Delete loan data & burn Loan token before calling safe transfer
        _deleteLoan(loanId);

        emit LoanClaimed(loanId, false);

        // End here if the credit amount is zero
        if (creditAmount == 0) return;

        // Note: Zero credit amount can happen when the loan is refinanced by the original lender.

        // Repay the original lender
        if (destinationOfFunds == loanOwner) {
            _push(credit, creditAmount, loanOwner);
        } else {
            IPoolAdapter poolAdapter = getPoolAdapter(destinationOfFunds);
            // Check that pool has registered adapter
            if (address(poolAdapter) == address(0)) {
                // Note: Adapter can be unregistered during the loan lifetime, so the pool might not have an adapter.
                // In that case, the loan owner will be able to claim the repaid credit.

                revert InvalidSourceOfFunds(destinationOfFunds);
            }

            // Supply the repaid credit to the original pool
            _supplyToPool(credit, creditAmount, poolAdapter, destinationOfFunds, loanOwner);
        }

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
        Loan memory loan = Loans[loanId];

        // Store in memory before deleting the loan
        address asset = defaulted ? loan.collateral : loan.creditAddress;
        uint256 assetAmount = defaulted ? loan.collateralAmount : loanRepaymentAmount(loanId);

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
        loanToken.burn(loanId);
        delete Loans[loanId];
    }

    /**
     * @notice Return a Loan status associated with a loan id.
     * @param loanId Id of a loan in question.
     * @return status Loan status.
     */
    function _getLoanStatus(uint256 loanId) private view returns (LoanStatus) {
        Loan memory loan = Loans[loanId];
        return (loan.status == LoanStatus.RUNNING && loan.loanExpiration <= block.timestamp)
            ? LoanStatus.EXPIRED
            : loan.status;
    }

    /* ------------------------------------------------------------ */
    /*                      ISproLoanMetadataProvider                */
    /* ------------------------------------------------------------ */

    /// @inheritdoc ISproLoanMetadataProvider
    function loanMetadataUri() external view returns (string memory) {
        return loanMetadataUri(address(this));
    }

    /* -------------------------------------------------------------------------- */
    /*                                  INTERNAL                                  */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Check if the loan can be repaid.
     * @dev The function will revert if the loan cannot be repaid.
     * @param status Loan status.
     * @param loanExpiration Loan default timestamp.
     */
    function _checkLoanCanBeRepaid(LoanStatus status, uint40 loanExpiration) internal view {
        // Check that loan exists and is not from a different loan contract
        if (status == LoanStatus.NONE) {
            revert NonExistingLoan();
        }
        // Check that loan is running
        if (status != LoanStatus.RUNNING) {
            revert LoanNotRunning();
        }
        // Check that loan is not defaulted
        if (loanExpiration <= block.timestamp) {
            revert LoanDefaulted(loanExpiration);
        }
    }

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
     * @notice Withdraw a credit asset from a pool to the Vault.
     * @dev The function will revert if pool doesn't have registered pool adapter.
     * @param credit Asset to be pulled from the pool.
     * @param creditAmount Amount of an asset to be pulled.
     * @param lender Address of a lender.
     * @param sourceOfFunds Address of a source of funds.
     */
    function _withdrawCreditFromPool(address credit, uint256 creditAmount, address lender, address sourceOfFunds)
        internal
    {
        IPoolAdapter poolAdapter = getPoolAdapter(sourceOfFunds);
        if (address(poolAdapter) == address(0)) {
            revert InvalidSourceOfFunds(sourceOfFunds);
        }

        if (creditAmount > 0) {
            _withdrawFromPool(credit, creditAmount, poolAdapter, sourceOfFunds, lender);
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

    /* -------------------------------------------------------------------------- */
    /*                                   PRIVATE                                  */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Make an on-chain proposal.
     * @dev Function will mark a proposal hash as proposed.
     * @param proposal Proposal struct.
     * @return proposer_ Address of the borrower/proposer
     * @return collateral_ Address of the collateral token.
     * @return collateralAmount_ Amount of the collateral token.
     */
    function _makeProposal(Proposal memory proposal)
        private
        returns (address proposer_, address collateral_, uint256 collateralAmount_)
    {
        // Decode proposal data
        if (proposal.startTimestamp > proposal.loanExpiration) {
            revert InvalidDurationStartTime();
        }

        // Make proposal hash
        bytes32 proposalHash = keccak256(abi.encode(proposal));

        // Try to make proposal
        _makeProposal(proposalHash);

        collateral_ = proposal.collateralAddress;
        collateralAmount_ = proposal.collateralAmount;
        withdrawableCollateral[proposalHash] = collateralAmount_;

        emit ProposalMade(proposalHash, proposer_ = proposal.proposer, proposal);
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
                proposal.nonce,
                proposal.loanContract
            )
        );

        // Create loan terms object
        uint256 collateralUsed_ = (creditAmount * proposal.collateralAmount) / proposal.availableCreditLimit;

        loanTerms_ = Terms(
            acceptor,
            proposal.proposer,
            proposal.startTimestamp,
            proposal.loanExpiration,
            proposal.collateralAddress,
            collateralUsed_,
            proposal.creditAddress,
            creditAmount,
            proposal.fixedInterestAmount,
            proposal.accruingInterestAPR,
            bytes32(0),
            proposal.proposerSpecHash
        );

        withdrawableCollateral[proposalHash_] -= collateralUsed_;
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

        proposal_.collateralAmount = withdrawableCollateral[proposalHash];
        delete withdrawableCollateral[proposalHash];

        proposalsMade[proposalHash] = false;
    }

    /**
     * @notice Make an on-chain proposal.
     * @dev Function will mark a proposal hash as proposed.
     * @param proposalHash Proposal hash.
     */
    function _makeProposal(bytes32 proposalHash) private {
        if (proposalsMade[proposalHash]) {
            revert ProposalAlreadyExists();
        }

        proposalsMade[proposalHash] = true;
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
        if (!proposalsMade[proposalHash]) {
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

        if (proposal.availableCreditLimit == 0) {
            revert AvailableCreditLimitZero();
        } else if (creditUsed[proposalHash] + creditAmount < proposal.availableCreditLimit) {
            // Credit may only be between min and max amounts if it is not exact
            uint256 minCreditAmount =
                Math.mulDiv(proposal.availableCreditLimit, partialPositionBps, Constants.BPS_DIVISOR);
            if (creditAmount < minCreditAmount) {
                revert CreditAmountTooSmall(creditAmount, minCreditAmount);
            }

            uint256 maxCreditAmount = Math.mulDiv(
                proposal.availableCreditLimit, (Constants.BPS_DIVISOR - partialPositionBps), Constants.BPS_DIVISOR
            );
            if (creditAmount > maxCreditAmount) {
                revert CreditAmountLeavesTooLittle(creditAmount, maxCreditAmount);
            }
        } else if (creditUsed[proposalHash] + creditAmount > proposal.availableCreditLimit) {
            // Revert, credit limit is exceeded
            revert AvailableCreditLimitExceeded(creditUsed[proposalHash] + creditAmount, proposal.availableCreditLimit);
        }

        // Apply increase if credit amount checks pass
        creditUsed[proposalHash] += creditAmount;
    }

    /**
     * @notice Mint Loan token and store loan data under loan id.
     * @param loanTerms Loan terms struct.
     * @param lenderSpec Lender specification struct.
     * @return loanId_ Id of the created Loan token.
     */
    function _createLoan(Terms memory loanTerms, LenderSpec calldata lenderSpec) private returns (uint256 loanId_) {
        // Mint Loan token for lender
        loanId_ = loanToken.mint(loanTerms.lender);

        // Store loan data under loan id
        Loan storage loan = Loans[loanId_];
        loan.status = LoanStatus.RUNNING;
        loan.creditAddress = loanTerms.credit;
        loan.originalSourceOfFunds = lenderSpec.sourceOfFunds;
        loan.startTimestamp = loanTerms.startTimestamp;
        loan.loanExpiration = loanTerms.loanExpiration;
        loan.borrower = loanTerms.borrower;
        loan.originalLender = loanTerms.lender;
        loan.accruingInterestAPR = loanTerms.accruingInterestAPR;
        loan.fixedInterestAmount = loanTerms.fixedInterestAmount;
        loan.principalAmount = loanTerms.creditAmount;
        loan.collateral = loanTerms.collateral;
        loan.collateralAmount = loanTerms.collateralAmount;
    }

    /**
     * @notice Transfers credit to borrower
     * @dev The function assumes a prior token approval to a contract address or signed permits.
     * @param loanTerms Loan terms struct.
     * @param sourceOfFunds Address of a source of funds.
     */
    function _settleNewLoan(Terms memory loanTerms, address sourceOfFunds) private {
        // Lender is not the source of funds
        if (sourceOfFunds != loanTerms.lender) {
            // Withdraw credit asset to the lender first
            _withdrawCreditFromPool(loanTerms.credit, loanTerms.creditAmount, loanTerms.lender, sourceOfFunds);
        }

        // Transfer credit to borrower
        _pushFrom(loanTerms.credit, loanTerms.creditAmount, loanTerms.lender, loanTerms.borrower);
    }

    /**
     * @notice Update loan to repaid state.
     * @param loanId Id of a loan that is being repaid.
     */
    function _updateRepaidLoan(uint256 loanId) private {
        Loan storage loan = Loans[loanId];

        // Move loan to repaid state and wait for the loan owner to claim the repaid credit
        loan.status = LoanStatus.PAID_BACK;

        // Update accrued interest amount
        loan.fixedInterestAmount = _loanAccruedInterest(loan);
        loan.accruingInterestAPR = 0;

        // Note: Reusing `fixedInterestAmount` to store accrued interest at the time of repayment
        // to have the value at the time of claim and stop accruing new interest.

        emit LoanPaidBack(loanId);
    }

    /**
     * @notice Calculate the loan accrued interest.
     * @param loan Loan data struct.
     * @return Accrued interest amount.
     */
    function _loanAccruedInterest(Loan memory loan) private pure returns (uint256) {
        if (loan.accruingInterestAPR == 0) return loan.fixedInterestAmount;

        uint256 accruingMinutes = (loan.loanExpiration - loan.startTimestamp) / 1 minutes;
        uint256 accruedInterest = Math.mulDiv(
            loan.principalAmount,
            uint256(loan.accruingInterestAPR) * accruingMinutes,
            Constants.ACCRUING_INTEREST_APR_DENOMINATOR,
            Math.Rounding.Ceil
        );
        return loan.fixedInterestAmount + accruedInterest;
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
