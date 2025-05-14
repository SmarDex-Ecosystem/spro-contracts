// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IP2PLendingTypes } from "src/interfaces/IP2PLendingTypes.sol";

interface INFTRenderer {
    /**
     * @notice Renders the JSON metadata for a given loan NFT.
     * @param loan The loan data.
     * @return uri_ The JSON metadata URI for the loan NFT.
     */
    function render(IP2PLendingTypes.Loan memory loan) external view returns (string memory uri_);
}
