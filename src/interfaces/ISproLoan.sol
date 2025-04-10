// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ISproLoan is IERC721 {
    /**
     * @notice Retrieves the last used ID.
     * @dev The first ID is 1, this value is incremental.
     * @return _lastLoanId The last used ID.
     */
    function _lastLoanId() external view returns (uint256 _lastLoanId);

    /**
     * @notice Mints a new token.
     * @dev Only the owner can mint a new token.
     * @param to The address of the new token owner.
     * @return loanId The Id of the new token.
     */
    function mint(address to) external returns (uint256 loanId);

    /**
     * @notice Burns a token.
     * @dev Only the owner can burn a token.
     * @param loanId The Id of the token to burn.
     */
    function burn(uint256 loanId) external;
}
