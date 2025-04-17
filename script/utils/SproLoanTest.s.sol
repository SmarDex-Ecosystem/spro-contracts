// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Script, console } from "forge-std/Script.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { Spro } from "src/spro/Spro.sol";
import { SproLoan } from "src/spro/SproLoan.sol";
import { ISproTypes } from "src/interfaces/ISproTypes.sol";

/**
 * @title DeploySproLoanTest
 * @notice Script to deploy Spro and SproLoan contracts.
 * @dev This script deploys the SproLoan contract and mints a loan token for the deployer. Once deployed, you can either
 * add the NFT to your wallet or view the rendered SVG using this command: cast call --rpc-url {URL} {tokenOwner}
 * "tokenURI(uint256)(string)" 1 | sed 's/^"//; s/"$//' | sed 's|^data:application/json;base64,||' | base64 -d | jq -r
 * '.image' | sed 's|^data:image/svg+xml;base64,||' | base64 -d.
 */
contract DeploySproLoanTest is Script {
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    function run() external {
        address deployerAddress = vm.envAddress("DEPLOYER_ADDRESS");
        vm.startBroadcast(deployerAddress);

        SproHandlerTest spro = new SproHandlerTest();
        SproLoan sproLoan = new SproLoan(address(spro));

        uint256 loanId = spro.forceMint(msg.sender, sproLoan);
        uint256 collateralDecimals = IERC20Metadata(WETH).decimals();
        uint256 creditDecimals = IERC20Metadata(USDC).decimals();
        spro.setLoan(
            loanId,
            ISproTypes.Loan({
                status: ISproTypes.LoanStatus.RUNNING,
                lender: msg.sender,
                borrower: msg.sender,
                startTimestamp: uint40(1_742_203_988),
                loanExpiration: uint40(1_742_203_988 + 100 days),
                collateralAddress: WETH,
                collateralAmount: 100 * 10 ** collateralDecimals,
                creditAddress: USDC,
                principalAmount: 200 * 10 ** creditDecimals,
                fixedInterestAmount: 10 * 10 ** creditDecimals
            })
        );

        console.log("Spro address", address(spro));
        console.log("loanToken address", address(sproLoan));
        console.log("tokenOwner", sproLoan.ownerOf(loanId));

        vm.stopBroadcast();
    }
}

/**
 * @title SproHandlerTest
 * @dev This contract is used to test the SproLoan contract.
 * It allows setting and getting loan data for testing purposes.
 * It also allows minting a loan token directly for testing.
 */
contract SproHandlerTest {
    mapping(uint256 => ISproTypes.Loan) internal _loans;

    function setLoan(uint256 loanId, ISproTypes.Loan memory loan) public {
        _loans[loanId] = loan;
    }

    function getLoan(uint256 loanId) external view returns (ISproTypes.Loan memory loan_) {
        loan_ = _loans[loanId];
    }

    function forceMint(address to, SproLoan sproLoan) external returns (uint256 loanId_) {
        return sproLoan.mint(to);
    }
}
