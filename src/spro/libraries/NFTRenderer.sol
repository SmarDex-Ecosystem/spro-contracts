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
            "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 300 480'>",
            "<style>.title { font: bold 25px sans-serif; }",
            ".text { font: normal 18px sans-serif; }</style>",
            renderBackground(loan.lender, creditSymbol, collateralSymbol),
            renderTop(creditSymbol, collateralSymbol),
            renderBottom(creditAmount, collateralAmount, fee, creditSymbol, collateralSymbol),
            "</svg>"
        );
        string memory description =
            renderDescription(creditSymbol, collateralSymbol, fee, creditAmount, collateralAmount);
        string memory image = string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(svg)));
        bytes memory json =
            abi.encodePacked('{"name":"Spro loan",', '"description":"', description, '",', '"image":"', image, '"}');

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
    }

    function renderBackground(address owner, string memory creditSymbol, string memory collateralSymbol)
        internal
        pure
        returns (string memory background)
    {
        bytes32 key = keccak256(abi.encodePacked(owner, creditSymbol, collateralSymbol));
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

    function renderTop(string memory creditSymbol, string memory collateralSymbol)
        internal
        pure
        returns (string memory top)
    {
        top = string.concat(
            '<rect x="30" y="87" width="240" height="42"/>',
            '<text x="39" y="120" class="title" fill="#fff">',
            creditSymbol,
            " - ",
            collateralSymbol,
            "</text>"
        );
    }

    function renderBottom(
        uint256 creditAmount,
        uint256 collateralAmount,
        uint256 fee,
        string memory creditSymbol,
        string memory collateralSymbol
    ) internal pure returns (string memory bottom) {
        bottom = string.concat(
            '<rect x="30" y="342" width="240" height="24"/>',
            '<text x="39" y="360" class="text" fill="#fff">Credit : ',
            Strings.toString(creditAmount),
            " ",
            creditSymbol,
            "</text>",
            '<rect x="30" y="372" width="240" height="24"/>',
            '<text x="39" y="360" dy="30" class="text" fill="#fff">Bonus: ',
            Strings.toString(fee),
            " ",
            creditSymbol,
            "</text>",
            '<rect x="30" y="402" width="240" height="24"/>',
            '<text x="39" y="390" dy="30" class="text" fill="#fff">Collateral: ',
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
