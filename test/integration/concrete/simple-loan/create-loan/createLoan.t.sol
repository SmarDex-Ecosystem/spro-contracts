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
        assertEq(deployment.sdex.balanceOf(address(0xdead)), deployment.config.fee());
        assertEq(deployment.sdex.balanceOf(borrower), INITIAL_SDEX_BALANCE - deployment.config.fee());
        assertEq(deployment.sdex.balanceOf(lender), INITIAL_SDEX_BALANCE);

        (Spro.LoanInfo memory loanInfo) = deployment.config.getLoan(id);
        assertTrue(loanInfo.status == ISproTypes.LoanStatus.RUNNING);

        assertEq(credit.balanceOf(lender), INITIAL_CREDIT_BALANCE - lenderSpec.creditAmount);
        assertEq(credit.balanceOf(borrower), lenderSpec.creditAmount);
    }
}
