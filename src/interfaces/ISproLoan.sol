// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { INFTRenderer } from "src/interfaces/INFTRenderer.sol";

interface ISproLoan is IERC721 {
    /* -------------------------------------------------------------------------- */
    /*                                  Functions                                 */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Retrieves the last used ID.
     * @dev The first ID is 1, this value is incremental.
     * @return _lastLoanId The last used ID.
     */
    function _lastLoanId() external view returns (uint256 _lastLoanId);

    /**
     * @notice Retrieves the NFT renderer.
     * @dev The NFT renderer is used to render the token URI.
     * @return _nftRenderer The NFT renderer.
     */
    function _nftRenderer() external view returns (INFTRenderer _nftRenderer);

    /**
     * @notice Sets the NFT renderer.
     * @dev Only the owner can set the NFT renderer.
     * @param nftRenderer The address of the new NFT renderer.
     */
    function setNftRenderer(INFTRenderer nftRenderer) external;

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

    /* -------------------------------------------------------------------------- */
    /*                                   Errors                                   */
    /* -------------------------------------------------------------------------- */

    /// @notice The given NFT renderer address is invalid.
    error SproLoanInvalidNftRendererAddress();

    /* -------------------------------------------------------------------------- */
    /*                                   Events                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Emitted when the NFT renderer is updated.
     * @param nftRenderer The new NFT renderer address.
     */
    event NftRendererUpdated(address nftRenderer);
}
