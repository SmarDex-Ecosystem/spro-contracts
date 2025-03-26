// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IAllowanceTransfer } from "permit2/src/interfaces/IAllowanceTransfer.sol";

import { SproLoan } from "src/spro/SproLoan.sol";

interface ISproStorage {
    /**
     * @notice Retrieves the denominator used for the reward multipliers.
     * @return BPS_DIVISOR The BPS divisor.
     */
    function BPS_DIVISOR() external view returns (uint256 BPS_DIVISOR);

    /**
     * @notice Retrieves the maximum SDEX fee that can be set by the contract owner.
     * @return MAX_SDEX_FEE The maximum allowable fee in SDEX.
     */
    function MAX_SDEX_FEE() external view returns (uint256 MAX_SDEX_FEE);

    /**
     * @notice Retrieves the minimum loan duration allowed, expressed in seconds.
     * @return MIN_LOAN_DURATION The minimum duration of a loan in seconds.
     */
    function MIN_LOAN_DURATION() external view returns (uint32 MIN_LOAN_DURATION);

    /**
     * @notice Retrieves the address of the SDEX token contract.
     * @return SDEX The address of the SDEX token contract.
     */
    function SDEX() external view returns (address SDEX);

    /**
     * @notice Retrieves the address of the Permit2 contract used for transfer management.
     * @return PERMIT2 The address of the Permit2 contract.
     */
    function PERMIT2() external view returns (IAllowanceTransfer PERMIT2);

    /**
     * @notice Retrieves the current proposal nonce.
     * @return proposalNonce The current proposal nonce.
     */
    function proposalNonce() external view returns (uint256 proposalNonce);

    /**
     * @notice Retrieves the minimum usage ratio for partial lending, expressed in basis points.
     * @return _partialPositionBps The minimum usage ratio for partial lending.
     */
    function _partialPositionBps() external view returns (uint16 _partialPositionBps);

    /**
     * @notice Retrieves the protocol fixed SDEX fee value.
     * @return _fee The amount of SDEX required to pay the fee.
     */
    function _fee() external view returns (uint256 _fee);

    /**
     * @notice Retrieves the address of the {SproLoan} contract.
     * @return _loanToken The contract is an ERC721 token.
     */
    function _loanToken() external view returns (SproLoan _loanToken);

    /**
     * @notice Retrieves the withdrawable collateral amount for a given proposal hash.
     * @param proposalHash The hash of the proposal.
     * @return _withdrawableCollateral The remaining collateral amount for the proposal.
     */
    function _withdrawableCollateral(bytes32 proposalHash) external view returns (uint256 _withdrawableCollateral);

    /**
     * @notice Checks if a proposal has already been made for a given proposal hash.
     * @param proposalHash The hash of the proposal.
     * @return _proposalsMade True if the proposal has already been made, false otherwise.
     */
    function _proposalsMade(bytes32 proposalHash) external view returns (bool _proposalsMade);

    /**
     * @notice Retrieves the credit already used for a given proposal hash.
     * @param proposalHash The hash of the proposal.
     * @return _creditUsed The amount of credit already used for the given proposal hash.
     */
    function _creditUsed(bytes32 proposalHash) external view returns (uint256 _creditUsed);
}
