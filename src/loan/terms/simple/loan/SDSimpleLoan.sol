// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { SDConfig } from "pwn/config/SDConfig.sol";
import { PWNHub } from "pwn/hub/PWNHub.sol";
import { PWNHubTags } from "pwn/hub/PWNHubTags.sol";
import { IERC5646 } from "pwn/interfaces/IERC5646.sol";
import { IPoolAdapter } from "pwn/interfaces/IPoolAdapter.sol";
import { IPWNLoanMetadataProvider } from "pwn/interfaces/IPWNLoanMetadataProvider.sol";
import { SDListedFee } from "pwn/loan/lib/SDListedFee.sol";
import { SDSimpleLoanProposal } from "pwn/loan/terms/simple/proposal/SDSimpleLoanProposal.sol";
import { PWNLOAN } from "pwn/loan/token/PWNLOAN.sol";
import { Permit, InvalidPermitOwner, InvalidPermitAsset } from "pwn/loan/vault/Permit.sol";
import { PWNVault } from "pwn/loan/vault/PWNVault.sol";
import { PWNRevokedNonce } from "pwn/nonce/PWNRevokedNonce.sol";
import { Expired, AddressMissingHubTag } from "pwn/PWNErrors.sol";
import { SDSimpleLoanSimpleProposal } from "pwn/loan/terms/simple/proposal/SDSimpleLoanSimpleProposal.sol";

/**
 * @title SD Simple Loan -- forked from PWNSimpleLoan.sol
 * @notice Contract managing a simple loan in PWN protocol.
 * @dev Acts as a vault for every loan created by this contract.
 */
