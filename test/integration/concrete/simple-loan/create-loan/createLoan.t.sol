// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { SigUtils } from "test/utils/SigUtils.sol";
import { IPoolAdapter } from "test/helper/DummyPoolAdapter.sol";
import { SDBaseIntegrationTest, Spro } from "test/integration/SDBaseIntegrationTest.t.sol";

import { ISproErrors } from "src/interfaces/ISproErrors.sol";
import { SproConstantsLibrary as Constants } from "src/libraries/SproConstantsLibrary.sol";
import { ISproTypes } from "src/interfaces/ISproTypes.sol";

contract CreateLoan_SDSimpleLoan_Integration_Concrete_Test is SDBaseIntegrationTest {
    modifier proposalContractHasTag() {
        _;
    }

    function test_RevertWhen_InvalidLoanDuration() external proposalContractHasTag {
        // Set bad duration value
        uint256 minDuration = Constants.MIN_LOAN_DURATION;
        proposal.loanExpiration = proposal.startTimestamp + uint32(minDuration - 1);

        // Create proposal
        _createERC20Proposal();

        // Specs
        Spro.LenderSpec memory lenderSpec = _buildLenderSpec(true);

        vm.prank(lender);
        vm.expectRevert(
            abi.encodeWithSelector(
                ISproErrors.InvalidDuration.selector, proposal.loanExpiration - proposal.startTimestamp, minDuration
            )
        );
        deployment.config.createLoan(proposal, lenderSpec, "", "");
    }

    function test_RevertWhen_InvalidMaxApr() external proposalContractHasTag {
        // Set bad max accruing interest apr
        uint256 maxApr = Constants.MAX_ACCRUING_INTEREST_APR;
        proposal.accruingInterestAPR = uint24(maxApr + 1);

        // Create proposal
        _createERC20Proposal();

        // Specs
        Spro.LenderSpec memory lenderSpec = _buildLenderSpec(true);

        vm.prank(lender);
        vm.expectRevert(
            abi.encodeWithSelector(ISproErrors.InterestAPROutOfBounds.selector, proposal.accruingInterestAPR, maxApr)
        );
        deployment.config.createLoan(proposal, lenderSpec, "", "");
    }

    modifier whenLoanTermsValid() {
        _;
    }

    modifier whenERC20Collateral() {
        _;
    }

    function test_CreateLoan_ERC20() external proposalContractHasTag whenLoanTermsValid whenERC20Collateral {
        _createERC20Proposal();

        Spro.LenderSpec memory lenderSpec = _buildLenderSpec(true);

        vm.startPrank(lender);
        credit.mint(lender, INITIAL_CREDIT_BALANCE);
        credit.approve(address(deployment.config), CREDIT_LIMIT);

        uint256 id = deployment.config.createLoan(proposal, lenderSpec, "", "");
        vm.stopPrank();

        assertEq(deployment.loanToken.ownerOf(id), lender);
        assertEq(deployment.sdex.balanceOf(address(address(0xdead))), deployment.config.fixFeeUnlisted());
        assertEq(deployment.sdex.balanceOf(borrower), INITIAL_SDEX_BALANCE - deployment.config.fixFeeUnlisted());
        assertEq(deployment.sdex.balanceOf(lender), INITIAL_SDEX_BALANCE);

        (Spro.LoanInfo memory loanInfo) = deployment.config.getLoan(id);
        assertTrue(loanInfo.status == ISproTypes.LoanStatus.RUNNING);

        assertEq(credit.balanceOf(lender), INITIAL_CREDIT_BALANCE - lenderSpec.creditAmount);
        assertEq(credit.balanceOf(borrower), lenderSpec.creditAmount);
    }

    function test_CreateLoan_ERC20_PermitData()
        external
        proposalContractHasTag
        whenLoanTermsValid
        whenERC20Collateral
    {
        // Change the credit asset address
        proposal.creditAddress = address(creditPermit);
        _createERC20Proposal();

        Spro.LenderSpec memory lenderSpec = _buildLenderSpec(true);

        // Construct permit data for the lender
        permit.asset = address(creditPermit);
        permit.owner = lender;
        permit.amount = CREDIT_LIMIT;
        permit.deadline = 1 days;

        SigUtils.Permit memory p = SigUtils.Permit({
            owner: permit.owner,
            spender: address(deployment.config),
            value: permit.amount,
            nonce: creditPermit.nonces(lender),
            deadline: permit.deadline
        });

        bytes32 digest = sigUtils.getTypedDataHash(p);

        vm.startPrank(lender);
        // Mint initial credit permit balance for lender
        creditPermit.mint(lender, INITIAL_CREDIT_BALANCE);
        // sign the digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(lenderPK, digest);

        permit.v = v;
        permit.r = r;
        permit.s = s;

        // Zero the approvals before the repayment, tokens should be transferred via permit
        creditPermit.approve(address(deployment.config), 0);

        // Set the permit data
        lenderSpec.permitData = abi.encode(permit);

        uint256 id = deployment.config.createLoan(proposal, lenderSpec, "", "");
        vm.stopPrank();

        assertEq(deployment.loanToken.ownerOf(id), lender);
        assertEq(deployment.sdex.balanceOf(address(address(0xdead))), deployment.config.fixFeeUnlisted());
        assertEq(deployment.sdex.balanceOf(borrower), INITIAL_SDEX_BALANCE - deployment.config.fixFeeUnlisted());
        assertEq(deployment.sdex.balanceOf(lender), INITIAL_SDEX_BALANCE);

        (Spro.LoanInfo memory loanInfo) = deployment.config.getLoan(id);
        assertTrue(loanInfo.status == ISproTypes.LoanStatus.RUNNING);

        assertEq(creditPermit.balanceOf(lender), INITIAL_CREDIT_BALANCE - lenderSpec.creditAmount);
        assertEq(creditPermit.balanceOf(borrower), lenderSpec.creditAmount);
    }
}
