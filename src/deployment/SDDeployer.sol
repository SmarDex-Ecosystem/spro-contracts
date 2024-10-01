// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

/**
 * @title SD Deployer - forked from PWNDeployer.sol
 * @notice Contract that deploys other SD protocol contracts with `CREATE2` opcode, to have same addresses on different
 * chains.
 */
contract SDDeployer is Ownable {
    string internal constant VERSION = "1.0";

    /* ------------------------------------------------------------ */
    /*                          CONSTRUCTOR                         */
    /* ------------------------------------------------------------ */

    constructor(address _owner) Ownable(_owner) { }

    /* ------------------------------------------------------------ */
    /*                          DEPLOY FUNCTIONS                    */
    /* ------------------------------------------------------------ */

    /**
     * @notice Deploy new contract with salt.
     * @dev Set of salts is defined in {PWNContractDeployerSalt.sol}.
     *      Only deployer owner can call this function.
     * @param salt Salt used in `CREATE2` call.
     * @param bytecode Contracts create code encoded with constructor params.
     * @return Newly deployed contract address.
     */
    function deploy(bytes32 salt, bytes memory bytecode) external onlyOwner returns (address) {
        return Create2.deploy(0, salt, bytecode);
    }

    /**
     * @notice Deploy new contract with salt and transfer its ownership to the `owner`.
     * @dev Set of salts is defined in {PWNContractDeployerSalt.sol}.
     *      Only deployer owner can call this function.
     *      The newly deployed contract is expected to be `Ownable` to execute the `transferOwnership` function.
     * @param salt Salt used in `CREATE2` call.
     * @param owner Address to which the contract ownership is transferred after deployment.
     * @param bytecode Contracts create code encoded with constructor params.
     * @return deployedContract Newly deployed contract address.
     */
    function deployAndTransferOwnership(bytes32 salt, address owner, bytes memory bytecode)
        external
        onlyOwner
        returns (address deployedContract)
    {
        deployedContract = Create2.deploy(0, salt, bytecode);
        Ownable(deployedContract).transferOwnership(owner);
    }

    /**
     * @notice Compute address of a contract that would be deployed with given salt.
     * @param salt Salt used in `CREATE2` call.
     * @param bytecodeHash Hash of a contracts create code encoded with constructor params.
     * @return Computed contract address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) external view returns (address) {
        return Create2.computeAddress(salt, bytecodeHash);
    }
}
