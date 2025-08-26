// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Script } from "forge-std/Script.sol";
import { Spro } from "src/spro/Spro.sol";
import { SproLoan } from "src/spro/SproLoan.sol";

contract DeploySpro is Script {
    address constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    uint256 internal constant FEE = 50e18;
    uint16 internal constant PARTIAL_POSITION_BPS = 500;

    function run(address sdex, address owner) public returns (Spro spro_, SproLoan sproLoan_) {
        vm.broadcast();
        spro_ = new Spro(sdex, PERMIT2, FEE, PARTIAL_POSITION_BPS, owner);
        sproLoan_ = spro_._loanToken();
    }
}
