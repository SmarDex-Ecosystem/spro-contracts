// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import {console2} from "forge-std/src/Script.sol";
import {ScriptUtils} from "./lib/ScriptUtils.sol";

import {
    TransparentUpgradeableProxy,
    ITransparentUpgradeableProxy
} from "openzeppelin/proxy/transparent/TransparentUpgradeableProxy.sol";
import {
    SDDeployments,
    SDConfig,
    IPWNDeployer,
    PWNHub,
    PWNHubTags,
    SDSimpleLoan,
    SDSimpleLoanSimpleProposal,
    PWNLOAN,
    PWNRevokedNonce,
    MultiTokenCategoryRegistry
} from "pwn/SDDeployments.sol";
import "openzeppelin/utils/Create2.sol";

library SDContractDeployerParams {
    string internal constant VERSION = "1.0";

    /*//////////////////////////////////////////////////////////////////////////
                                     SALT
    //////////////////////////////////////////////////////////////////////////*/

    // Singletons
    bytes32 internal constant CONFIG = keccak256("SDConfig");
    bytes32 internal constant CONFIG_PROXY = keccak256("SDConfigProxy");
    bytes32 internal constant HUB = keccak256("SDHub");
    bytes32 internal constant LOAN = keccak256("SDLOAN");
    bytes32 internal constant REVOKED_NONCE = keccak256("SDRevokedNonce");

    // Loan types
    bytes32 internal constant SIMPLE_LOAN = keccak256("SDSimpleLoan");

    // Proposal types
    bytes32 internal constant SIMPLE_LOAN_SIMPLE_PROPOSAL = keccak256("SDSimpleLoanSimpleProposal");

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR ARGS
    //////////////////////////////////////////////////////////////////////////*/

    // SDConfig @note arbitrarily set here, please change.
    uint256 internal constant UNLISTED_FEE = 50e18;
    uint256 internal constant LISTED_FEE = 30e18;
    uint256 internal constant VARIABLE_FACTOR = 1e16;
    uint16 internal constant PARTIAL_POSITION_PERCENTAGE = 500;
}

