// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import {Test} from "forge-std/src/Test.sol";

import {
    SDSimpleLoan,
    PWNHubTags,
    InvalidPermitOwner,
    InvalidPermitAsset,
    Math,
    MultiToken,
    Permit,
    PWNRevokedNonce,
    IPoolAdapter
} from "pwn/loan/terms/simple/loan/SDSimpleLoan.sol";

import {T20} from "test/helper/T20.sol";
import {T721} from "test/helper/T721.sol";
import {DummyPoolAdapter} from "test/helper/DummyPoolAdapter.sol";

contract SDSimpleLoanHarness is SDSimpleLoan {
    constructor(address _h, address _lt, address _c, address _rn, address _cr) SDSimpleLoan(_h, _lt, _c, _rn, _cr) {}

    function exposed_checkPermit(address caller, address creditAddress, Permit memory permit) external pure {
        _checkPermit(caller, creditAddress, permit);
    }

    function exposed_checkLoanCanBeRepaid(uint8 status, uint40 defaultTimestamp) external view {
        _checkLoanCanBeRepaid(status, defaultTimestamp);
    }

    function exposed_checkLoanCreditAddress(address loanCreditAddress, address expectedCreditAddress) external pure {
        _checkLoanCreditAddress(loanCreditAddress, expectedCreditAddress);
    }

    function exposed_withdrawCreditFromPool(
        MultiToken.Asset memory credit,
        Terms memory loanTerms,
        LenderSpec calldata lenderSpec
    ) external {
        _withdrawCreditFromPool(credit, loanTerms, lenderSpec);
    }
}

contract SDSimpleLoanTest is Test {
    address public hub = makeAddr("hub");
    address public loanToken = makeAddr("loanToken");
    address public config = makeAddr("config");
    address public revokedNonce = makeAddr("revokedNonce");
    address public categoryRegistry = makeAddr("categoryRegistry");

    address public permitAsset = makeAddr("permitAsset");
    address public credit = makeAddr("credit");

    address poolAdapter = address(new DummyPoolAdapter());

    SDSimpleLoanHarness simpleLoan;

    function setUp() public {
        vm.etch(config, bytes("data"));
        simpleLoan = new SDSimpleLoanHarness(hub, loanToken, config, revokedNonce, categoryRegistry);

        vm.mockCall(config, abi.encodeWithSignature("getPoolAdapter(address)"), abi.encode(poolAdapter));
    }

    function test_constructor() external view {
        assertEq(address(simpleLoan.hub()), hub);
        assertEq(address(simpleLoan.loanToken()), loanToken);
        assertEq(address(simpleLoan.config()), config);
        assertEq(address(simpleLoan.revokedNonce()), revokedNonce);
        assertEq(address(simpleLoan.categoryRegistry()), categoryRegistry);
    }

    function testFuzz_getLenderSpecHash(address source, uint256 amount, bytes memory data) external view {
        SDSimpleLoan.LenderSpec memory ls =
            SDSimpleLoan.LenderSpec({sourceOfFunds: source, creditAmount: amount, permitData: data});
        bytes32 lenderSpecHash = keccak256(abi.encode(ls));

        assertEq(simpleLoan.getLenderSpecHash(ls), lenderSpecHash);
    }

    function test_shouldFail_checkPermit_whenInvalidPermitOwner() external {
        Permit memory permit;
        permit.asset = permitAsset;

        vm.expectRevert(abi.encodeWithSelector(InvalidPermitOwner.selector, permit.owner, address(this)));
        simpleLoan.exposed_checkPermit(address(this), credit, permit);
    }

    function test_shouldFail_checkPermit_whenInvalidPermitAsset() external {
        Permit memory permit;
        permit.asset = permitAsset;
        permit.owner = address(this);

        vm.expectRevert(abi.encodeWithSelector(InvalidPermitAsset.selector, permit.asset, address(this)));
        simpleLoan.exposed_checkPermit({caller: address(this), creditAddress: address(this), permit: permit});
    }

    function testFuzz_shouldFail_withdrawCreditFromPool_InvalidSourceOfFunds(
        address source,
        uint256 amount,
        bytes memory data
    ) external {
        MultiToken.Asset memory credit_;
        SDSimpleLoan.Terms memory loanTerms;
        SDSimpleLoan.LenderSpec memory lenderSpec =
            SDSimpleLoan.LenderSpec({sourceOfFunds: source, creditAmount: amount, permitData: data});

        vm.mockCall(config, abi.encodeWithSignature("getPoolAdapter(address)"), abi.encode(address(0)));

        vm.expectRevert(abi.encodeWithSelector(SDSimpleLoan.InvalidSourceOfFunds.selector, lenderSpec.sourceOfFunds));
        simpleLoan.exposed_withdrawCreditFromPool(credit_, loanTerms, lenderSpec);
    }

    function test_loanRepaymentAmount_shouldReturnZeroForNonExistingLoan() external view {
        uint256 amount = simpleLoan.loanRepaymentAmount(0);

        assertEq(amount, 0);
    }

    function test_shouldFail_checkLoanCanBeRepaid_NonExistingLoan() external {
        vm.expectRevert(SDSimpleLoan.NonExistingLoan.selector);
        simpleLoan.exposed_checkLoanCanBeRepaid(0, 0);

        vm.expectRevert(SDSimpleLoan.LoanNotRunning.selector);
        simpleLoan.exposed_checkLoanCanBeRepaid(1, 0);
    }

    function test_shouldFail_checkLoanCanBeRepaid_LoanNotRunning() external {
        vm.expectRevert(SDSimpleLoan.LoanNotRunning.selector);
        simpleLoan.exposed_checkLoanCanBeRepaid(1, 0);
    }

    function test_shouldFail_checkLoanCanBeRepaid_LoanDefaulted() external {
        skip(30 days);
        uint40 ts = uint40(block.timestamp - 1);
        vm.expectRevert(abi.encodeWithSelector(SDSimpleLoan.LoanDefaulted.selector, ts));
        simpleLoan.exposed_checkLoanCanBeRepaid(2, ts);
    }

    function test_shouldFail_DifferentCreditAddress(address loanCreditAddress, address expectedCreditAddress)
        external
    {
        vm.assume(loanCreditAddress != expectedCreditAddress);

        vm.expectRevert(
            abi.encodeWithSelector(
                SDSimpleLoan.DifferentCreditAddress.selector, loanCreditAddress, expectedCreditAddress
            )
        );
        simpleLoan.exposed_checkLoanCreditAddress(loanCreditAddress, expectedCreditAddress);
    }
}
