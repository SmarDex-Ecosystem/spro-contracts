// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import { Spro } from "src/spro/Spro.sol";
import { T20 } from "test/helper/T20.sol";

contract SproFuzzTest {
    Spro spro;
    T20 sdex;
    uint256 numberOfProposals;
    address[] collateralAddresses;
    address[] creditAddresses;

    address payable constant PERMIT2 = payable(address(0x000000000022D473030F116dDEE9F6B43aC78BA3));
    uint256 public constant FEE = 20e18;
    uint16 public constant PARTIAL_POSITION_BPS = 500;

    constructor() payable {
        sdex = new T20("SDEX", "SDEX");
        spro = new Spro(address(sdex), PERMIT2, FEE, PARTIAL_POSITION_BPS);
        for (uint256 i = 0; i < 10; i++) {
            collateralAddresses.push(address(new T20("COLLAT", "COLLAT")));
            creditAddresses.push(address(new T20("CREDIT", "CREDIT")));
        }
    }

    function assertPartialPositionBps(uint16 bps) public {
        require(bps > 0 && bps <= spro.BPS_DIVISOR() / 2, "Invalid BPS");
        spro.setPartialPositionPercentage(bps);
        assert(spro._partialPositionBps() == bps);
    }

    function createProposal(
        uint8 collateralAddress,
        uint256 collateralAmount,
        uint8 creditAddress,
        uint256 availableCreditLimit,
        uint256 fixedInterestAmount,
        uint40 startTimestamp,
        uint40 loanExpiration
    ) public {
        require(collateralAddress < collateralAddresses.length, "Invalid collateral address");
        require(creditAddress < creditAddresses.length, "Invalid credit address");
        T20(collateralAddresses[collateralAddress]).mint(address(this), collateralAmount);
        T20(creditAddresses[creditAddress]).mint(address(this), availableCreditLimit);
        startTimestamp = uint40(block.timestamp + startTimestamp);
        loanExpiration = uint40(block.timestamp + startTimestamp + loanExpiration);
        try spro.createProposal(
            collateralAddresses[collateralAddress],
            collateralAmount,
            creditAddresses[creditAddress],
            availableCreditLimit,
            fixedInterestAmount,
            startTimestamp,
            loanExpiration,
            ""
        ) {
            numberOfProposals++;
        } catch { }
        assert(spro._proposalNonce() == numberOfProposals);
    }
}
