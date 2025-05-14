// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { INFTRenderer } from "src/interfaces/INFTRenderer.sol";

interface IP2PLendingLoan is IERC721 {
    /**
     * @notice Emitted when the NFT renderer is updated.
     * @param nftRenderer The new NFT renderer address.
     */
    event NftRendererUpdated(address nftRenderer);

    /// @notice The given NFT renderer address is invalid.
    error P2PLendingLoanInvalidNftRendererAddress();

    /**
     * @notice Retrieves the last used ID.
     * @dev The first ID is 1, this value is incremental.
     * @return lastLoanId_ The last used ID.
     */
    function _lastLoanId() external view returns (uint256 lastLoanId_);

    /**
     * @notice Retrieves the NFT renderer.
     * @dev The NFT renderer is used to render the token URI.
     * @return nftRenderer_ The NFT renderer.
     */
    function _nftRenderer() external view returns (INFTRenderer nftRenderer_);

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
}
