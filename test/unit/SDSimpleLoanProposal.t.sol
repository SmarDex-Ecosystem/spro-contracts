// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import {Test} from "forge-std/src/Test.sol";
import {MultiToken} from "MultiToken/MultiToken.sol";
import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";

import {
    PWNHub,
    PWNRevokedNonce,
    SDConfig,
    SDSimpleLoan,
    SDSimpleLoanProposal
} from "pwn/loan/terms/simple/proposal/SDSimpleLoanProposal.sol";

contract SDSimpleLoanProposalHarness is SDSimpleLoanProposal {
    constructor(address _hub, address _revokedNonce, address _config, string memory _name, string memory _version)
        SDSimpleLoanProposal(_hub, _revokedNonce, _config, _name, _version)
    {}

    function acceptProposal(address acceptor, uint256 creditAmount, bytes calldata proposalData)
        external
        override
        returns (bytes32 proposalHash, SDSimpleLoan.Terms memory loanTerms)
    {}

    function makeProposal(bytes calldata proposalData)
        external
        override
        returns (address proposer, MultiToken.Asset memory collateral, address creditAddress, uint256 creditLimit)
    {}

    function cancelProposal(bytes calldata proposalData)
        external
        override
        returns (address proposer, MultiToken.Asset memory collateral)
    {}
}

contract SDSimpleLoanProposalTest is Test {
    address public hub = makeAddr("hub");
    address public revokedNonce = makeAddr("revokedNonce");
    address public config = makeAddr("config");

    function test_constructor() external {
        string memory name = "name";
        string memory version = "version";
        SDSimpleLoanProposal s = new SDSimpleLoanProposalHarness(hub, revokedNonce, config, name, version);
        bytes32 ds = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(abi.encodePacked(name)),
                keccak256(abi.encodePacked(version)),
                block.chainid,
                address(s)
            )
        );

        assertEq(address(s.hub()), hub);
        assertEq(address(s.revokedNonce()), revokedNonce);
        assertEq(address(s.config()), config);
        assertEq(s.DOMAIN_SEPARATOR(), ds);
    }
}
