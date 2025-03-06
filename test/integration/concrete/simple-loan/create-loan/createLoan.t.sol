// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { SDBaseIntegrationTest, Spro } from "test/integration/SDBaseIntegrationTest.t.sol";

import { ISproTypes } from "src/interfaces/ISproTypes.sol";

contract CreateLoan_SDSimpleLoan_Integration_Concrete_Test is SDBaseIntegrationTest {
    modifier proposalContractHasTag() {
        _;
    }

    modifier whenLoanTermsValid() {
        _;
    }

    modifier whenERC20Collateral() {
        _;
    }

    function test_CreateLoan_ERC20() external proposalContractHasTag whenLoanTermsValid whenERC20Collateral {
        _createERC20Proposal();

        vm.startPrank(lender);
        credit.mint(lender, INITIAL_CREDIT_BALANCE);
        credit.approve(address(deployment.config), CREDIT_LIMIT);

        uint256 id = deployment.config.createLoan(proposal, CREDIT_LIMIT, "");
        vm.stopPrank();

        assertEq(deployment.loanToken.ownerOf(id), lender);
        assertEq(deployment.sdex.balanceOf(address(0xdead)), deployment.config.fee());
        assertEq(deployment.sdex.balanceOf(borrower), INITIAL_SDEX_BALANCE - deployment.config.fee());
        assertEq(deployment.sdex.balanceOf(lender), INITIAL_SDEX_BALANCE);

        (Spro.Loan memory loanInfo,,) = deployment.config.getLoan(id);
        assertTrue(loanInfo.status == ISproTypes.LoanStatus.RUNNING);

        assertEq(credit.balanceOf(lender), INITIAL_CREDIT_BALANCE - CREDIT_LIMIT);
        assertEq(credit.balanceOf(borrower), CREDIT_LIMIT);
    }
}
