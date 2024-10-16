// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { IPoolAdapter } from "src/interfaces/IPoolAdapter.sol";
import { ISproTypes } from "src/interfaces/ISproTypes.sol";
import { ISproErrors } from "src/interfaces/ISproErrors.sol";
import { ISproEvents } from "src/interfaces/ISproEvents.sol";

/**
 * @title ISpro
 * @notice Interface for Spro protocol.
 */
interface ISpro is ISproTypes, ISproErrors, ISproEvents {
    /* -------------------------------------------------------------------------- */
    /*                                   SETTER                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Set new protocol listed fee value.
     * @param fee New listed fee value in amount SDEX tokens (units 1e18)
     */
    function setFixFeeListed(uint256 fee) external;

    /**
     * @notice Set new protocol unlisted fee value.
     * @param fee New unlisted fee value in amount SDEX tokens (units 1e18)
     */
    function setFixFeeUnlisted(uint256 fee) external;

    /**
     * @notice List or unlist a token.
     * @param token Credit token address.
     * @param list True if the token is listed.
     */
    function setListedToken(address token, bool list) external;

    /**
     * @notice Set percentage of a proposal's availableCreditLimit which can be used in partial lending.
     * @param percentage New percentage value.
     */
    function setPartialPositionPercentage(uint16 percentage) external;

    /**
     * @notice Set a Loan token metadata uri for a specific loan contract.
     * @param loanContract Address of a loan contract.
     * @param metadataUri New value of Loan token metadata uri for given `loanContract`.
     */
    function setLoanMetadataUri(address loanContract, string memory metadataUri) external;

    /**
     * @notice Set a default Loan token metadata uri.
     * @param metadataUri New value of default Loan token metadata uri.
     */
    function setDefaultLoanMetadataUri(string memory metadataUri) external;

    /* -------------------------------------------------------------------------- */
    /*                                   GETTER                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Get hash of a lender specification.
     * @param lenderSpec Lender specification struct.
     * @return Hash of a lender specification.
     */
    function getLenderSpecHash(ISproTypes.LenderSpec memory lenderSpec) external pure returns (bytes32);

    /**
     * @notice Get an proposal hash according to EIP-712
     * @param proposal Proposal struct to be hashed.
     * @return Proposal struct hash.
     */
    function getProposalHash(ISproTypes.Proposal memory proposal) external returns (bytes32);

    /**
     * @notice Getter for credit used and credit remaining for a proposal.
     * @param proposal Proposal struct.
     * @return used_ Credit used for the proposal.
     * @return remaining_ Credit remaining for the proposal.
     */
    function getProposalCreditStatus(ISproTypes.Proposal memory proposal)
        external
        view
        returns (uint256 used_, uint256 remaining_);

    /**
     * @notice Return a Loan data struct associated with a loan id.
     * @param loanId Id of a loan in question.
     * @return loanInfo_ Loan information struct.
     */
    function getLoan(uint256 loanId) external view returns (ISproTypes.LoanInfo memory loanInfo_);

    /* -------------------------------------------------------------------------- */
    /*                                    VIEW                                    */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Get the fee to create or refinance the loan.
     * @dev The function returns the fee in SDEX tokens.
     * @param assetAddress Address of an asset to be used.
     */
    function getLoanFee(address assetAddress) external view returns (uint256 fee);

    /**
     * @notice Return a Loan token metadata uri base on a loan contract that minted the token.
     * @param loanContract Address of a loan contract.
     * @return uri_ Metadata uri for given loan contract.
     */
    function loanMetadataUri(address loanContract) external view returns (string memory uri_);

    /**
     * @notice Calculate the loan repayment amount with fixed and accrued interest.
     * @param loanId Id of a loan.
     * @return Repayment amount.
     */
    function loanRepaymentAmount(uint256 loanId) external view returns (uint256);

    /**
     * @notice Calculates the loan repayment amount with fixed and accrued interest for a set of loan ids.
     * @dev Intended to be used to build permit data or credit token approvals
     * @param loanIds Array of loan ids.
     * @param creditAddress Expected credit address for all loan ids.
     * @return amount_ Total repayment amount for loan.
     */
    function totalLoanRepaymentAmount(uint256[] memory loanIds, address creditAddress)
        external
        view
        returns (uint256 amount_);

    /* ------------------------------------------------------------ */
    /*                          POOL ADAPTER                        */
    /* ------------------------------------------------------------ */

    /**
     * @notice Returns the pool adapter for a given pool.
     * @param pool The pool for which the adapter is requested.
     * @return The adapter for the given pool.
     */
    function getPoolAdapter(address pool) external view returns (IPoolAdapter);

    /**
     * @notice Registers a pool adapter for a given pool.
     * @param pool The pool for which the adapter is registered.
     * @param adapter The adapter to be registered.
     */
    function registerPoolAdapter(address pool, address adapter) external;

    /* ------------------------------------------------------------ */
    /*                      CREATE PROPOSAL                         */
    /* ------------------------------------------------------------ */

