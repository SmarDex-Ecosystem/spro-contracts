// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { ISproLoan } from "src/interfaces/ISproLoan.sol";
import { INFTRenderer } from "src/interfaces/INFTRenderer.sol";
import { ISpro } from "src/interfaces/ISpro.sol";
import { NFTRenderer } from "src/spro/NFTRenderer.sol";
import { ISproTypes } from "src/interfaces/ISproTypes.sol";

contract SproLoan is ISproLoan, ERC721, Ownable {
    /// @inheritdoc ISproLoan
    uint256 public _lastLoanId;

    /// @inheritdoc ISproLoan
    INFTRenderer public _nftRenderer;

    /// @param deployer The deployer address.
    constructor(address deployer) ERC721("P2P Loan", "P2PLOAN") Ownable(deployer) {
        _nftRenderer = new NFTRenderer();
    }

    /// @inheritdoc ISproLoan
    function setNftRenderer(INFTRenderer nftRenderer) external onlyOwner {
        if (address(nftRenderer) == address(0)) {
            revert ISproLoan.SproLoanInvalidNftRendererAddress();
        }
        _nftRenderer = nftRenderer;
        emit ISproLoan.NftRendererUpdated(address(nftRenderer));
    }

    /// @inheritdoc ISproLoan
    function mint(address to) external onlyOwner returns (uint256 loanId_) {
        loanId_ = ++_lastLoanId;
        _mint(to, loanId_);
    }

    /// @inheritdoc ISproLoan
    function burn(uint256 loanId) external onlyOwner {
        _burn(loanId);
    }

    /// @inheritdoc ERC721
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory uri_) {
        _requireOwned(tokenId);
        ISproTypes.Loan memory loan = ISpro(owner()).getLoan(tokenId);
        return _nftRenderer.render(loan);
    }
}