contract SDSimpleLoan is PWNVault, IERC5646, IPWNLoanMetadataProvider {
    string public constant VERSION = "1.0";

    /* ------------------------------------------------------------ */
    /*  VARIABLES & CONSTANTS DEFINITIONS                        */
    /* ------------------------------------------------------------ */

    uint32 public constant MIN_LOAN_DURATION = 10 minutes;
    uint40 public constant MAX_ACCRUING_INTEREST_APR = 16e6; // 160,000 APR (with 2 decimals)

    uint256 public constant ACCRUING_INTEREST_APR_DECIMALS = 1e2;
    uint256 public constant MINUTES_IN_YEAR = 525_600; // Note: Assuming 365 days in a year
    uint256 public constant ACCRUING_INTEREST_APR_DENOMINATOR = ACCRUING_INTEREST_APR_DECIMALS * MINUTES_IN_YEAR * 100;

    uint256 public constant MAX_EXTENSION_DURATION = 90 days;
    uint256 public constant MIN_EXTENSION_DURATION = 1 days;

    bytes32 public immutable DOMAIN_SEPARATOR = keccak256(
        abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256("SDSimpleLoan"),
            keccak256(abi.encodePacked(VERSION)),
            block.chainid,
            address(this)
        )
    );

    PWNHub public immutable hub;
    PWNLOAN public immutable loanToken;
    SDConfig public immutable config;
    PWNRevokedNonce public immutable revokedNonce;

    /**
     * @notice Struct defining a simple loan terms.
     * @dev This struct is created by proposal contracts and never stored.
     * @param lender Address of a lender.
     * @param borrower Address of a borrower.
     * @param startTimestamp Unix timestamp (in seconds) of a start date.
     * @param defaultTimestamp Unix timestamp (in seconds) of a default date.
     * @param collateral Address of a collateral asset.
     * @param collateralAmount Amount of a collateral asset.
     * @param credit Address of a credit asset.
     * @param creditAmount Amount of a credit asset.
     * @param fixedInterestAmount Fixed interest amount in credit asset tokens. It is the minimum amount of interest
     * which has to be paid by a borrower.
     * @param accruingInterestAPR Accruing interest APR with 2 decimals.
     * @param lenderSpecHash Hash of a lender specification.
     * @param borrowerSpecHash Hash of a borrower specification.
     */
    struct Terms {
        address lender;
        address borrower;
        uint40 startTimestamp;
        uint40 defaultTimestamp;
        address collateral;
        uint256 collateralAmount;
        address credit;
        uint256 creditAmount;
        uint256 fixedInterestAmount;
        uint24 accruingInterestAPR;
        bytes32 lenderSpecHash;
        bytes32 borrowerSpecHash;
    }

    /**
     * @notice Loan proposal specification during loan creation.
     * @param proposalContract Address of a loan proposal contract.
     * @param proposalData Encoded proposal data that is passed to the loan proposal contract.
     */
    struct ProposalSpec {
        address proposalContract;
        bytes proposalData;
    }

    /**
     * @notice Lender specification during loan creation.
     * @param sourceOfFunds Address of a source of funds. This can be the lenders address, if the loan is funded
     * directly,
     *                      or a pool address from with the funds are withdrawn on the lenders behalf.
     * @param creditAmount Amount of credit tokens to lend.
     * @param permitData Callers permit data for a loans credit asset.
     */
    struct LenderSpec {
        address sourceOfFunds;
        uint256 creditAmount;
        bytes permitData;
    }

    /**
     * @notice Struct defining a simple loan.
     * @param status 0 == none/dead || 2 == running/accepted offer/accepted request || 3 == paid back || 4 == expired.
     * @param creditAddress Address of an asset used as a loan credit.
     * @param originalSourceOfFunds Address of a source of funds that was used to fund the loan.
     * @param startTimestamp Unix timestamp (in seconds) of a start date.
     * @param defaultTimestamp Unix timestamp (in seconds) of a default date.
     * @param borrower Address of a borrower.
     * @param originalLender Address of a lender that funded the loan.
     * @param accruingInterestAPR Accruing interest APR with 2 decimals.
     * @param fixedInterestAmount Fixed interest amount in credit asset tokens.
     *                            It is the minimum amount of interest which has to be paid by a borrower.
     *                            This property is reused to store the final interest amount if the loan is repaid and
     * waiting to be claimed.
     * @param principalAmount Principal amount in credit asset tokens.
     * @param collateral Address of a collateral asset.
     * @param collateralAmount Amount of a collateral asset.
     */
    struct LOAN {
        uint8 status;
        address creditAddress;
        address originalSourceOfFunds;
        uint40 startTimestamp;
        uint40 defaultTimestamp;
        address borrower;
        address originalLender;
        uint24 accruingInterestAPR;
        uint256 fixedInterestAmount;
        uint256 principalAmount;
        address collateral;
        uint256 collateralAmount;
    }

    /**
     * Mapping of all LOAN data by loan id.
     */
    mapping(uint256 => LOAN) private LOANs;

    /* ------------------------------------------------------------ */
    /*                      EVENTS DEFINITIONS                      */
    /* ------------------------------------------------------------ */

    /**
     * @notice Emitted when a new loan in created.
     */
    event LOANCreated(
        uint256 indexed loanId,
        bytes32 indexed proposalHash,
        address indexed proposalContract,
        Terms terms,
        LenderSpec lenderSpec,
        bytes extra
    );

    /**
     * @notice Emitted when a loan is paid back.
     */
    event LOANPaidBack(uint256 indexed loanId);

    /**
     * @notice Emitted when a repaid or defaulted loan is claimed.
     */
    event LOANClaimed(uint256 indexed loanId, bool indexed defaulted);

    /* ------------------------------------------------------------ */
    /*                      ERRORS DEFINITIONS                      */
    /* ------------------------------------------------------------ */

    /**
     * @notice Thrown when a caller is not a stated proposer.
     */
    error CallerIsNotStatedProposer(address addr);

    /**
     * @notice Thrown when managed loan is running.
     */
    error LoanNotRunning();

    /**
     * @notice Thrown when manged loan is still running.
     */
    error LoanRunning();

    /**
     * @notice Thrown when managed loan is defaulted.
     */
    error LoanDefaulted(uint40);

    /**
     * @notice Thrown when loan doesn't exist.
     */
    error NonExistingLoan();

    /**
     * @notice Thrown when caller is not a LOAN token holder.
     */
    error CallerNotLOANTokenHolder();

    /**
     * @notice Thrown when loan duration is below the minimum.
     */
    error InvalidDuration(uint256 current, uint256 limit);

    /**
     * @notice Thrown when accruing interest APR is above the maximum.
     */
    error InterestAPROutOfBounds(uint256 current, uint256 limit);

    /**
     * @notice Thrown when caller is not a vault.
     */
    error CallerNotVault();

    /**
     * @notice Thrown when caller is not the borrower/proposer
     */
    error CallerNotProposer();

    /**
     * @notice Thrown when pool based source of funds doesn't have a registered adapter.
     */
    error InvalidSourceOfFunds(address sourceOfFunds);

    /**
     * @notice Thrown when the loan credit address is different than the expected credit address.
     */
    error DifferentCreditAddress(address loanCreditAddress, address expectedCreditAddress);

    /* ------------------------------------------------------------ */
    /*                          CONSTRUCTOR                         */
    /* ------------------------------------------------------------ */

    constructor(address _hub, address _loanToken, address _config, address _revokedNonce) {
        hub = PWNHub(_hub);
        loanToken = PWNLOAN(_loanToken);
        config = SDConfig(_config);
        revokedNonce = PWNRevokedNonce(_revokedNonce);
    }

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
     * @param proposalSpec Proposal specification struct.
     */
    function createProposal(ProposalSpec calldata proposalSpec) external {
        // Check provided proposal contract
        if (!hub.hasTag(proposalSpec.proposalContract, PWNHubTags.LOAN_PROPOSAL)) {
            revert AddressMissingHubTag({ addr: proposalSpec.proposalContract, tag: PWNHubTags.LOAN_PROPOSAL });
        }

        // Make the proposal
        (address proposer, address collateral, uint256 collateralAmount, address creditAddress, uint256 creditLimit) =
            SDSimpleLoanProposal(proposalSpec.proposalContract).makeProposal(proposalSpec.proposalData);

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
            _pushFrom(config.SDEX(), feeAmount, msg.sender, config.SINK());
        }
    }

    /* ------------------------------------------------------------ */
    /*        CANCEL PROPOSAL AND WITHDRAW UNUSED COLLATERAL        */
    /* ------------------------------------------------------------ */

    /**
     * @notice A borrower can cancel their proposal and withdraw unused collateral.
     * @dev Resets withdrawable collateral, revokes the nonce if needed, transfers unused collateral to the proposer.
     * @dev Fungible withdrawable collateral with amount == 0 calls should not revert, should transfer 0 tokens.
     * @param proposalSpec Proposal specification struct.
     */
    function cancelProposal(ProposalSpec calldata proposalSpec) external {
        // Check provided proposal contract
        if (!hub.hasTag(proposalSpec.proposalContract, PWNHubTags.LOAN_PROPOSAL)) {
            revert AddressMissingHubTag({ addr: proposalSpec.proposalContract, tag: PWNHubTags.LOAN_PROPOSAL });
        }

        (address proposer, address collateral, uint256 collateralAmount) =
            SDSimpleLoanProposal(proposalSpec.proposalContract).cancelProposal(proposalSpec.proposalData);

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
     * @param proposalSpec Proposal specification struct.
     * @param lenderSpec Lender specification struct.
     * @param extra Auxiliary data that are emitted in the loan creation event. They are not used in the contract logic.
     * @return loanId Id of the created LOAN token.
     */
    function createLOAN(ProposalSpec calldata proposalSpec, LenderSpec calldata lenderSpec, bytes calldata extra)
        external
        returns (uint256 loanId)
    {
        // Check provided proposal contract
        if (!hub.hasTag(proposalSpec.proposalContract, PWNHubTags.LOAN_PROPOSAL)) {
            revert AddressMissingHubTag({ addr: proposalSpec.proposalContract, tag: PWNHubTags.LOAN_PROPOSAL });
        }

        // Accept proposal and get loan terms
        (bytes32 proposalHash, Terms memory loanTerms) = SDSimpleLoanProposal(proposalSpec.proposalContract)
            .acceptProposal({
            acceptor: msg.sender,
            creditAmount: lenderSpec.creditAmount,
            proposalData: proposalSpec.proposalData
        });

        // Check minimum loan duration
        if (loanTerms.defaultTimestamp - loanTerms.startTimestamp < MIN_LOAN_DURATION) {
            revert InvalidDuration({
                current: loanTerms.defaultTimestamp - loanTerms.startTimestamp,
                limit: MIN_LOAN_DURATION
            });
        }

        // Check maximum accruing interest APR
        if (loanTerms.accruingInterestAPR > MAX_ACCRUING_INTEREST_APR) {
            revert InterestAPROutOfBounds({ current: loanTerms.accruingInterestAPR, limit: MAX_ACCRUING_INTEREST_APR });
        }

        // Create a new loan
        loanId = _createLoan({ loanTerms: loanTerms, lenderSpec: lenderSpec });

        emit LOANCreated({
            loanId: loanId,
            proposalHash: proposalHash,
            proposalContract: proposalSpec.proposalContract,
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
        uint256 tokenFactor = config.tokenFactors(assetAddress);
        return (tokenFactor == 0)
            ? config.fixFeeUnlisted()
            : SDListedFee.calculate(config.fixFeeListed(), config.variableFactor(), tokenFactor, amount);
    }

    /**
     * @notice Transfers credit to borrower
     * @dev The function assumes a prior token approval to a contract address or signed permits.
     * @param loanTerms Loan terms struct.
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
        IPoolAdapter poolAdapter = config.getPoolAdapter(lenderSpec.sourceOfFunds);
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
            loan.principalAmount, uint256(loan.accruingInterestAPR) * accruingMinutes, ACCRUING_INTEREST_APR_DENOMINATOR
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
            IPoolAdapter poolAdapter = config.getPoolAdapter(destinationOfFunds);
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
     * @notice Loan information struct.
     * @param status LOAN status.
     * @param startTimestamp Unix timestamp (in seconds) of a loan creation date.
     * @param defaultTimestamp Unix timestamp (in seconds) of a loan default date.
     * @param borrower Address of a loan borrower.
     * @param originalLender Address of a loan original lender.
     * @param loanOwner Address of a LOAN token holder.
     * @param accruingInterestAPR Accruing interest APR with 2 decimal places.
     * @param fixedInterestAmount Fixed interest amount in credit asset tokens.
     * @param credit Address of a credit asset.
     * @param collateral Address of a collateral asset.
     * @param collateralAmount Amount of a collateral asset.
     * @param originalSourceOfFunds Address of a source of funds for the loan. Original lender address, if the loan was
     * funded directly, or a pool address from witch credit funds were withdrawn / borrowred.
     * @param repaymentAmount Loan repayment amount in credit asset tokens.
     */
    struct LoanInfo {
        uint8 status;
        uint40 startTimestamp;
        uint40 defaultTimestamp;
        address borrower;
        address originalLender;
        address loanOwner;
        uint24 accruingInterestAPR;
        uint256 fixedInterestAmount;
        address credit;
        address collateral;
        uint256 collateralAmount;
        address originalSourceOfFunds;
        uint256 repaymentAmount;
    }

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
    /*                      IPWNLoanMetadataProvider                */
    /* ------------------------------------------------------------ */

    /**
     * @inheritdoc IPWNLoanMetadataProvider
     */
    function loanMetadataUri() external view override returns (string memory) {
        return config.loanMetadataUri(address(this));
    }

    /* ------------------------------------------------------------ */
    /*                            ERC5646                           */
    /* ------------------------------------------------------------ */

    /**
     * @inheritdoc IERC5646
     */
    function getStateFingerprint(uint256 tokenId) external view virtual override returns (bytes32) {
        LOAN storage loan = LOANs[tokenId];

        if (loan.status == 0) return bytes32(0);

        // The only mutable state properties are:
        // - status: updated for expired loans based on block.timestamp
        // - defaultTimestamp: updated when the loan is extended
        // - fixedInterestAmount: updated when the loan is repaid and waiting to be claimed
        // - accruingInterestAPR: updated when the loan is repaid and waiting to be claimed
        // Others don't have to be part of the state fingerprint as it does not act as a token identification.
        return keccak256(
            abi.encode(
                _getLOANStatus(tokenId), loan.defaultTimestamp, loan.fixedInterestAmount, loan.accruingInterestAPR
            )
        );
    }
}
