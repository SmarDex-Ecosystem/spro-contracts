// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";

import { DummyPoolAdapter } from "test/helper/DummyPoolAdapter.sol";
import { SproHandler } from "test/helper/SproHandler.sol";

import { Spro } from "src/spro/Spro.sol";
import { ISproTypes } from "src/interfaces/ISproTypes.sol";
import { ISproErrors } from "src/interfaces/ISproErrors.sol";

contract SproSimpleLoanTest is Test {
    address public sdex = makeAddr("sdex");
    address public permit2 = makeAddr("permit2");
    address public config = makeAddr("config");

    address public permitAsset = makeAddr("permitAsset");
    address public credit = makeAddr("credit");

    address poolAdapter = address(new DummyPoolAdapter());

    SproHandler sproHandler;

    function setUp() public {
        vm.etch(config, bytes("data"));
        sproHandler = new SproHandler(sdex, permit2, 1, 1);

        vm.mockCall(config, abi.encodeWithSignature("getPoolAdapter(address)"), abi.encode(poolAdapter));
    }

    function test_shouldFail_checkPermit_whenInvalidPermitOwner() external {
        Spro.Permit memory permit;
        permit.asset = permitAsset;

        vm.expectRevert(abi.encodeWithSelector(ISproErrors.InvalidPermitOwner.selector, permit.owner, address(this)));
        sproHandler.exposed_checkPermit(address(this), credit, permit);
    }

    function test_shouldFail_checkPermit_whenInvalidPermitAsset() external {
        Spro.Permit memory permit;
        permit.asset = permitAsset;
        permit.owner = address(this);

        vm.expectRevert(abi.encodeWithSelector(ISproErrors.InvalidPermitAsset.selector, permit.asset, address(this)));
        sproHandler.exposed_checkPermit({ caller: address(this), creditAddress: address(this), permit: permit });
    }

    function testFuzz_shouldFail_withdrawCreditFromPool_InvalidSourceOfFunds(
        address source,
        uint256 amount,
        bytes memory data
    ) external {
        address credit_;
        Spro.Terms memory loanTerms;
        Spro.LenderSpec memory lenderSpec =
            ISproTypes.LenderSpec({ sourceOfFunds: source, creditAmount: amount, permitData: data });

        vm.mockCall(config, abi.encodeWithSignature("getPoolAdapter(address)"), abi.encode(address(0)));

        vm.expectRevert(abi.encodeWithSelector(ISproErrors.InvalidSourceOfFunds.selector, lenderSpec.sourceOfFunds));
        sproHandler.exposed_withdrawCreditFromPool(credit_, amount, loanTerms, lenderSpec);
    }

    function test_loanRepaymentAmount_shouldReturnZeroForNonExistingLoan() external view {
        uint256 amount = sproHandler.loanRepaymentAmount(0);

        assertEq(amount, 0);
    }

    function test_shouldFail_checkLoanCanBeRepaid_NonExistingLoan() external {
        vm.expectRevert(ISproErrors.NonExistingLoan.selector);
        sproHandler.exposed_checkLoanCanBeRepaid(ISproTypes.LoanStatus.NONE, 0);

        vm.expectRevert(ISproErrors.LoanNotRunning.selector);
        sproHandler.exposed_checkLoanCanBeRepaid(ISproTypes.LoanStatus.PAID_BACK, 0);
    }

    function test_shouldFail_checkLoanCanBeRepaid_LoanNotRunning() external {
        vm.expectRevert(ISproErrors.LoanNotRunning.selector);
        sproHandler.exposed_checkLoanCanBeRepaid(ISproTypes.LoanStatus.PAID_BACK, 0);
    }

    function test_shouldFail_checkLoanCanBeRepaid_LoanDefaulted() external {
        skip(30 days);
        uint40 ts = uint40(block.timestamp - 1);
        vm.expectRevert(abi.encodeWithSelector(ISproErrors.LoanDefaulted.selector, ts));
        sproHandler.exposed_checkLoanCanBeRepaid(ISproTypes.LoanStatus.RUNNING, ts);
    }

    function test_shouldFail_DifferentCreditAddress(address loanCreditAddress, address expectedCreditAddress)
        external
    {
        vm.assume(loanCreditAddress != expectedCreditAddress);

        vm.expectRevert(
            abi.encodeWithSelector(
                ISproErrors.DifferentCreditAddress.selector, loanCreditAddress, expectedCreditAddress
            )
        );
        sproHandler.exposed_checkLoanCreditAddress(loanCreditAddress, expectedCreditAddress);
    }

    function testFuzz_shouldFail_partialLoan(uint256 a, uint256 l) external {
        vm.assume(a != l);

        vm.expectRevert(abi.encodeWithSelector(ISproErrors.OnlyCompleteLendingForNFTs.selector, a, l));
        sproHandler.exposed_checkCompleteLoan(a, l);
    }
}
