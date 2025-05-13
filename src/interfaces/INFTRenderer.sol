// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { ISproTypes } from "src/interfaces/ISproTypes.sol";

interface INFTRenderer {
    /**
     * @notice Renders the JSON metadata for a given loan NFT.
     * @param loan The loan data.
     * @return uri_ The JSON metadata URI for the loan NFT.
     */
    function render(ISproTypes.Loan memory loan) external view returns (string memory uri_);
}
