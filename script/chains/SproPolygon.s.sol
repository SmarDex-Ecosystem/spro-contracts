// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Script } from "forge-std/Script.sol";
import { Spro } from "src/spro/Spro.sol";
import { SproLoan } from "src/spro/SproLoan.sol";
import { DeploySpro } from "../Spro.s.sol";

contract Deploy is Script, DeploySpro {
    address constant SDEX = 0x6899fAcE15c14348E1759371049ab64A3a06bFA6;
    address constant OWNER_WALLET = 0x1F0214B6E2f7825C222B833dADD88B651628B085;
    uint256 constant POLYGON_CHAIN_ID = 137;

    function run() external returns (Spro spro_, SproLoan sproLoan_) {
        require(block.chainid == POLYGON_CHAIN_ID, "SproPolygon: Must be deployed on Polygon network");

        (spro_, sproLoan_) = run(SDEX, OWNER_WALLET);
    }
}
