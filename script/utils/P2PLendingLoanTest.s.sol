// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Script, console } from "forge-std/Script.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { P2PLending } from "src/p2pLending/P2PLending.sol";
import { P2PLendingLoan } from "src/p2pLending/P2PLendingLoan.sol";
import { IP2PLendingTypes } from "src/interfaces/IP2PLendingTypes.sol";

/**
 * @title DeployP2PLendingLoanTest
 * @notice Script to deploy P2PLending and P2PLendingLoan contracts.
 * @dev This script deploys the P2PLendingLoan contract and mints a loan token for the deployer. Once deployed, you can
 * either
 * add the NFT to your wallet or view the rendered SVG using this command: cast call --rpc-url {URL} {tokenOwner}
 * "tokenURI(uint256)(string)" 1 | sed 's/^"//; s/"$//' | sed 's|^data:application/json;base64,||' | base64 -d | jq -r
 * '.image' | sed // 's|^data:image/svg+xml;base64,||' | base64 -d.
 */
contract DeployP2PLendingLoanTest is Script {
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    function run() external {
        address deployerAddress = vm.envAddress("DEPLOYER_ADDRESS");
        vm.startBroadcast(deployerAddress);

        P2PLendingHandlerTest spro = new P2PLendingHandlerTest();
        P2PLendingLoan sproLoan = new P2PLendingLoan(address(spro));

        uint256 loanId = spro.forceMint(msg.sender, sproLoan);
        uint256 collateralDecimals = IERC20Metadata(WETH).decimals();
        uint256 creditDecimals = IERC20Metadata(USDC).decimals();
        spro.setLoan(
            loanId,
            IP2PLendingTypes.Loan({
                status: IP2PLendingTypes.LoanStatus.RUNNING,
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

        console.log("P2PLending address", address(spro));
        console.log("loanToken address", address(sproLoan));
        console.log("tokenOwner", sproLoan.ownerOf(loanId));

        vm.stopBroadcast();
    }
}

/**
 * @title P2PLendingHandlerTest
 * @dev This contract is used to test the P2PLendingLoan contract.
 * It allows setting and getting loan data for testing purposes.
 * It also allows minting a loan token directly for testing.
 */
contract P2PLendingHandlerTest {
    mapping(uint256 => IP2PLendingTypes.Loan) internal _loans;

    function setLoan(uint256 loanId, IP2PLendingTypes.Loan memory loan) public {
        _loans[loanId] = loan;
    }

    function getLoan(uint256 loanId) external view returns (IP2PLendingTypes.Loan memory loan_) {
        loan_ = _loans[loanId];
    }

    function forceMint(address to, P2PLendingLoan sproLoan) external returns (uint256 loanId_) {
        return sproLoan.mint(to);
    }
}
