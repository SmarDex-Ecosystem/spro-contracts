// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";

import { Spro } from "spro/Spro.sol";
import { ISproTypes } from "src/interfaces/ISproTypes.sol";
import { ISproErrors } from "src/interfaces/ISproErrors.sol";

contract SproHarness is Spro {
    constructor(
        address _sdex,
        address _revokedNonce,
        address _stateFingerprintComputer,
        uint16 _defaultThreshold,
        uint16 _percentage,
        uint16 _partialPositionPercentage,
        uint16 _variableFactor
    )
        Spro(
            _sdex,
            _revokedNonce,
            _stateFingerprintComputer,
            _defaultThreshold,
            _percentage,
            _partialPositionPercentage,
            _variableFactor
        )
    { }

    function exposed_checkCompleteLoan(uint256 _creditAmount, uint256 _availableCreditLimit) external pure {
        _checkCompleteLoan(_creditAmount, _availableCreditLimit);
    }
}

contract SDSimpleLoanSimpleProposalTest is Test {
    address public sdex = makeAddr("sdex");
    address public loanToken = makeAddr("loanToken");
    address public revokedNonce = makeAddr("revokedNonce");

    SproHarness harness;

    function setUp() public {
        harness = new SproHarness(sdex, revokedNonce, address(this), 1, 1, 1, 1);
    }

    function testFuzz_encodeProposalData(address addr) external view {
        Spro.Proposal memory proposal = ISproTypes.Proposal({
            collateralAddress: addr,
            collateralAmount: 1e20,
            checkCollateralStateFingerprint: false,
            collateralStateFingerprint: bytes32(0),
            creditAddress: addr,
            availableCreditLimit: 20e22,
            fixedInterestAmount: 1e14,
            accruingInterestAPR: 0,
            startTimestamp: uint40(block.timestamp),
            defaultTimestamp: uint40(block.timestamp) + 5 days,
            proposer: addr,
            proposerSpecHash: keccak256(abi.encode(addr)),
            nonceSpace: 0,
            nonce: 0,
            loanContract: addr
        });
        bytes memory x = abi.encode(proposal);
        assertEq(harness.encodeProposalData(proposal), x);
    }

    function testFuzz_shouldFail_partialLoan(uint256 a, uint256 l) external {
        vm.assume(a != l);

        vm.expectRevert(abi.encodeWithSelector(ISproErrors.OnlyCompleteLendingForNFTs.selector, a, l));
        harness.exposed_checkCompleteLoan(a, l);
    }
}
