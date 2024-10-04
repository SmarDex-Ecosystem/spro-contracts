// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {
    PWNRevokedNonce, SDConfig, SDSimpleLoan, SDSimpleLoanSimpleProposal
} from "spro/SDSimpleLoanSimpleProposal.sol";

contract SDSimpleLoanProposalHarness is SDSimpleLoanSimpleProposal {
    constructor(address _revokedNonce, address _config, string memory _name, string memory _version)
        SDSimpleLoanSimpleProposal(_revokedNonce, _config)
    { }
}

contract SDSimpleLoanProposalTest is Test {
    address public revokedNonce = makeAddr("revokedNonce");
    address public config = makeAddr("config");

    function test_constructor() external {
        string memory name = "name";
        string memory version = "version";
        SDSimpleLoanSimpleProposal s = new SDSimpleLoanProposalHarness(revokedNonce, config, name, version);
        bytes32 ds = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(abi.encodePacked(name)),
                keccak256(abi.encodePacked(version)),
                block.chainid,
                address(s)
            )
        );

        assertEq(address(s.revokedNonce()), revokedNonce);
        assertEq(address(s.config()), config);
        assertEq(s.DOMAIN_SEPARATOR(), ds);
    }
}
