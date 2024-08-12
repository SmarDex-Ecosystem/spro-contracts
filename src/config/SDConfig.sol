// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import {Ownable2Step} from "openzeppelin/access/Ownable2Step.sol";
import {Initializable} from "openzeppelin/proxy/utils/Initializable.sol";

import {IPoolAdapter} from "pwn/interfaces/IPoolAdapter.sol";
import {IStateFingerprintComputer} from "pwn/interfaces/IStateFingerprintComputer.sol";

/**
 * @title PWN Config
 * @notice Contract holding configurable values of PWN protocol.
 * @dev Is intended to be used as a proxy via `TransparentUpgradeableProxy`.
 */
contract SDConfig is Ownable2Step, Initializable {
    string internal constant VERSION = "1.0";

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    /**
     * @notice SDEX token address.
     */
    address public sdex;

    /**
     * @notice Fee sink address.
     */
    address public sink;

    /**
     * @notice Protocol fixed fee for unlisted credit tokens.
     * @dev Amount of SDEX tokens (units 1e18).
     */
    uint256 public unlistedFee;

    /**
     * @notice Protocol fixed fee for listed credit tokens.
     * @dev Amount of SDEX tokens (units 1e18).
     */
    uint256 public listedFee;

    /**
     * @notice Variable factor for calculating variable fee component for listed credit tokens.
     * @dev Units 1e18. Eg. factor of 40_000 == 4e22
     */
    uint256 public variableFactor;

    /**
     * @notice Mapping holding token factor to a listed credit token.
     */
    mapping(address => uint256) public tokenFactors;

    /**
     * @notice Mapping of a loan contract address to LOAN token metadata uri.
     * @dev LOAN token minted by a loan contract will return metadata uri stored in this mapping.
     *      If there is no metadata uri for a loan contract, default metadata uri will be used stored under address(0).
     */
    mapping(address => string) private _loanMetadataUri;

    /**
     * @notice Mapping holding registered state fingerprint computer to an asset.
     */
    mapping(address => address) private _sfComputerRegistry;

    /**
     * @notice Mapping holding registered pool adapter to a pool address.
     */
    mapping(address => address) private _poolAdapterRegistry;

    /*----------------------------------------------------------*|
    |*  # EVENTS DEFINITIONS                                    *|
    |*----------------------------------------------------------*/

    /**
     * @notice Emitted when new listed fee is set.
     */
    event ListedFeeUpdated(uint256 oldFee, uint256 newFee);

    /**
     * @notice Emitted when new unlisted fee is set.
     */
    event UnlistedFeeUpdated(uint256 oldFee, uint256 newFee);

    /**
     * @notice Emitted when new variable factor is set.
     */
    event VariableFactorUpdated(uint256 oldFactor, uint256 newFactor);

    /**
     * @notice Emitted when the sdex token address is set.
     */
    event SDEXInitialized(address sdex);

    /**
     * @notice Emitted when the fee sink address is set.
     */
    event SinkInitialized(address sink);

    /**
     * @notice Emitted when a listed token factor is set.
     */
    event ListedTokenUpdated(address token, uint256 factor);

    /**
     * @notice Emitted when new LOAN token metadata uri is set.
     */
    event LOANMetadataUriUpdated(address indexed loanContract, string newUri);

    /**
     * @notice Emitted when new default LOAN token metadata uri is set.
     */
    event DefaultLOANMetadataUriUpdated(string newUri);

    /*----------------------------------------------------------*|
    |*  # ERRORS DEFINITIONS                                    *|
    |*----------------------------------------------------------*/

    /**
     * @notice Thrown when registering a computer which does not support the asset it is registered for.
     */
    error InvalidComputerContract(address computer, address asset);

    /**
     * @notice Thrown when trying to set a fee value higher than `MAX_FEE`.
     */
    error InvalidFeeValue(uint256 fee, uint256 limit);

    /**
     * @notice Thrown when trying to set the sink or sdex token as the zero address.
     */
    error ZeroAddress();

    /**
     * @notice Thrown when trying to set a LOAN token metadata uri for zero address loan contract.
     */
    error ZeroLoanContract();

    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR                                           *|
    |*----------------------------------------------------------*/

    constructor() Ownable2Step() {
        // PWNConfig is used as a proxy. Use initializer to setup initial properties.
        _disableInitializers();
        _transferOwnership(address(0));
    }

    function initialize(
        address _owner,
        address _sdex,
        address _sink,
        uint256 _unlistedFee,
        uint256 _listedFee,
        uint256 _variableFactor
    ) external initializer {
        require(_owner != address(0), "Owner is zero address");
        _transferOwnership(_owner);
        _setSDEX(_sdex);
        _setSink(_sink);
        _setUnlistedFee(_unlistedFee);
        _setListedFee(_listedFee);
        _setVariableFactor(_variableFactor);
    }

    /*----------------------------------------------------------*|
    |*  # FEE MANAGEMENT                                        *|
    |*----------------------------------------------------------*/

    /**
     * @notice Set new protocol listed fee value.
     * @param fee New listed fee value in amount SDEX tokens (units 1e18)
     */
    function setListedFee(uint256 fee) external onlyOwner {
        _setListedFee(fee);
    }

    /**
     * @notice Set new protocol unlisted fee value.
     * @param fee New unlisted fee value in amount SDEX tokens (units 1e18)
     */
    function setUnlistedFee(uint256 fee) external onlyOwner {
        _setUnlistedFee(fee);
    }

    /**
     * @notice Set new protocol variable factor
     * @param factor New variable factor value (units 1e18)
     */
    function setVariableFactor(uint256 factor) external onlyOwner {
        _setVariableFactor(factor);
    }

    /**
     * @notice Set new protocol token factor for credit asset
     * @param token Credit token address.
     * @param factor New token factor value (units 1e18)
     * @dev Token is unlisted for `factor == 0` and listed for `factor != 0`.
     */
    function setListedToken(address token, uint256 factor) external onlyOwner {
        _setListedToken(token, factor);
    }

    /**
     * @notice Internal implementation to set new protocol listed fee value.
     * @param _fee New listed fee value in amount SDEX tokens (units 1e18)
     */
    function _setListedFee(uint256 _fee) private {
        emit ListedFeeUpdated(listedFee, _fee);
        listedFee = _fee;
    }

    /**
     * @notice Internal implementation to set new protocol unlisted fee value.
     * @param _fee New unlisted fee value in amount SDEX tokens (units 1e18)
     */
    function _setUnlistedFee(uint256 _fee) private {
        emit UnlistedFeeUpdated(unlistedFee, _fee);
        unlistedFee = _fee;
    }

    /**
     * @notice Internal implementation to set new protocol variable factor
     * @param _factor New variable factor value (units 1e18)
     */
    function _setVariableFactor(uint256 _factor) private {
        emit VariableFactorUpdated(variableFactor, _factor);
        variableFactor = _factor;
    }

    /**
     * @notice Set SDEX token address
     * @param _sdex SDEX token address
     */
    function _setSDEX(address _sdex) private {
        if (_sdex == address(0)) revert ZeroAddress();
        sdex = _sdex;
        emit SDEXInitialized(_sdex);
    }

    /**
     * @notice Set fee sink address
     * @param _sink Fee sink address
     */
    function _setSink(address _sink) private {
        if (_sink == address(0)) revert ZeroAddress();
        sink = _sink;
        emit SinkInitialized(_sink);
    }

    /**
     * @notice Internal implementation to set new protocol token factor for credit asset
     * @param _token Credit token address.
     * @param _factor New token factor value (units 1e18)
     */
    function _setListedToken(address _token, uint256 _factor) private {
        tokenFactors[_token] = _factor;
        emit ListedTokenUpdated(_token, _factor);
    }

    /*----------------------------------------------------------*|
    |*  # LOAN METADATA                                         *|
    |*----------------------------------------------------------*/

    /**
     * @notice Set a LOAN token metadata uri for a specific loan contract.
     * @param loanContract Address of a loan contract.
     * @param metadataUri New value of LOAN token metadata uri for given `loanContract`.
     */
    function setLOANMetadataUri(address loanContract, string memory metadataUri) external onlyOwner {
        if (loanContract == address(0)) {
            // address(0) is used as a default metadata uri. Use `setDefaultLOANMetadataUri` to set default metadata uri.
            revert ZeroLoanContract();
        }

        _loanMetadataUri[loanContract] = metadataUri;
        emit LOANMetadataUriUpdated(loanContract, metadataUri);
    }

    /**
     * @notice Set a default LOAN token metadata uri.
     * @param metadataUri New value of default LOAN token metadata uri.
     */
    function setDefaultLOANMetadataUri(string memory metadataUri) external onlyOwner {
        _loanMetadataUri[address(0)] = metadataUri;
        emit DefaultLOANMetadataUriUpdated(metadataUri);
    }

    /**
     * @notice Return a LOAN token metadata uri base on a loan contract that minted the token.
     * @param loanContract Address of a loan contract.
     * @return uri Metadata uri for given loan contract.
     */
    function loanMetadataUri(address loanContract) external view returns (string memory uri) {
        uri = _loanMetadataUri[loanContract];
        // If there is no metadata uri for a loan contract, use default metadata uri.
        if (bytes(uri).length == 0) uri = _loanMetadataUri[address(0)];
    }

    /*----------------------------------------------------------*|
    |*  # STATE FINGERPRINT COMPUTER                            *|
    |*----------------------------------------------------------*/

    /**
     * @notice Returns the state fingerprint computer for a given asset.
     * @param asset The asset for which the computer is requested.
     * @return The computer for the given asset.
     */
    function getStateFingerprintComputer(address asset) external view returns (IStateFingerprintComputer) {
        return IStateFingerprintComputer(_sfComputerRegistry[asset]);
    }

    /**
     * @notice Registers a state fingerprint computer for a given asset.
     * @param asset The asset for which the computer is registered.
     * @param computer The computer to be registered. Use address(0) to remove a computer.
     */
    function registerStateFingerprintComputer(address asset, address computer) external onlyOwner {
        if (computer != address(0)) {
            if (!IStateFingerprintComputer(computer).supportsToken(asset)) {
                revert InvalidComputerContract({computer: computer, asset: asset});
            }
        }

        _sfComputerRegistry[asset] = computer;
    }

    /*----------------------------------------------------------*|
    |*  # POOL ADAPTER                                          *|
    |*----------------------------------------------------------*/

    /**
     * @notice Returns the pool adapter for a given pool.
     * @param pool The pool for which the adapter is requested.
     * @return The adapter for the given pool.
     */
    function getPoolAdapter(address pool) external view returns (IPoolAdapter) {
        return IPoolAdapter(_poolAdapterRegistry[pool]);
    }

    /**
     * @notice Registers a pool adapter for a given pool.
     * @param pool The pool for which the adapter is registered.
     * @param adapter The adapter to be registered.
     */
    function registerPoolAdapter(address pool, address adapter) external onlyOwner {
        _poolAdapterRegistry[pool] = adapter;
    }
}
