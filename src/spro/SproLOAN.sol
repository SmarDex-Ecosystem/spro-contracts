// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IERC5646 } from "src/interfaces/IERC5646.sol";
import { IPWNLoanMetadataProvider } from "src/interfaces/IPWNLoanMetadataProvider.sol";

/**
 * @title Spro LOAN token
 * @notice A LOAN token representing a loan in Spro protocol.
 * @dev Token doesn't hold any loan logic, just an address of a loan contract that minted the LOAN token.
 *      Spro LOAN token is shared between all loan contracts.
 */
contract SproLOAN is ERC721, IERC5646, Ownable {
    /* ------------------------------------------------------------ */
    /*                VARIABLES & CONSTANTS DEFINITIONS             */
    /* ------------------------------------------------------------ */

    /// @dev Last used LOAN id. First LOAN id is 1. This value is incremental.
    uint256 public lastLoanId;

    /// @dev Mapping of a LOAN id to a loan contract that minted the LOAN token.
    mapping(uint256 => address) public loanContract;

    /* ------------------------------------------------------------ */
    /*                      EVENTS DEFINITIONS                      */
    /* ------------------------------------------------------------ */

    /**
     * @notice Emitted when a new LOAN token is minted.
     * @param loanId Id of a newly minted LOAN token.
     * @param loanContract Address of a loan contract that minted the LOAN token.
     * @param owner Address of a LOAN token receiver.
     */
    event LOANMinted(uint256 indexed loanId, address indexed loanContract, address indexed owner);

    /**
     * @notice Emitted when a LOAN token is burned.
     * @param loanId Id of a burned LOAN token.
     */
    event LOANBurned(uint256 indexed loanId);

    /* ------------------------------------------------------------ */
    /*                      ERRORS DEFINITIONS                      */
    /* ------------------------------------------------------------ */

    /// @notice Thrown when `SproLOAN.burn` caller is not a loan contract that minted the LOAN token.
    error InvalidLoanContractCaller();

    /* ------------------------------------------------------------ */
    /*                          CONSTRUCTOR                         */
    /* ------------------------------------------------------------ */

    /**
     * @notice Initialize SproLoan contract.
     * @param creator Address of the creator.
     */
    constructor(address creator) ERC721("Spro LOAN", "LOAN") Ownable(creator) { }

    /* ------------------------------------------------------------ */
    /*                       TOKEN LIFECYCLE                        */
    /* ------------------------------------------------------------ */

    /**
     * @notice Mint a new LOAN token.
     * @dev Only owner can mint a new LOAN token.
     * @param to Address of a LOAN token receiver.
     * @return loanId Id of a newly minted LOAN token.
     */
    function mint(address to) external onlyOwner returns (uint256 loanId) {
        loanId = ++lastLoanId;
        loanContract[loanId] = msg.sender;
        _mint(to, loanId);
        emit LOANMinted(loanId, msg.sender, to);
    }

    /**
     * @notice Burn a LOAN token.
     * @dev Any address that is associated with given loan id can call this function.
     *      It is enabled to let deprecated loan contracts repay and claim existing loans.
     * @param loanId Id of a LOAN token to be burned.
     */
    function burn(uint256 loanId) external {
        if (loanContract[loanId] != msg.sender) {
            revert InvalidLoanContractCaller();
        }

        delete loanContract[loanId];
        _burn(loanId);
        emit LOANBurned(loanId);
    }

    /* ------------------------------------------------------------ */
    /*                          METADATA                            */
    /* ------------------------------------------------------------ */

    /**
     * @notice Return a LOAN token metadata uri base on a loan contract that minted the token.
     * @param tokenId Id of a LOAN token.
     * @return Metadata uri for given token id (loan id).
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireOwned(tokenId);

        return IPWNLoanMetadataProvider(loanContract[tokenId]).loanMetadataUri();
    }

    /* ------------------------------------------------------------ */
    /*                          ERC5646                             */
    /* ------------------------------------------------------------ */

    /**
     * @dev See {IERC5646-getStateFingerprint}.
     */
    function getStateFingerprint(uint256 tokenId) external view virtual override returns (bytes32) {
        address _loanContract = loanContract[tokenId];

        if (_loanContract == address(0)) return bytes32(0);

        return IERC5646(_loanContract).getStateFingerprint(tokenId);
    }

    /* ------------------------------------------------------------ */
    /*                          ERC165                              */
    /* ------------------------------------------------------------ */

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || interfaceId == type(IERC5646).interfaceId;
    }
}
