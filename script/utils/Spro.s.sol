// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Script, console } from "forge-std/Script.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { Spro } from "src/spro/Spro.sol";
import { SproLoan } from "src/spro/SproLoan.sol";
import { ISproTypes } from "src/interfaces/ISproTypes.sol";
import { ISproLoan } from "src/interfaces/ISproLoan.sol";

contract DeploySproLoanTest is Script {
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    function run() external {
        address deployerAddress = vm.envAddress("DEPLOYER_ADDRESS");
        vm.startBroadcast(deployerAddress);

        SproHandlerTest spro = new SproHandlerTest();
        ISproLoan sproLoan = ISproLoan(address(spro.loanToken()));

        console.log("Spro address", address(spro));
        console.log("loanToken address", address(sproLoan));

        uint256 loanId = sproLoan.mint(deployerAddress);
        uint256 collateralDecimals = IERC20Metadata(WETH).decimals();
        uint256 creditDecimals = IERC20Metadata(USDC).decimals();
        spro.setLoan(
            loanId,
            ISproTypes.Loan({
                status: ISproTypes.LoanStatus.RUNNING,
                lender: deployerAddress,
                borrower: deployerAddress,
                startTimestamp: uint40(1_742_203_988),
                loanExpiration: uint40(1_742_203_988 + 100 days),
                collateral: WETH,
                collateralAmount: 100 * 10 ** collateralDecimals,
                credit: USDC,
                principalAmount: 200 * 10 ** creditDecimals,
                fixedInterestAmount: 10 * 10 ** creditDecimals
            })
        );

        vm.stopBroadcast();
    }
}

contract SproHandlerTest {
    SproLoan public loanToken;
    mapping(uint256 => ISproTypes.Loan) internal _loans;

    function setUp() public virtual {
        loanToken = new SproLoan(address(this));
    }

    function setLoan(uint256 loanId, ISproTypes.Loan memory loan_) public {
        _loans[loanId] = loan_;
    }

    function getLoan(uint256 loanId) external view returns (ISproTypes.Loan memory loan_) {
        loan_ = _loans[loanId];
    }
}
