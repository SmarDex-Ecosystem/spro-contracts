// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IPoolAdapter } from "src/interfaces/IPoolAdapter.sol";
import { ISproLoanMetadataProvider } from "src/interfaces/ISproLoanMetadataProvider.sol";
import { SproLOAN } from "src/spro/SproLOAN.sol";
import { SproVault } from "src/spro/SproVault.sol";
import { SproRevokedNonce } from "src/spro/SproRevokedNonce.sol";
import { SproConstantsLibrary as Constants } from "src/libraries/SproConstantsLibrary.sol";
import { SproStorage } from "src/spro/SproStorage.sol";
import { Permit } from "src/spro/Permit.sol";
import { SproListedFee } from "src/libraries/SproListedFee.sol";

/// @title Spro - Spro Protocol
contract Spro is SproVault, SproStorage, Ownable2Step, ISproLoanMetadataProvider {
    /* ------------------------------------------------------------ */
    /*                          CONSTRUCTOR                         */
    /* ------------------------------------------------------------ */

    /**
     * @notice Initialize Spro contract.
     * @param _sdex Address of SDEX token.
     * @param _owner Address of the owner.
     * @param _fixFeeUnlisted Fixed fee for unlisted assets.
     * @param _fixFeeListed Fixed fee for listed assets.
     * @param _variableFactor Variable factor for listed assets.
     * @param _percentage Partial position percentage.
     */
    constructor(
        address _sdex,
        address _owner,
        uint256 _fixFeeUnlisted,
        uint256 _fixFeeListed,
        uint256 _variableFactor,
        uint16 _percentage
    ) Ownable(_owner) {
        require(_owner != address(0), "Owner is zero address");
        require(_sdex != address(0), "SDEX is zero address");
        require(
            _percentage > 0 && _percentage < Constants.PERCENTAGE / 2, "Partial percentage position value is invalid"
        );

        SDEX = _sdex;
        revokedNonce = new SproRevokedNonce(address(this));
        loanToken = new SproLOAN(address(this));
        fixFeeUnlisted = _fixFeeUnlisted;
        fixFeeListed = _fixFeeListed;
        variableFactor = _variableFactor;
        partialPositionPercentage = _percentage;
    }

    /* ------------------------------------------------------------ */
    /*                      FEE MANAGEMENT                          */
    /* ------------------------------------------------------------ */

    /**
     * @notice Set new protocol listed fee value.
     * @param fee New listed fee value in amount SDEX tokens (units 1e18)
     */
    function setFixFeeListed(uint256 fee) external onlyOwner {
        emit FixFeeListedUpdated(fixFeeListed, fee);
        fixFeeListed = fee;
    }

    /**
     * @notice Set new protocol unlisted fee value.
     * @param fee New unlisted fee value in amount SDEX tokens (units 1e18)
     */
    function setFixFeeUnlisted(uint256 fee) external onlyOwner {
        emit FixFeeUnlistedUpdated(fixFeeUnlisted, fee);
        fixFeeUnlisted = fee;
    }

    /**
     * @notice Set new protocol variable factor
     * @param factor New variable factor value (units 1e18)
     */
    function setVariableFactor(uint256 factor) external onlyOwner {
        emit VariableFactorUpdated(variableFactor, factor);
        variableFactor = factor;
    }

    /**
     * @notice Set new protocol token factor for credit asset
     * @param token Credit token address.
     * @param factor New token factor value (units 1e18)
     * @dev Token is unlisted for `factor == 0` and listed for `factor != 0`.
     */
    function setListedToken(address token, uint256 factor) external onlyOwner {
        emit ListedTokenUpdated(token, factor);
        tokenFactors[token] = factor;
    }

    /* ------------------------------------------------------------ */
    /*                  PARTIAL LENDING THRESHOLDS                  */
    /* ------------------------------------------------------------ */

    /**
     * @notice Set percentage of a proposal's availableCreditLimit which can be used in partial lending.
     * @param percentage New percentage value.
     */
    function setPartialPositionPercentage(uint16 percentage) external onlyOwner {
        if (percentage == 0) revert ZeroPercentageValue();
        if (percentage >= Constants.PERCENTAGE / 2) revert ExcessivePercentageValue(percentage);
        partialPositionPercentage = percentage;
    }

    /* ------------------------------------------------------------ */
    /*                          LOAN METADATA                       */
    /* ------------------------------------------------------------ */

    /**
     * @notice Set a LOAN token metadata uri for a specific loan contract.
     * @param loanContract Address of a loan contract.
     * @param metadataUri New value of LOAN token metadata uri for given `loanContract`.
     */
    function setLOANMetadataUri(address loanContract, string memory metadataUri) external onlyOwner {
        if (loanContract == address(0)) {
            // address(0) is used as a default metadata uri. Use `setDefaultLOANMetadataUri` to set default metadata
            // uri.
            revert ZeroLoanContract();
        }

        _loanMetadataUri[loanContract] = metadataUri;
        emit LOANMetadataUriUpdated(loanContract, metadataUri);
    }

    /**
     * @notice Set a default LOAN token metadata uri.
     * @param metadataUri New value of default LOAN token metadata uri.
     */
    function setDefaultLOANMetadataUri(string memory metadataUri) external onlyOwner {
        _loanMetadataUri[address(0)] = metadataUri;
        emit DefaultLOANMetadataUriUpdated(metadataUri);
    }

    /**
     * @notice Return a LOAN token metadata uri base on a loan contract that minted the token.
     * @param loanContract Address of a loan contract.
     * @return uri Metadata uri for given loan contract.
     */
    function loanMetadataUri(address loanContract) public view returns (string memory uri) {
        uri = _loanMetadataUri[loanContract];
        // If there is no metadata uri for a loan contract, use default metadata uri.
        if (bytes(uri).length == 0) uri = _loanMetadataUri[address(0)];
    }

    /* ------------------------------------------------------------ */
    /*                          POOL ADAPTER                        */
    /* ------------------------------------------------------------ */

    /**
     * @notice Returns the pool adapter for a given pool.
     * @param pool The pool for which the adapter is requested.
     * @return The adapter for the given pool.
     */
    function getPoolAdapter(address pool) public view returns (IPoolAdapter) {
        return IPoolAdapter(_poolAdapterRegistry[pool]);
    }

    /**
     * @notice Registers a pool adapter for a given pool.
     * @param pool The pool for which the adapter is registered.
     * @param adapter The adapter to be registered.
     */
    function registerPoolAdapter(address pool, address adapter) external onlyOwner {
        _poolAdapterRegistry[pool] = adapter;
    }

    /* -------------------------------------------------------------------------- */
    /*                                    LOAN                                    */
    /* -------------------------------------------------------------------------- */

    /* ------------------------------------------------------------ */
    /*                      LENDER SPEC                             */
    /* ------------------------------------------------------------ */

    /**
     * @notice Get hash of a lender specification.
     * @param lenderSpec Lender specification struct.
     * @return Hash of a lender specification.
     */
    function getLenderSpecHash(LenderSpec calldata lenderSpec) public pure returns (bytes32) {
        return keccak256(abi.encode(lenderSpec));
    }

    /* ------------------------------------------------------------ */
    /*                      CREATE PROPOSAL                         */
    /* ------------------------------------------------------------ */

    /**
     * @notice Create a borrow request proposal and transfers collateral to the vault and SDEX to fee sink.
     * @param proposalData Proposal data.
     */
    function createProposal(bytes calldata proposalData) external {
        // Make the proposal
        (address proposer, address collateral, uint256 collateralAmount, address creditAddress, uint256 creditLimit) =
            makeProposal(proposalData);

        // Check caller is the proposer
        if (msg.sender != proposer) {
            revert CallerIsNotStatedProposer({ addr: proposer });
        }

        // Transfer collateral to Vault
        _pull(collateral, collateralAmount, proposer);

        // Calculate fee amount
        uint256 feeAmount = getLoanFee(creditAddress, creditLimit);

        // Fees to sink (burned)
        if (feeAmount > 0) {
            _pushFrom(SDEX, feeAmount, msg.sender, Constants.SINK);
        }
    }

    /* ------------------------------------------------------------ */
    /*        CANCEL PROPOSAL AND WITHDRAW UNUSED COLLATERAL        */
    /* ------------------------------------------------------------ */

    /**
     * @notice A borrower can cancel their proposal and withdraw unused collateral.
     * @dev Resets withdrawable collateral, revokes the nonce if needed, transfers unused collateral to the proposer.
     * @dev Fungible withdrawable collateral with amount == 0 calls should not revert, should transfer 0 tokens.
     * @param proposalData Proposal data.
     */
    function cancelProposal(bytes calldata proposalData) external {
        (address proposer, address collateral, uint256 collateralAmount) = _cancelProposal(proposalData);

        // The caller must be the proposer
        if (msg.sender != proposer) revert CallerNotProposer();

        // Transfers withdrawable collateral to the proposer/borrower
        _push(collateral, collateralAmount, proposer);
    }

    /* ------------------------------------------------------------ */
    /*                          CREATE LOAN                         */
    /* ------------------------------------------------------------ */

    /**
     * @notice Create a new loan.
     * @dev The function assumes a prior token approval to a contract address or signed permits.
     * @param proposalData Proposal data.
     * @param lenderSpec Lender specification struct.
     * @param extra Auxiliary data that are emitted in the loan creation event. They are not used in the contract logic.
     * @return loanId Id of the created LOAN token.
     */
    function createLOAN(bytes calldata proposalData, LenderSpec calldata lenderSpec, bytes calldata extra)
        external
        returns (uint256 loanId)
    {
        // Accept proposal and get loan terms
        (bytes32 proposalHash, Terms memory loanTerms) =
            acceptProposal({ acceptor: msg.sender, creditAmount: lenderSpec.creditAmount, proposalData: proposalData });

        // Check minimum loan duration
        if (loanTerms.defaultTimestamp - loanTerms.startTimestamp < Constants.MIN_LOAN_DURATION) {
            revert InvalidDuration({
                current: loanTerms.defaultTimestamp - loanTerms.startTimestamp,
                limit: Constants.MIN_LOAN_DURATION
            });
        }

        // Check maximum accruing interest APR
        if (loanTerms.accruingInterestAPR > Constants.MAX_ACCRUING_INTEREST_APR) {
            revert InterestAPROutOfBounds({
                current: loanTerms.accruingInterestAPR,
                limit: Constants.MAX_ACCRUING_INTEREST_APR
            });
        }

        // Create a new loan
        loanId = _createLoan({ loanTerms: loanTerms, lenderSpec: lenderSpec });

        emit LOANCreated({
            loanId: loanId,
            proposalHash: proposalHash,
            terms: loanTerms,
            lenderSpec: lenderSpec,
            extra: extra
        });

        // Execute permit for the caller
        if (lenderSpec.permitData.length > 0) {
            Permit memory permit = abi.decode(lenderSpec.permitData, (Permit));
            _checkPermit(msg.sender, loanTerms.credit, permit);
            _tryPermit(permit);
        }

        // Settle the loan - Transfer credit to borrower
        _settleNewLoan(loanTerms, lenderSpec);
    }

    /**
     * @notice Check that permit data have correct owner and asset.
     * @param caller Caller address.
     * @param creditAddress Address of a credit to be used.
     * @param permit Permit to be checked.
     */
    function _checkPermit(address caller, address creditAddress, Permit memory permit) internal pure {
        if (permit.asset != address(0)) {
            if (permit.owner != caller) {
                revert InvalidPermitOwner({ current: permit.owner, expected: caller });
            }
            if (permit.asset != creditAddress) {
                revert InvalidPermitAsset({ current: permit.asset, expected: creditAddress });
            }
        }
    }

    /**
     * @notice Mint LOAN token and store loan data under loan id.
     * @param loanTerms Loan terms struct.
     * @param lenderSpec Lender specification struct.
     * @return loanId Id of the created LOAN token.
     */
    function _createLoan(Terms memory loanTerms, LenderSpec calldata lenderSpec) private returns (uint256 loanId) {
        // Mint LOAN token for lender
        loanId = loanToken.mint(loanTerms.lender);

        // Store loan data under loan id
        LOAN storage loan = LOANs[loanId];
        loan.status = 2;
        loan.creditAddress = loanTerms.credit;
        loan.originalSourceOfFunds = lenderSpec.sourceOfFunds;
        loan.startTimestamp = loanTerms.startTimestamp;
        loan.defaultTimestamp = loanTerms.defaultTimestamp;
        loan.borrower = loanTerms.borrower;
        loan.originalLender = loanTerms.lender;
        loan.accruingInterestAPR = loanTerms.accruingInterestAPR;
        loan.fixedInterestAmount = loanTerms.fixedInterestAmount;
        loan.principalAmount = loanTerms.creditAmount;
        loan.collateral = loanTerms.collateral;
        loan.collateralAmount = loanTerms.collateralAmount;
    }

    /**
     * @notice Get the fee to create or refinance the loan.
     * @param assetAddress Address of an asset to be used.
     * @param amount Amount of an asset to be used.
     */
    function getLoanFee(address assetAddress, uint256 amount) public view returns (uint256) {
        uint256 tokenFactor = tokenFactors[assetAddress];
        return (tokenFactor == 0)
            ? fixFeeUnlisted
            : SproListedFee.calculate(fixFeeListed, variableFactor, tokenFactor, amount);
    }

    /**
     * @notice Transfers credit to borrower
     * @dev The function assumes a prior token approval to a contract address or signed permits.
     * @param loanTerms Loan terms struct.
     * @param lenderSpec Lender specification struct.
     */
    function _settleNewLoan(Terms memory loanTerms, LenderSpec calldata lenderSpec) private {
        // Lender is not the source of funds
        if (lenderSpec.sourceOfFunds != loanTerms.lender) {
            // Withdraw credit asset to the lender first
            _withdrawCreditFromPool(loanTerms.credit, loanTerms.creditAmount, loanTerms, lenderSpec);
        }

        // Transfer credit to borrower
        _pushFrom(loanTerms.credit, loanTerms.creditAmount, loanTerms.lender, loanTerms.borrower);
    }

    /**
     * @notice Withdraw a credit asset from a pool to the Vault.
     * @dev The function will revert if pool doesn't have registered pool adapter.
     * @param credit Asset to be pulled from the pool.
     * @param creditAmount Amount of an asset to be pulled.
     * @param loanTerms Loan terms struct.
     * @param lenderSpec Lender specification struct.
     */
    function _withdrawCreditFromPool(
        address credit,
        uint256 creditAmount,
        Terms memory loanTerms,
        LenderSpec calldata lenderSpec
    ) internal {
        IPoolAdapter poolAdapter = getPoolAdapter(lenderSpec.sourceOfFunds);
        if (address(poolAdapter) == address(0)) {
            revert InvalidSourceOfFunds({ sourceOfFunds: lenderSpec.sourceOfFunds });
        }

        if (creditAmount > 0) {
            _withdrawFromPool(credit, creditAmount, poolAdapter, lenderSpec.sourceOfFunds, loanTerms.lender);
        }
    }

    /* ------------------------------------------------------------ */
    /*                          REPAY LOAN                          */
    /* ------------------------------------------------------------ */

    /**
     * @notice Repay running loan.
     * @dev Any address can repay a running loan, but a collateral will be transferred to a borrower address associated
     * with the loan.
     *      If the LOAN token holder is the same as the original lender, the repayment credit asset will be
     *      transferred to the LOAN token holder directly. Otherwise it will transfer the repayment credit asset to
     *      a vault, waiting on a LOAN token holder to claim it. The function assumes a prior token approval to a
     * contract address
     *      or a signed permit.
     * @param loanId Id of a loan that is being repaid.
     * @param permitData Callers credit permit data.
     */
    function repayLOAN(uint256 loanId, bytes calldata permitData) external {
        LOAN storage loan = LOANs[loanId];

        _checkLoanCanBeRepaid(loan.status, loan.defaultTimestamp);

        // Update loan to repaid state
        _updateRepaidLoan(loanId);

        // Execute permit for the caller
        if (permitData.length > 0) {
            Permit memory permit = abi.decode(permitData, (Permit));
            _checkPermit(msg.sender, loan.creditAddress, permit);
            _tryPermit(permit);
        }

        // Transfer the repaid credit to the Vault
        uint256 repaymentAmount = loanRepaymentAmount(loanId);
        _pull(loan.creditAddress, repaymentAmount, msg.sender);

        // Transfer collateral back to borrower
        _push(loan.collateral, loan.collateralAmount, loan.borrower);

        // Try to repay directly
        try this.tryClaimRepaidLOAN(loanId, repaymentAmount, loanToken.ownerOf(loanId)) { }
        catch {
            // Note: Safe transfer or supply to a pool can fail. In that case leave the LOAN token in repaid state and
            // wait for the LOAN token owner to claim the repaid credit. Otherwise lender would be able to prevent
            // borrower from repaying the loan.
        }
    }

    /**
     * @notice Repay running loans.
     * @dev Any address can repay a running loan, but a collateral will be transferred to a borrower address associated
     * with the loan.
     *      If the LOAN token holder is the same as the original lender, the repayment credit asset will be
     *      transferred to the LOAN token holder directly. Otherwise it will transfer the repayment credit asset to
     *      a vault, waiting on a LOAN token holder to claim it. The function assumes a prior token approval to a
     * contract address
     *      or a signed permit.
     * @param loanIds Id array of loans that are being repaid.
     * @param creditAddress Expected credit address for all loan ids.
     * @param permitData Callers credit permit data.
     */
    function repayMultipleLOANs(uint256[] calldata loanIds, address creditAddress, bytes calldata permitData)
        external
    {
        uint256 totalRepaymentAmount;

        for (uint256 i; i < loanIds.length; ++i) {
            uint256 loanId = loanIds[i];
            LOAN storage loan = LOANs[loanId];

            // Checks: loan can be repaid & credit address is the same for all loanIds
            _checkLoanCanBeRepaid(loan.status, loan.defaultTimestamp);
            _checkLoanCreditAddress(loan.creditAddress, creditAddress);

            // Update loan to repaid state
            _updateRepaidLoan(loanId);

            // Increment the total repayment amount
            totalRepaymentAmount += loanRepaymentAmount(loanId);
        }

        // Execute permit for the caller
        if (permitData.length > 0) {
            Permit memory permit = abi.decode(permitData, (Permit));
            _checkPermit(msg.sender, creditAddress, permit);
            _tryPermit(permit);
        }
        // Transfer the repaid credit to the vault
        _pull(creditAddress, totalRepaymentAmount, msg.sender);

        for (uint256 i; i < loanIds.length; ++i) {
            uint256 loanId = loanIds[i];
            LOAN storage loan = LOANs[loanId];

            // Transfer collateral back to the borrower
            _push(loan.collateral, loan.collateralAmount, loan.borrower);

            // Try to repay directly (for each loanId)
            try this.tryClaimRepaidLOAN(loanId, loanRepaymentAmount(loanId), loanToken.ownerOf(loanId)) { }
            catch {
                // Note: Safe transfer or supply to a pool can fail. In that case leave the LOAN token in repaid state
                // and
                // wait for the LOAN token owner to claim the repaid credit. Otherwise lender would be able to prevent
                // borrower from repaying the loan.
            }
        }
    }

    /**
     * @notice Check if the loan can be repaid.
     * @dev The function will revert if the loan cannot be repaid.
     * @param status Loan status.
     * @param defaultTimestamp Loan default timestamp.
     */
    function _checkLoanCanBeRepaid(uint8 status, uint40 defaultTimestamp) internal view {
        // Check that loan exists and is not from a different loan contract
        if (status == 0) revert NonExistingLoan();
        // Check that loan is running
        if (status != 2) revert LoanNotRunning();
        // Check that loan is not defaulted
        if (defaultTimestamp <= block.timestamp) {
            revert LoanDefaulted(defaultTimestamp);
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
     * @notice Update loan to repaid state.
     * @param loanId Id of a loan that is being repaid.
     */
    function _updateRepaidLoan(uint256 loanId) private {
        LOAN storage loan = LOANs[loanId];

        // Move loan to repaid state and wait for the loan owner to claim the repaid credit
        loan.status = 3;

        // Update accrued interest amount
        loan.fixedInterestAmount = _loanAccruedInterest(loan);
        loan.accruingInterestAPR = 0;

        // Note: Reusing `fixedInterestAmount` to store accrued interest at the time of repayment
        // to have the value at the time of claim and stop accruing new interest.

        emit LOANPaidBack({ loanId: loanId });
    }

    /* ------------------------------------------------------------ */
    /*                      LOAN REPAYMENT AMOUNT                   */
    /* ------------------------------------------------------------ */

    /**
     * @notice Calculate the loan repayment amount with fixed and accrued interest.
     * @param loanId Id of a loan.
     * @return Repayment amount.
     */
    function loanRepaymentAmount(uint256 loanId) public view returns (uint256) {
        LOAN storage loan = LOANs[loanId];

        // Check non-existent loan
        if (loan.status == 0) return 0;

        // Return loan principal with accrued interest
        return loan.principalAmount + _loanAccruedInterest(loan);
    }

    /**
     * @notice Calculates the loan repayment amount with fixed and accrued interest for a set of loan ids.
     * @dev Intended to be used to build permit data or credit token approvals
     * @param loanIds Array of loan ids.
     * @param creditAddress Expected credit address for all loan ids.
     * @return amount
     */
    function totalLoanRepaymentAmount(uint256[] calldata loanIds, address creditAddress)
        external
        view
        returns (uint256 amount)
    {
        for (uint256 i; i < loanIds.length; ++i) {
            uint256 loanId = loanIds[i];
            LOAN storage loan = LOANs[loanId];
            _checkLoanCreditAddress(loan.creditAddress, creditAddress);
            // Check non-existent loan
            if (loan.status == 0) return 0;

            // Add loan principal with accrued interest
            amount += loan.principalAmount + _loanAccruedInterest(loan);
        }
    }

    /**
     * @notice Calculate the loan accrued interest.
     * @param loan Loan data struct.
     * @return Accrued interest amount.
     */
    function _loanAccruedInterest(LOAN storage loan) private view returns (uint256) {
        if (loan.accruingInterestAPR == 0) return loan.fixedInterestAmount;

        uint256 accruingMinutes = (loan.defaultTimestamp - loan.startTimestamp) / 1 minutes;
        uint256 accruedInterest = Math.mulDiv(
            loan.principalAmount,
            uint256(loan.accruingInterestAPR) * accruingMinutes,
            Constants.ACCRUING_INTEREST_APR_DENOMINATOR,
            Math.Rounding.Ceil
        );
        return loan.fixedInterestAmount + accruedInterest;
    }

    /* ------------------------------------------------------------ */
    /*                          CLAIM LOAN                          */
    /* ------------------------------------------------------------ */

    /**
     * @notice Claim a repaid or defaulted loan.
     * @dev Only a LOAN token holder can claim a repaid or defaulted loan.
     *      Claim will transfer the repaid credit or collateral to a LOAN token holder address and burn the LOAN token.
     * @param loanId Id of a loan that is being claimed.
     */
    function claimLOAN(uint256 loanId) public {
        LOAN storage loan = LOANs[loanId];

        // Check that caller is LOAN token holder
        if (loanToken.ownerOf(loanId) != msg.sender) {
            revert CallerNotLOANTokenHolder();
        }

        if (loan.status == 0) {
            // Loan is not existing or from a different loan contract
            revert NonExistingLoan();
        } else if (loan.status == 3) {
            // Loan has been paid back
            _settleLoanClaim({ loanId: loanId, loanOwner: msg.sender, defaulted: false });
        } else if (loan.status == 2 && loan.defaultTimestamp <= block.timestamp) {
            // Loan is running but expired
            _settleLoanClaim({ loanId: loanId, loanOwner: msg.sender, defaulted: true });
        }
        // Loan is in wrong state
        else {
            revert LoanRunning();
        }
    }

    /**
     * @notice Claims multiple repaid or defaulted loans.
     * @dev Only a LOAN token holder can claim a repaid or defaulted loan.
     *      Claim will transfer the repaid credit or collateral to a LOAN token holder address and burn the LOAN token.
     * @param loanIds Array of ids of loans that are being claimed.
     */
    function claimMultipleLOANs(uint256[] calldata loanIds) external {
        uint256 l = loanIds.length;
        for (uint256 i; i < l; ++i) {
            claimLOAN(loanIds[i]);
        }
    }

    /**
     * @notice Try to claim a repaid loan for the loan owner.
     * @dev The function is called by the vault to repay a loan directly to the original lender or its source of funds
     *      if the loan owner is the original lender. If the transfer fails, the LOAN token will remain in repaid state
     *      and the LOAN token owner will be able to claim the repaid credit. Otherwise lender would be able to prevent
     *      borrower from repaying the loan.
     * @param loanId Id of a loan that is being claimed.
     * @param creditAmount Amount of a credit to be claimed.
     * @param loanOwner Address of the LOAN token holder.
     */
    function tryClaimRepaidLOAN(uint256 loanId, uint256 creditAmount, address loanOwner) external {
        if (msg.sender != address(this)) revert CallerNotVault();

        LOAN storage loan = LOANs[loanId];

        if (loan.status != 3) return;

        // If current loan owner is not original lender, the loan cannot be repaid directly, return without revert.
        if (loan.originalLender != loanOwner) return;

        // Note: The loan owner is the original lender at this point.

        address destinationOfFunds = loan.originalSourceOfFunds;
        address credit = loan.creditAddress;

        // Delete loan data & burn LOAN token before calling safe transfer
        _deleteLoan(loanId);

        emit LOANClaimed({ loanId: loanId, defaulted: false });

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

                revert InvalidSourceOfFunds({ sourceOfFunds: destinationOfFunds });
            }

            // Supply the repaid credit to the original pool
            _supplyToPool(credit, creditAmount, poolAdapter, destinationOfFunds, loanOwner);
        }

        // Note: If the transfer fails, the LOAN token will remain in repaid state and the LOAN token owner
        // will be able to claim the repaid credit. Otherwise lender would be able to prevent borrower from
        // repaying the loan.
    }

    /**
     * @notice Settle the loan claim.
     * @param loanId Id of a loan that is being claimed.
     * @param loanOwner Address of the LOAN token holder.
     * @param defaulted If the loan is defaulted.
     */
    function _settleLoanClaim(uint256 loanId, address loanOwner, bool defaulted) private {
        LOAN storage loan = LOANs[loanId];

        // Store in memory before deleting the loan
        address asset = defaulted ? loan.collateral : loan.creditAddress;
        uint256 assetAmount = defaulted ? loan.collateralAmount : loanRepaymentAmount(loanId);

        // Delete loan data & burn LOAN token before calling safe transfer
        _deleteLoan(loanId);

        emit LOANClaimed({ loanId: loanId, defaulted: defaulted });

        // Transfer asset to current LOAN token owner
        _push(asset, assetAmount, loanOwner);
    }

    /**
     * @notice Delete loan data and burn LOAN token.
     * @param loanId Id of a loan that is being deleted.
     */
    function _deleteLoan(uint256 loanId) private {
        loanToken.burn(loanId);
        delete LOANs[loanId];
    }

    /* ------------------------------------------------------------ */
    /*                          GET LOAN                            */
    /* ------------------------------------------------------------ */

    /**
     * @notice Return a LOAN data struct associated with a loan id.
     * @param loanId Id of a loan in question.
     * @return loanInfo Loan information struct.
     */
    function getLOAN(uint256 loanId) external view returns (LoanInfo memory loanInfo) {
        LOAN storage loan = LOANs[loanId];

        loanInfo.status = _getLOANStatus(loanId);
        loanInfo.startTimestamp = loan.startTimestamp;
        loanInfo.defaultTimestamp = loan.defaultTimestamp;
        loanInfo.borrower = loan.borrower;
        loanInfo.originalLender = loan.originalLender;
        loanInfo.loanOwner = loan.status != 0 ? loanToken.ownerOf(loanId) : address(0);
        loanInfo.accruingInterestAPR = loan.accruingInterestAPR;
        loanInfo.fixedInterestAmount = loan.fixedInterestAmount;
        loanInfo.credit = loan.creditAddress;
        loanInfo.collateral = loan.collateral;
        loanInfo.collateralAmount = loan.collateralAmount;
        loanInfo.originalSourceOfFunds = loan.originalSourceOfFunds;
        loanInfo.repaymentAmount = loanRepaymentAmount(loanId);
    }

    /**
     * @notice Return a LOAN status associated with a loan id.
     * @param loanId Id of a loan in question.
     * @return status LOAN status.
     */
    function _getLOANStatus(uint256 loanId) private view returns (uint8) {
        LOAN storage loan = LOANs[loanId];
        return (loan.status == 2 && loan.defaultTimestamp <= block.timestamp) ? 4 : loan.status;
    }

    /* ------------------------------------------------------------ */
    /*                      ISproLoanMetadataProvider                */
    /* ------------------------------------------------------------ */

    /**
     * @inheritdoc ISproLoanMetadataProvider
     */
    function loanMetadataUri() external view override returns (string memory) {
        return loanMetadataUri(address(this));
    }

    /* -------------------------------------------------------------------------- */
    /*                                  PROPOSAL                                  */
    /* -------------------------------------------------------------------------- */

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
        internal
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
     * @param acceptor Address of a proposal acceptor.
     * @param creditAmount Amount of credit to lend.
     * @param proposalData Encoded proposal data with signature.
     * @return proposalHash Proposal hash.
     * @return loanTerms Loan terms.
     */
    function acceptProposal(address acceptor, uint256 creditAmount, bytes calldata proposalData)
        internal
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
    function _cancelProposal(bytes calldata proposalData)
        internal
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
     * @param proposalTypehash Proposal typehash.
     * @param encodedProposal Encoded proposal struct.
     * @return Struct hash.
     */
    function _getProposalHash(bytes32 proposalTypehash, bytes memory encodedProposal) internal view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                hex"1901", DOMAIN_SEPARATOR_PROPOSAL, keccak256(abi.encodePacked(proposalTypehash, encodedProposal))
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
     * @param creditAmount Amount of credit to lend.
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
            revert SproRevokedNonce.NonceNotUsable({
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
                Math.mulDiv(proposal.availableCreditLimit, partialPositionPercentage, Constants.PERCENTAGE);
            if (creditAmount < minCreditAmount) {
                revert CreditAmountTooSmall({ amount: creditAmount, minimum: minCreditAmount });
            }

            uint256 maxCreditAmount = Math.mulDiv(
                proposal.availableCreditLimit, (Constants.PERCENTAGE - partialPositionPercentage), Constants.PERCENTAGE
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
