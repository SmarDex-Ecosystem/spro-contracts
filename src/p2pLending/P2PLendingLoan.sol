// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IP2PLendingLoan } from "src/interfaces/IP2PLendingLoan.sol";
import { INFTRenderer } from "src/interfaces/INFTRenderer.sol";
import { IP2PLending } from "src/interfaces/IP2PLending.sol";
import { NFTRenderer } from "src/p2pLending/NFTRenderer.sol";
import { IP2PLendingTypes } from "src/interfaces/IP2PLendingTypes.sol";

contract P2PLendingLoan is IP2PLendingLoan, ERC721, Ownable {
    /// @inheritdoc IP2PLendingLoan
    uint256 public _lastLoanId;

    /// @inheritdoc IP2PLendingLoan
    INFTRenderer public _nftRenderer;

    /// @param deployer The deployer address.
    constructor(address deployer) ERC721("P2P Loan", "P2PLOAN") Ownable(deployer) {
        _nftRenderer = new NFTRenderer();
    }

    /// @inheritdoc IP2PLendingLoan
    function setNftRenderer(INFTRenderer nftRenderer) external onlyOwner {
        if (address(nftRenderer) == address(0)) {
            revert IP2PLendingLoan.P2PLendingLoanInvalidNftRendererAddress();
        }
        _nftRenderer = nftRenderer;
        emit IP2PLendingLoan.NftRendererUpdated(address(nftRenderer));
    }

    /// @inheritdoc IP2PLendingLoan
    function mint(address to) external onlyOwner returns (uint256 loanId_) {
        loanId_ = ++_lastLoanId;
        _mint(to, loanId_);
    }

    /// @inheritdoc IP2PLendingLoan
    function burn(uint256 loanId) external onlyOwner {
        _burn(loanId);
    }

    /// @inheritdoc ERC721
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory uri_) {
        _requireOwned(tokenId);
        IP2PLendingTypes.Loan memory loan = IP2PLending(owner()).getLoan(tokenId);
        return _nftRenderer.render(loan);
    }
}
