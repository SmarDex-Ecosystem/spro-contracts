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
     * @notice Retrieves the metadata URI.
     * @return _metadataUri The url that returns the token information.
     */
    function _metadataUri() external view returns (string memory _metadataUri);

    /**
     * @notice A new token was minted.
     * @param loanId The Id of the new token.
     * @param owner The address of the new token owner.
     */
    event LoanMinted(uint256 indexed loanId, address indexed owner);

    /**
     * @notice A token was burned.
     * @param loanId the Id of the token.
     */
    event LoanBurned(uint256 indexed loanId);

    /**
     * @notice The token metadata uri was updated.
     * @param newUri The new metadata uri.
     */
    event LoanMetadataUriUpdated(string newUri);

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

    /**
     * @notice Sets a new metadata uri.
     * @dev Only the owner can set a new metadata uri.
     * @param newMetadataUri The new metadata uri.
     */
    function setLoanMetadataUri(string memory newMetadataUri) external;
}
