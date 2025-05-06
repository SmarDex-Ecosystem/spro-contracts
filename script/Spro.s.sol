// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Script } from "forge-std/Script.sol";
import { Spro } from "src/spro/Spro.sol";
import { SproLoan } from "src/spro/SproLoan.sol";

contract Deploy is Script {
    address constant SDEX_MAINNET = 0x5DE8ab7E27f6E7A1fFf3E5B337584Aa43961BEeF;
    address constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    address constant SAFE_WALLET = 0x1E3e1128F6bC2264a19D7a065982696d356879c5;
    uint256 internal constant FEE = 50e18;
    uint16 internal constant PARTIAL_POSITION_BPS = 500;

    function run() external returns (Spro spro_, SproLoan sproLoan_) {
        vm.broadcast();
        spro_ = new Spro(SDEX_MAINNET, PERMIT2, FEE, PARTIAL_POSITION_BPS, SAFE_WALLET);
        sproLoan_ = spro_._loanToken();
    }
}
