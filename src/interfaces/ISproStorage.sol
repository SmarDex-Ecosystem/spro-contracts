// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IAllowanceTransfer } from "permit2/src/interfaces/IAllowanceTransfer.sol";

import { SproLoan } from "src/spro/SproLoan.sol";

interface ISproStorage {
    /**
     * @notice Gets the divisor for basis point (BPS) values.
     * @return BPS_DIVISOR The divisor required to calculate percentage values.
     */
    function BPS_DIVISOR() external view returns (uint256 BPS_DIVISOR);

    /**
     * @notice Gets the maximum SDEX fee allowed.
     * @return MAX_SDEX_FEE The maximum fee can be set by the owner.
     */
    function MAX_SDEX_FEE() external view returns (uint256 MAX_SDEX_FEE);

    /**
     * @notice Gets the minimum loan duration allowed.
     * @return MIN_LOAN_DURATION The duration of a loan in seconds.
     */
    function MIN_LOAN_DURATION() external view returns (uint32 MIN_LOAN_DURATION);

    /**
     * @notice Gets the SDEX token address.
     * @return SDEX The public address of the SDEX token.
     */
    function SDEX() external view returns (address SDEX);

    /**
     * @notice Gets the permit2 contract address.
     * @return PERMIT2 The public address of the permit2 contract.
     */
    function PERMIT2() external view returns (IAllowanceTransfer PERMIT2);

    /**
     * @notice Gets the minimum usage ratio for partial lending (in basis points).
     * @return _partialPositionBps The minimum usage ratio for partial lending.
     */
    function _partialPositionBps() external view returns (uint16 _partialPositionBps);

    /**
     * @notice Gets the protocol fixed SDEX fee value.
     * @return _fee The amount of SDEX required to pay the fee.
     */
    function _fee() external view returns (uint256 _fee);

    /**
     * @notice Gets the {SproLoan} contract address.
     * @return _loanToken The contract address is an ERC721 token.
     */
    function _loanToken() external view returns (SproLoan _loanToken);

    /**
     * @notice Gets the withdrawable collateral amount for a given proposal hash.
     * @param proposalHash The hash of the proposal.
     * @return _withdrawableCollateral The remaining collateral amount for the proposal.
     */
    function _withdrawableCollateral(bytes32 proposalHash) external view returns (uint256 _withdrawableCollateral);

    /**
     * @notice Checks if a proposal has already been made.
     * @param proposalHash The hash of the proposal.
     * @return _proposalsMade True if the proposal has already been made.
     */
    function _proposalsMade(bytes32 proposalHash) external view returns (bool _proposalsMade);

    /**
     * @notice Gets the credit already used for a given proposal hash.
     * @param proposalHash The hash of the proposal.
     * @return _creditUsed The credit already used for the given proposal hash.
     */
    function _creditUsed(bytes32 proposalHash) external view returns (uint256 _creditUsed);
}
