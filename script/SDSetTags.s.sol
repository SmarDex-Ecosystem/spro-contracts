// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import {console2} from "forge-std/src/Script.sol";
import {ScriptUtils} from "./lib/ScriptUtils.sol";

import {SDDeployments, PWNHubTags} from "pwn/SDDeployments.sol";
import "openzeppelin/utils/Create2.sol";

// This script must be run by the protocol admin
// Local:
// forge script script/SDSetTags.s.sol:SDSetTags -vvvvv --rpc-url $LOCAL_URL --private-key $PRIVATE_KEY --broadcast
contract SDSetTags is ScriptUtils, SDDeployments {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        _loadDeployedAddresses();

        // Set hub tags
        address[] memory addrs = new address[](10);
        addrs[0] = address(deployment.simpleLoan);
        addrs[1] = address(deployment.simpleLoan);

        addrs[2] = address(deployment.simpleLoanSimpleProposal);
        addrs[3] = address(deployment.simpleLoanSimpleProposal);

        bytes32[] memory tags = new bytes32[](10);
        tags[0] = PWNHubTags.ACTIVE_LOAN;
        tags[1] = PWNHubTags.NONCE_MANAGER;

        tags[2] = PWNHubTags.LOAN_PROPOSAL;
        tags[3] = PWNHubTags.NONCE_MANAGER;

        vm.startBroadcast(pk);

        deployment.hub.setTags(addrs, tags, true);

        vm.stopBroadcast();
    }
}
