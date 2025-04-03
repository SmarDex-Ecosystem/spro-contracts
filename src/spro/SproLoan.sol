// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";

import { ISproLoan } from "src/interfaces/ISproLoan.sol";
import { ISpro } from "src/interfaces/ISpro.sol";
import { NFTRenderer } from "src/spro/libraries/NFTRenderer.sol";
import { ISproTypes } from "src/interfaces/ISproTypes.sol";

contract SproLoan is ISproLoan, ERC721, Ownable {
    /// @inheritdoc ISproLoan
    uint256 public _lastLoanId;

    /// @inheritdoc ISproLoan
    string public _metadataUri;

    /// @param deployer The deployer address.
    constructor(address deployer) ERC721("Spro Loan", "LOAN") Ownable(deployer) { }

    /// @inheritdoc ISproLoan
    function mint(address to) external onlyOwner returns (uint256 loanId_) {
        loanId_ = ++_lastLoanId;
        _mint(to, loanId_);
        emit LoanMinted(loanId_, to);
    }

    /// @inheritdoc ISproLoan
    function burn(uint256 loanId) external onlyOwner {
        _burn(loanId);
        emit LoanBurned(loanId);
    }

    /// @inheritdoc ERC721
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory uri_) {
        _requireOwned(tokenId);
        ISproTypes.Loan memory loan = ISpro(owner()).getLoan(tokenId);
        return NFTRenderer.render(loan);
    }

    /// @inheritdoc ISproLoan
    function setLoanMetadataUri(string memory newMetadataUri) external onlyOwner {
        _metadataUri = newMetadataUri;
        emit LoanMetadataUriUpdated(newMetadataUri);
        emit IERC4906.BatchMetadataUpdate(0, type(uint256).max);
    }
}
