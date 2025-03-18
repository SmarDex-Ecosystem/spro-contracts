// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { IERC20Metadata } from "@openzeppelin/contracts//token/ERC20/extensions/IERC20Metadata.sol";

import { ISproTypes } from "src/interfaces/ISproTypes.sol";

library NFTRenderer {
    function render(ISproTypes.Loan memory loan) public view returns (string memory uri_) {
        IERC20Metadata credit = IERC20Metadata(loan.credit);
        IERC20Metadata collateral = IERC20Metadata(loan.collateral);

        string memory creditSymbol = credit.symbol();
        string memory collateralSymbol = collateral.symbol();
        uint256 creditAmount = loan.principalAmount / 10 ** credit.decimals();
        uint256 collateralAmount = loan.collateralAmount / 10 ** collateral.decimals();
        uint256 fee = loan.fixedInterestAmount / 10 ** credit.decimals();

        bytes memory svg = abi.encodePacked(
            "<svg xmlns='http://www.w3.org/2000/svg' width='300' height='300' viewBox='0 0 300 300'>",
            "<style>.title { font: bold 20px sans-serif; text-anchor: middle; }",
            ".text { font: normal 14px sans-serif; text-anchor: middle; }",
            ".label { font: bold 14px sans-serif; text-anchor: start; }</style>",
            renderBackground(creditSymbol, collateralSymbol),
            renderContent(creditSymbol, collateralSymbol, creditAmount, collateralAmount, fee),
            "</svg>"
        );
        string memory description =
            renderDescription(creditSymbol, collateralSymbol, fee, creditAmount, collateralAmount);
        string memory image = string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(svg)));
        bytes memory json =
            abi.encodePacked('{"name":"Spro loan",', '"description":"', description, '",', '"image":"', image, '"}');

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
    }

    function renderBackground(string memory creditSymbol, string memory collateralSymbol)
        internal
        pure
        returns (string memory background)
    {
        bytes32 key = keccak256(abi.encodePacked(creditSymbol, collateralSymbol));
        uint256 hue = uint256(key) % 360;

        background = string.concat(
            '<rect width="300" height="300" fill="hsl(',
            Strings.toString(hue),
            ',40%,40%)"/>',
            '<rect x="10" y="10" width="280" height="280" rx="15" ry="15" fill="hsl(',
            Strings.toString(hue),
            ',100%,50%)" stroke="#000"/>'
        );
    }

    function renderContent(
        string memory creditSymbol,
        string memory collateralSymbol,
        uint256 creditAmount,
        uint256 collateralAmount,
        uint256 fee
    ) internal pure returns (string memory content) {
        content = string.concat(
            '<text x="150" y="40" class="title" fill="#fff">',
            creditSymbol,
            " - ",
            collateralSymbol,
            " Loan</text>",
            '<line x1="50" y1="60" x2="250" y2="60" stroke="#fff" stroke-width="2"/>',
            '<text x="150" y="100" class="text" fill="#fff">Credit: ',
            Strings.toString(creditAmount),
            " ",
            creditSymbol,
            "</text>",
            '<text x="150" y="140" class="text" fill="#fff">Bonus: ',
            Strings.toString(fee),
            " ",
            creditSymbol,
            "</text>",
            '<text x="150" y="180" class="text" fill="#fff">Collateral: ',
            Strings.toString(collateralAmount),
            " ",
            collateralSymbol,
            "</text>"
        );
    }

    function renderDescription(
        string memory creditSymbol,
        string memory collateralSymbol,
        uint256 fee,
        uint256 credit,
        uint256 collateral
    ) internal pure returns (string memory description) {
        description = string.concat(
            "Credit: ",
            Strings.toString(credit),
            " ",
            creditSymbol,
            ", Bonus: ",
            Strings.toString(fee),
            " ",
            creditSymbol,
            ", Collateral: ",
            Strings.toString(collateral),
            " ",
            collateralSymbol
        );
    }
}
