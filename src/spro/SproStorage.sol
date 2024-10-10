// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { SproLOAN } from "src/spro/SproLOAN.sol";
import { SproRevokedNonce } from "src/spro/SproRevokedNonce.sol";
import { ISproStorage } from "src/interfaces/ISproStorage.sol";
import { SproConstantsLibrary as Constants } from "src/libraries/SproConstantsLibrary.sol";
import { ISproTypes } from "src/interfaces/ISproTypes.sol";

contract SproStorage is ISproStorage {
    /* -------------------------------------------------------------------------- */
    /*                                   CONFIG                                   */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ISproStorage
    address public immutable SDEX;

    /// @inheritdoc ISproStorage
    SproRevokedNonce public immutable revokedNonce;

    /// @inheritdoc ISproStorage
    uint16 public partialPositionPercentage;

    /// @inheritdoc ISproStorage
    uint256 public fixFeeUnlisted;

    /// @inheritdoc ISproStorage
    uint256 public fixFeeListed;

    /// @inheritdoc ISproStorage
    uint256 public variableFactor;

    /// @inheritdoc ISproStorage
    mapping(address => uint256) public tokenFactors;

    /// @inheritdoc ISproStorage
    mapping(address => string) public _loanMetadataUri;

    /// @inheritdoc ISproStorage
    mapping(address => address) public _poolAdapterRegistry;

    /* -------------------------------------------------------------------------- */
    /*                                    LOAN                                    */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ISproStorage
    bytes32 public immutable DOMAIN_SEPARATOR_LOAN = keccak256(
        abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256("SDSimpleLoan"),
            keccak256(abi.encodePacked(Constants.VERSION)),
            block.chainid,
            address(this)
        )
    );

    /// @inheritdoc ISproStorage
    SproLOAN public immutable loanToken;

    /// @notice  Mapping of all LOAN data by loan id.
    mapping(uint256 => ISproTypes.LOAN) internal LOANs;

    /* -------------------------------------------------------------------------- */
    /*                                  PROPOSAL                                  */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ISproStorage
    bytes32 public immutable DOMAIN_SEPARATOR_PROPOSAL = keccak256(
        abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(abi.encodePacked("SDSimpleLoanSimpleProposal")),
            keccak256(abi.encodePacked(Constants.VERSION)),
            block.chainid,
            address(this)
        )
    );

    /// @inheritdoc ISproStorage
    mapping(bytes32 => uint256) public withdrawableCollateral;

    /// @inheritdoc ISproStorage
    mapping(bytes32 => bool) public proposalsMade;

    /// @inheritdoc ISproStorage
    mapping(bytes32 => uint256) public creditUsed;
}
