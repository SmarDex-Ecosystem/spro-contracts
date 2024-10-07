// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import { PWNLOAN } from "spro/PWNLOAN.sol";
import { PWNRevokedNonce } from "spro/PWNRevokedNonce.sol";
import { ISproErrors } from "src/interfaces/ISproErrors.sol";
import { ISproEvents } from "src/interfaces/ISproEvents.sol";
import { SproConstantsLibrary as Constants } from "src/libraries/SproConstantsLibrary.sol";

contract SproStorage is ISproErrors, ISproEvents {
    /* -------------------------------------------------------------------------- */
    /*                                   CONFIG                                   */
    /* -------------------------------------------------------------------------- */

    /// @notice SDEX token address.
    address public immutable SDEX;

    /// @notice Percentage of a proposal's availableCreditLimit which can be used in partial lending.
    uint16 public partialPositionPercentage;

    /**
     * @notice Protocol fixed fee for unlisted credit tokens.
     * @dev Amount of SDEX tokens (units 1e18).
     */
    uint256 public fixFeeUnlisted;

    /**
     * @notice Protocol fixed fee for listed credit tokens.
     * @dev Amount of SDEX tokens (units 1e18).
     */
    uint256 public fixFeeListed;

    /**
     * @notice Variable factor for calculating variable fee component for listed credit tokens.
     * @dev Units 1e18. Eg. factor of 40_000 == 4e22
     */
    uint256 public variableFactor;

    /// @notice Mapping holding token factor to a listed credit token.
    mapping(address => uint256) public tokenFactors;

    /**
     * @notice Mapping of a loan contract address to LOAN token metadata uri.
     * @dev LOAN token minted by a loan contract will return metadata uri stored in this mapping.
     *      If there is no metadata uri for a loan contract, default metadata uri will be used stored under address(0).
     */
    mapping(address => string) public _loanMetadataUri;

    /// @notice Mapping holding registered state fingerprint computer to an asset.
    mapping(address => address) public _sfComputerRegistry;

    /// @notice Mapping holding registered pool adapter to a pool address.
    mapping(address => address) public _poolAdapterRegistry;

    PWNRevokedNonce public immutable revokedNonce;

    /* -------------------------------------------------------------------------- */
    /*                                    LOAN                                    */
    /* -------------------------------------------------------------------------- */

    bytes32 public immutable DOMAIN_SEPARATOR_LOAN = keccak256(
        abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256("SDSimpleLoan"),
            keccak256(abi.encodePacked(Constants.VERSION)),
            block.chainid,
            address(this)
        )
    );

    PWNLOAN public immutable loanToken;

    /// @notice  Mapping of all LOAN data by loan id.
    mapping(uint256 => LOAN) internal LOANs;

    /* -------------------------------------------------------------------------- */
    /*                                  PROPOSAL                                  */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev Mapping of proposals to the borrower's withdrawable collateral tokens
     *      (proposal hash => amount of collateral tokens)
     */
    mapping(bytes32 => uint256) public withdrawableCollateral;

    bytes32 public immutable DOMAIN_SEPARATOR_PROPOSAL = keccak256(
        abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(abi.encodePacked("SDSimpleLoanSimpleProposal")),
            keccak256(abi.encodePacked(Constants.VERSION)),
            block.chainid,
            address(this)
        )
    );

    /**
     * @dev Mapping of proposals made via on-chain transactions.
     *      (proposal hash => is made)
     */
    mapping(bytes32 => bool) public proposalsMade;

    /**
     * @dev Mapping of credit used by a proposal with defined available credit limit.
     *      (proposal hash => credit used)
     */
    mapping(bytes32 => uint256) public creditUsed;
}
