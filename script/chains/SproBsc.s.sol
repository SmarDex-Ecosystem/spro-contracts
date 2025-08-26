// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Spro } from "src/spro/Spro.sol";
import { SproLoan } from "src/spro/SproLoan.sol";
import { DeploySpro } from "../Spro.s.sol";

contract Deploy is DeploySpro {
    address constant SDEX = 0xFdc66A08B0d0Dc44c17bbd471B88f49F50CdD20F;
    address constant OWNER_WALLET = 0x1F0214B6E2f7825C222B833dADD88B651628B085;
    uint256 constant BSC_CHAIN_ID = 56;

    function run() external returns (Spro spro_, SproLoan sproLoan_) {
        require(block.chainid == BSC_CHAIN_ID, "SproBsc script: Must be deployed on BSC network");

        (spro_, sproLoan_) = run(SDEX, OWNER_WALLET);
    }
}