    /**
     * @notice Create a borrow request proposal and transfers collateral to the vault and SDEX to fee sink.
     * @param proposal Proposal struct.
     */
    function createProposal(Proposal memory proposal) external;

    /* ------------------------------------------------------------ */
    /*        CANCEL PROPOSAL AND WITHDRAW UNUSED COLLATERAL        */
    /* ------------------------------------------------------------ */

    /**
     * @notice A borrower can cancel their proposal and withdraw unused collateral.
     * @dev Resets withdrawable collateral, revokes the nonce if needed, transfers unused collateral to the proposer.
     * @dev Fungible withdrawable collateral with amount == 0 calls should not revert, should transfer 0 tokens.
     * @param proposal Proposal struct.
     */
    function cancelProposal(Proposal memory proposal) external;

    /* ------------------------------------------------------------ */
    /*                          CREATE LOAN                         */
    /* ------------------------------------------------------------ */

    /**
     * @notice Create a new loan.
     * @dev The function assumes a prior token approval to a contract address or signed permits.
     * @param proposal Proposal struct.
     * @param lenderSpec Lender specification struct.
     * @param extra Auxiliary data that are emitted in the loan creation event. They are not used in the contract logic.
     * @return loanId_ Id of the created Loan token.
     */
    function createLoan(Proposal memory proposal, ISproTypes.LenderSpec memory lenderSpec, bytes memory extra)
        external
        returns (uint256 loanId_);

    /* ------------------------------------------------------------ */
    /*                          REPAY LOAN                          */
    /* ------------------------------------------------------------ */

    /**
     * @notice Repay running loan.
     * @dev Any address can repay a running loan, but a collateral will be transferred to a borrower address associated
     * with the loan.
     *      If the Loan token holder is the same as the original lender, the repayment credit asset will be
     *      transferred to the Loan token holder directly. Otherwise it will transfer the repayment credit asset to
     *      a vault, waiting on a Loan token holder to claim it. The function assumes a prior token approval to a
     * contract address
     *      or a signed permit.
     * @param loanId Id of a loan that is being repaid.
     * @param permitData Callers credit permit data.
     */
    function repayLoan(uint256 loanId, bytes calldata permitData) external;

    /**
     * @notice Repay running loans.
     * @dev Any address can repay a running loan, but a collateral will be transferred to a borrower address associated
     * with the loan.
     *      If the Loan token holder is the same as the original lender, the repayment credit asset will be
     *      transferred to the Loan token holder directly. Otherwise it will transfer the repayment credit asset to
     *      a vault, waiting on a Loan token holder to claim it. The function assumes a prior token approval to a
     * contract address
     *      or a signed permit.
     * @param loanIds Id array of loans that are being repaid.
     * @param creditAddress Expected credit address for all loan ids.
     * @param permitData Callers credit permit data.
     */
    function repayMultipleLoans(uint256[] calldata loanIds, address creditAddress, bytes calldata permitData)
        external;

    /* ------------------------------------------------------------ */
    /*                          CLAIM LOAN                          */
    /* ------------------------------------------------------------ */

    /**
     * @notice Claim a repaid or defaulted loan.
     * @dev Only a Loan token holder can claim a repaid or defaulted loan.
     *      Claim will transfer the repaid credit or collateral to a Loan token holder address and burn the Loan token.
     * @param loanId Id of a loan that is being claimed.
     */
    function claimLoan(uint256 loanId) external;

    /**
     * @notice Claims multiple repaid or defaulted loans.
     * @dev Only a Loan token holder can claim a repaid or defaulted loan.
     *      Claim will transfer the repaid credit or collateral to a Loan token holder address and burn the Loan token.
     * @param loanIds Array of ids of loans that are being claimed.
     */
    function claimMultipleLoans(uint256[] memory loanIds) external;

    /**
     * @notice Try to claim a repaid loan for the loan owner.
     * @dev The function is called by the vault to repay a loan directly to the original lender or its source of funds
     *      if the loan owner is the original lender. If the transfer fails, the Loan token will remain in repaid state
     *      and the Loan token owner will be able to claim the repaid credit. Otherwise lender would be able to prevent
     *      borrower from repaying the loan.
     * @param loanId Id of a loan that is being claimed.
     * @param creditAmount Amount of a credit to be claimed.
     * @param loanOwner Address of the Loan token holder.
     */
    function tryClaimRepaidLoan(uint256 loanId, uint256 creditAmount, address loanOwner) external;

    /* ------------------------------------------------------------ */
    /*                          EXTERNALS                           */
    /* ------------------------------------------------------------ */

    /**
     * @notice Helper function for revoking a proposal nonce on behalf of a caller.
     * @param nonceSpace Nonce space of a proposal nonce to be revoked.
     * @param nonce Proposal nonce to be revoked.
     */
    function revokeNonce(uint256 nonceSpace, uint256 nonce) external;
}
