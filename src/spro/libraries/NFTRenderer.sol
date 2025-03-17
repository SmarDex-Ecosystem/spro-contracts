// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { IERC20Metadata } from "@openzeppelin/contracts//token/ERC20/extensions/IERC20Metadata.sol";

import { ISproTypes } from "src/interfaces/ISproTypes.sol";

library NFTRenderer {
    function render(ISproTypes.Loan memory loan) public view returns (string memory uri_) {
        IERC20Metadata token0 = IERC20Metadata(loan.credit);
        IERC20Metadata token1 = IERC20Metadata(loan.collateral);

        uint40 startTimestamp = loan.startTimestamp;
        uint40 loanExpiration = loan.loanExpiration;
        uint256 collateralAmount = loan.collateralAmount;
        uint256 principalAmount = loan.principalAmount;
        uint256 fee = loan.fixedInterestAmount / 10 ** 18;

        string memory symbol0 = token0.symbol();
        string memory symbol1 = token1.symbol();
        string memory image = string.concat(
            "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 300 480'>",
            "<style>.tokens { font: bold 30px sans-serif; }",
            ".fee { font: normal 26px sans-serif; }",
            ".tick { font: normal 18px sans-serif; }</style>",
            "<script>",
            "function timestampToDate(timestamp) {",
            "  const date = new Date(timestamp * 1000);",
            "  const year = date.getFullYear();",
            "  const month = String(date.getMonth() + 1).padStart(2, '0');",
            "  const day = String(date.getDate()).padStart(2, '0');",
            "  return `${year}-${month}-${day}`;",
            "}",
            "</script>",
            renderBackground(loan.lender, principalAmount, collateralAmount),
            renderTop(symbol0, symbol1, startTimestamp, loanExpiration),
            renderBottom(principalAmount, collateralAmount, fee, symbol0, symbol1),
            "</svg>"
        );
        string memory description = renderDescription(symbol0, symbol1, uint24(fee), 1250, 48);
        string memory json = string.concat(
            '{"name":"Spro loan",',
            '"description":"',
            description,
            '",',
            '"image":"data:image/svg+xml;base64,',
            Base64.encode(bytes(image)),
            '"}'
        );

        return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
    }

    function renderBackground(address owner, uint256 lowerTick, uint256 upperTick)
        internal
        pure
        returns (string memory background)
    {
        bytes32 key = keccak256(abi.encodePacked(owner, lowerTick, upperTick));
        uint256 hue = uint256(key) % 360;

        background = string.concat(
            '<rect width="300" height="480" fill="hsl(',
            Strings.toString(hue),
            ',40%,40%)"/>',
            '<rect x="30" y="30" width="240" height="420" rx="15" ry="15" fill="hsl(',
            Strings.toString(hue),
            ',100%,50%)" stroke="#000"/>'
        );
    }

    function renderTop(string memory symbol0, string memory symbol1, uint40 startTimestamp, uint40 loanExpiration)
        internal
        pure
        returns (string memory top)
    {
        top = string.concat(
            '<rect x="30" y="87" width="240" height="42"/>',
            '<text x="39" y="120" class="tokens" fill="#fff">',
            symbol0,
            "/",
            symbol1,
            "</text>",
            '<rect x="30" y="162" width="240" height="24"/>',
            '<text x="39" y="180" class="tick" fill="#fff">Start: <tspan id="startDate">',
            "</tspan></text>",
            '<rect x="30" y="192" width="240" height="24"/>',
            '<text x="39" y="210" class="tick" fill="#fff">End: <tspan id="endDate">',
            "</tspan></text>",
            "<script>",
            "document.getElementById('startDate').textContent = timestampToDate(",
            Strings.toString(startTimestamp),
            ");",
            "document.getElementById('endDate').textContent = timestampToDate(",
            Strings.toString(loanExpiration),
            ");",
            "</script>"
        );
    }

    function renderBottom(
        uint256 lowerTick,
        uint256 upperTick,
        uint256 fee,
        string memory symbol0,
        string memory symbol1
    ) internal pure returns (string memory bottom) {
        bottom = string.concat(
            '<rect x="30" y="342" width="240" height="24"/>',
            '<text x="39" y="360" class="tick" fill="#fff">Credit : ',
            Strings.toString(lowerTick),
            " ",
            symbol0,
            "</text>",
            '<rect x="30" y="372" width="240" height="24"/>',
            '<text x="39" y="360" dy="30" class="tick" fill="#fff">Collateral: ',
            Strings.toString(upperTick),
            " ",
            symbol1,
            "</text>",
            '<rect x="30" y="402" width="240" height="24"/>',
            '<text x="39" y="390" dy="30" class="tick" fill="#fff">Fee: ',
            Strings.toString(fee),
            " ",
            symbol0,
            "</text>"
        );
    }

    function renderDescription(
        string memory symbol0,
        string memory symbol1,
        uint24 fee,
        uint256 lowerTick,
        uint256 upperTick
    ) internal pure returns (string memory description) {
        description = string.concat(
            symbol0,
            "/",
            symbol1,
            " ",
            Strings.toString(fee),
            ", Credit: ",
            Strings.toString(lowerTick),
            ", Collateral: ",
            Strings.toString(upperTick)
        );
    }
}