contract Deploy is ScriptUtils, SDDeployments {
    function _protocolNotDeployedOnSelectedChain() internal pure override {
        revert("SD: selected chain is not set in deployments/sdlatest.json");
    }

    function _deployAndTransferOwnership(bytes32 salt, address owner, bytes memory bytecode)
        internal
        returns (address)
    {
        return deployment.deployer.deployAndTransferOwnership(salt, owner, bytecode);
    }

    function _deploy(bytes32 salt, bytes memory bytecode) internal returns (address) {
        return deployment.deployer.deploy(salt, bytecode);
    }

    /*
      forge script script/SD.s.sol:Deploy \
      --sig "deployProtocol()" \
      --rpc-url $RPC_URL \
      --private-key $PRIVATE_KEY \
      --with-gas-price $(cast --to-wei 15 gwei) \
      --verify --etherscan-api-key $ETHERSCAN_API_KEY \
      --broadcast
    */

    // Local:
    // forge script script/SD.s.sol:Deploy --sig "deployProtocol()" --rpc-url $LOCAL_URL --private-key $PRIVATE_KEY --broadcast

    /// @dev Expecting to have deployer, proxyAdmin, protocolAdmin and sdex
    /// addresses set in the `deployments/sdlatest.json`.
    function deployProtocol() external {
        _loadDeployedAddresses();

        require(address(deployment.deployer) != address(0), "Deployer not set");
        require(deployment.proxyAdmin != address(0), "ProxyAdmin not set");
        require(deployment.protocolAdmin != address(0), "Protocol admin not set");
        require(address(deployment.sdex) != address(0), "SDEX not set");

        uint256 pk = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast();
        // Deploy protocol

        // - Config

        // Note: To have the same config proxy address on new chains independently of the config implementation,
        // the config proxy is deployed first with Deployer implementation that has the same address on all chains.
        // Proxy implementation is then upgraded to the correct one in the next transaction.

        deployment.config = SDConfig(
            _deploy({
                salt: SDContractDeployerParams.CONFIG_PROXY,
                bytecode: abi.encodePacked(
                    type(TransparentUpgradeableProxy).creationCode, abi.encode(deployment.deployer, vm.addr(pk), "")
                )
            })
        );
        address configSingleton = _deploy({
            salt: SDContractDeployerParams.CONFIG,
            bytecode: abi.encodePacked(type(SDConfig).creationCode, abi.encode(deployment.sdex))
        });
        vm.stopBroadcast();

        vm.startBroadcast(pk);
        ITransparentUpgradeableProxy(address(deployment.config)).upgradeToAndCall(
            configSingleton,
            abi.encodeWithSelector(
                SDConfig.initialize.selector,
                deployment.protocolAdmin,
                SDContractDeployerParams.UNLISTED_FEE,
                SDContractDeployerParams.LISTED_FEE,
                SDContractDeployerParams.VARIABLE_FACTOR,
                SDContractDeployerParams.PARTIAL_POSITION_PERCENTAGE
            )
        );
        ITransparentUpgradeableProxy(address(deployment.config)).changeAdmin(deployment.proxyAdmin);
        vm.stopBroadcast();

        vm.startBroadcast();
        // - MultiToken category registry
        deployment.categoryRegistry = MultiTokenCategoryRegistry(
            _deployAndTransferOwnership({ // Need ownership acceptance from the new owner
                salt: SDContractDeployerParams.CONFIG,
                owner: deployment.protocolAdmin,
                bytecode: type(MultiTokenCategoryRegistry).creationCode
            })
        );

        // - Hub
        deployment.hub = PWNHub(
            _deployAndTransferOwnership({ // Need ownership acceptance from the new owner
                salt: SDContractDeployerParams.HUB,
                owner: deployment.protocolAdmin,
                bytecode: type(PWNHub).creationCode
            })
        );

        // - LOAN token
        deployment.loanToken = PWNLOAN(
            _deploy({
                salt: SDContractDeployerParams.LOAN,
                bytecode: abi.encodePacked(type(PWNLOAN).creationCode, abi.encode(address(deployment.hub)))
            })
        );

        // - Revoked nonces
        deployment.revokedNonce = PWNRevokedNonce(
            _deploy({
                salt: SDContractDeployerParams.REVOKED_NONCE,
                bytecode: abi.encodePacked(
                    type(PWNRevokedNonce).creationCode, abi.encode(address(deployment.hub), PWNHubTags.NONCE_MANAGER)
                )
            })
        );

        // - Loan types
        deployment.simpleLoan = SDSimpleLoan(
            _deploy({
                salt: SDContractDeployerParams.SIMPLE_LOAN,
                bytecode: abi.encodePacked(
                    type(SDSimpleLoan).creationCode,
                    abi.encode(
                        address(deployment.hub),
                        address(deployment.loanToken),
                        address(deployment.config),
                        address(deployment.revokedNonce),
                        address(deployment.categoryRegistry)
                    )
                )
            })
        );

        // - Proposals
        deployment.simpleLoanSimpleProposal = SDSimpleLoanSimpleProposal(
            _deploy({
                salt: SDContractDeployerParams.SIMPLE_LOAN_SIMPLE_PROPOSAL,
                bytecode: abi.encodePacked(
                    type(SDSimpleLoanSimpleProposal).creationCode,
                    abi.encode(address(deployment.hub), address(deployment.revokedNonce), address(deployment.config))
                )
            })
        );

        vm.stopBroadcast();

        console2.log("Deployer:", address(deployment.deployer));
        console2.log("ProxyAdmin:", deployment.proxyAdmin);
        console2.log("ProtocolAdmin:", deployment.protocolAdmin);
        console2.log("SDEX:", address(deployment.sdex));
        console2.log("MultiToken Category Registry:", address(deployment.categoryRegistry));
        console2.log("SDConfig - singleton:", configSingleton);
        console2.log("SDConfig - proxy:", address(deployment.config));
        console2.log("PWNHub:", address(deployment.hub));
        console2.log("PWNLOAN:", address(deployment.loanToken));
        console2.log("PWNRevokedNonce:", address(deployment.revokedNonce));
        console2.log("SDSimpleLoan:", address(deployment.simpleLoan));
        console2.log("SDSimpleLoanSimpleProposal:", address(deployment.simpleLoanSimpleProposal));

        // Writes deployment addresses to deployments JSON - @note currently points to sdLatest.json
        _writeDeploymentAddress(address(deployment.categoryRegistry), ".categoryRegistry");
        _writeDeploymentAddress(configSingleton, ".configSingleton");
        _writeDeploymentAddress(address(deployment.config), ".config");
        _writeDeploymentAddress(address(deployment.hub), ".hub");
        _writeDeploymentAddress(address(deployment.loanToken), ".loanToken");
        _writeDeploymentAddress(address(deployment.revokedNonce), ".revokedNonce");
        _writeDeploymentAddress(address(deployment.simpleLoan), ".simpleLoan");
        _writeDeploymentAddress(address(deployment.simpleLoanSimpleProposal), ".simpleLoanSimpleProposal");
    }
}
