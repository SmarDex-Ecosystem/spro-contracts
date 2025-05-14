// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { ISproTypes } from "src/interfaces/ISproTypes.sol";
import { INFTRenderer } from "src/interfaces/INFTRenderer.sol";

contract NFTRenderer is INFTRenderer {
    /// @inheritdoc INFTRenderer
    function render(ISproTypes.Loan memory loan) external view returns (string memory uri_) {
        IERC20Metadata credit = IERC20Metadata(loan.creditAddress);
        IERC20Metadata collateral = IERC20Metadata(loan.collateralAddress);

        string memory creditTicker = credit.symbol();
        string memory collateralTicker = collateral.symbol();
        uint256 interest = loan.fixedInterestAmount / 10 ** credit.decimals();
        uint256 creditAmount = loan.principalAmount / 10 ** credit.decimals();
        uint256 collateralAmount = loan.collateralAmount / 10 ** collateral.decimals();

        bytes memory svg = abi.encodePacked(
            renderBackgroundAndTop(creditTicker, collateralTicker),
            renderInfobox(creditTicker, collateralTicker, interest, creditAmount, collateralAmount)
        );
        string memory description =
            "This NFT represents a unique loan created using the P2PLending Protocol, which is a key component of the SmarDex.io ecosystem. It enables decentralized lending and borrowing between users";
        string memory image = string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(svg)));
        string memory attributes =
            renderAttributes(creditTicker, collateralTicker, interest, creditAmount, collateralAmount);
        bytes memory json = abi.encodePacked(
            '{"name":"P2P loan","description":"',
            description,
            '","image":"',
            image,
            '","attributes":[',
            attributes,
            "]}"
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
    }

    /**
     * @notice Renders the SVG background and top section of the NFT.
     * @param creditTicker The ticker of the credit asset.
     * @param collateralTicker The ticker of the collateral asset.
     * @return background_ The SVG string for the background and top section.
     */
    function renderBackgroundAndTop(string memory creditTicker, string memory collateralTicker)
        internal
        pure
        returns (string memory background_)
    {
        background_ = string.concat(
            "<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' xml:space='preserve' width='500' height='500' version='1.1'><defs><path id='logo' d='M140 98.577a3.035 3.035 0 0 0-1.514-2.623l-26.979-15.551a3.035 3.035 0 0 0-3.021 0L81.528 95.975A3.02 3.02 0 0 0 80 98.59v31.13a3.02 3.02 0 0 0 1.514 2.603l26.972 15.586a3 3 0 0 0 3.021 0l26.979-15.586A3.02 3.02 0 0 0 140 129.72Zm-8.442 26.267a3.028 3.028 0 0 1-1.514 2.596l-18.537 10.723a3 3 0 0 1-3.021 0l-18.53-10.723a3.028 3.028 0 0 1-1.514-2.623v-7.96l20.044 11.56a3.035 3.035 0 0 0 3.028 0l7.374-4.256v-9.733l-6.879 3.998a3.035 3.035 0 0 1-3.042 0l-12.076-6.977-8.435-4.884v-3.097a3.035 3.035 0 0 1 1.514-2.624l18.516-10.695a3.049 3.049 0 0 1 3.028 0l18.516 10.681a3.035 3.035 0 0 1 1.514 2.624v8.002l-8.442-4.884-11.588-6.676A2.98 2.98 0 0 0 110 99.49a3.028 3.028 0 0 0-1.52.405l-7.34 4.248h-.05v9.768l6.873-3.99a3.007 3.007 0 0 1 3.035 0l12.111 6.976v-.056l8.45 4.884z'/><pattern id='basepattern' width='60' height='68.318' patternUnits='userSpaceOnUse' preserveAspectRatio='xMidYMid' style='fill:#000'><g transform='translate(-80 -80)'><use href='#logo' /></g></pattern><pattern xlink:href='#basepattern' id='bgpattern1' width='72' height='123' x='36' y='61.5' patternTransform='translate(80 80)' preserveAspectRatio='xMidYMid'/><pattern xlink:href='#basepattern' id='bgpattern2' width='72' height='123' x='0' y='0' patternTransform='translate(80 80)' preserveAspectRatio='xMidYMid'/><linearGradient id='basegradient'><stop style='stop-color:#00ab72'/><stop offset='1'/></linearGradient><linearGradient xlink:href='#basegradient' id='bggradient' x1='250' x2='250' y1='500' y2='0' gradientUnits='userSpaceOnUse'/><style>.text{font-family:Arial,sans-serif;fill:#fff}.bold{font-weight:700}.title{font-size:21.3333px;fill:#00ffb2}.ticker{font-style:italic;font-size:17.3333px}.value{font-size:21.3333px}</style></defs><rect width='499' height='499' x='.5' y='.5' rx='19.96' ry='19.96' style='fill:url(#bggradient)'/><g style='opacity:.05' transform='matrix(.998 0 0 .998 .5 .5)'><rect width='500' height='500' rx='20' ry='20' style='fill:#00ab72'/><rect width='500' height='500' rx='20' ry='20' style='fill:url(#bgpattern2)'/><rect width='500' height='500' rx='20' ry='20' style='fill:url(#bgpattern1)'/></g><rect width='497.018' height='497.018' x='1.491' y='1.491' rx='19.881' ry='19.881' style='fill:none;stroke:#00ffb2;stroke-width:2.98211'/><g transform='matrix(.405 0 0 .405 153.96 56.765)' style='fill:#fff'><use href='#logo' style='fill:#00ffb2' transform='matrix(1.45 0 0 1.45 -118 -118)' /><path d='M117.18 38.73c0 3.08 2.69 4.87 7.42 5.44 2.81.26 4.93.51 8 .83 9.08.9 16.05 4.36 16.05 14 0 8.19-6.46 14.14-19.32 14.14-14.85 0-20.54-7.48-22.33-14h9.15c1.22 2.86 4.85 6.66 13.18 6.66 6.92 0 10.56-2.63 10.56-6.27 0-4.35-3.2-5.76-7.87-6.34l-8.02-.83c-9.09-.9-15.48-5.18-15.48-13.38 0-8.2 7.36-13 18.17-13 14.27 0 19.52 6.85 20.92 12.61h-8.76c-1.28-2.31-4.74-5.31-12.16-5.31-6.21 0-9.47 2.11-9.47 5.43z' /><path d='m184.18 59.91 13.62-33.08h12.35v45.43h-8.32V35L187.7 69.75a4.33 4.33 0 0 1-8 0l-14-34.41v36.92h-7.93V26.83h12.86z' /><path d='M253.72 62.92h-22.91l-4.16 9.34H218l20.42-45.62h8.12L267 72.26h-9.15l-4.16-9.34zm-3.26-7.42-8.19-18.36-8.19 18.36z' /><path d='M274.9 26.83h25.4c9.92 0 15.54 4.68 15.54 13.57 0 6.14-3.19 10.49-9 12.28l10.69 19.58h-9.09l-10.3-18.69h-14.67v18.69h-8.58V26.83Zm8.57 7.62v11.64h16.12c4.93 0 7.42-1.79 7.42-5.69 0-4.16-2.49-5.95-7.42-5.95z' /><path d='M326.65 26.83H345c14.52 0 24.31 8.32 24.31 22.72 0 14.4-9.71 22.71-24.31 22.71h-18.35zm8.58 7.55v30.33h9.66c9.53 0 15.67-5.82 15.67-15.17s-6.14-15.16-15.67-15.16z' /><path d='M377.34 26.83h36.79v7.42h-28.22v10.37h16.83v7.48h-16.83v12.54h30.78v7.62h-39.35z' /><path d='m447.94 55.24-14.72 17h-10.11l19.71-23-19.2-22.46h11.26l13.5 16 13.69-16h10.37l-19 22 19.83 23.42h-10.82l-14.52-17z' /></g><text class='text bold' style='font-size:37.3333px' text-anchor='middle' x='250' y='209.583'>",
            creditTicker,
            " / ",
            collateralTicker,
            "</text><text class='text bold' style='font-size:21.3333px;fill:#0fa' x='219.781' y='168.915'>LOAN</text><text class='text' style='font-size:12px;letter-spacing:13px' x='98.266' y='473.545'>VISIT SMARDEX.IO</text><rect id='infobox' width='429.95' height='59.071' x='35.026' y='251.684' rx='7.001' ry='6.043' style='fill:#002610;stroke:#00ffb2;stroke-width:.929181'/><use xlink:href='#infobox' transform='translate(0 65)'/><use xlink:href='#infobox' transform='translate(0 130)'/><text class='text title' transform='translate(0 17.791)' x='48' y='270.9'>Loan</text><text class='text title' transform='translate(0 83.791)' x='48' y='270.9'>Interest</text><text class='text title' transform='translate(0 147.791)' x='48' y='270.9'>Collateral</text><text class='text value' transform='translate(0 16)' text-anchor='end' x='452' y='273.302'><tspan class='bold'>"
        );
    }

    /**
     * @notice Renders the infobox sections of the NFT.
     * @param creditTicker The ticker of the credit asset.
     * @param collateralTicker The ticker of the collateral asset.
     * @param interest The interest amount.
     * @param credit The credit amount.
     * @param collateral The collateral amount.
     * @return infobox_ The SVG string for the infobox sections.
     */
    function renderInfobox(
        string memory creditTicker,
        string memory collateralTicker,
        uint256 interest,
        uint256 credit,
        uint256 collateral
    ) internal pure returns (string memory infobox_) {
        infobox_ = string.concat(
            Strings.toString(credit),
            " </tspan><tspan class='ticker'>",
            creditTicker,
            "</tspan></text><text class='text value' transform='translate(0 82)' text-anchor='end' x='452' y='273.302'><tspan class='bold'>",
            Strings.toString(interest),
            " </tspan><tspan class='ticker'>",
            creditTicker,
            "</tspan></text><text class='text value' transform='translate(0 146)' text-anchor='end' x='452' y='273.302'><tspan class='bold'>",
            Strings.toString(collateral),
            " </tspan><tspan class='ticker'>",
            collateralTicker,
            "</tspan></text></svg>"
        );
    }

    /**
     * @notice Renders the attributes for the NFT.
     * @param creditTicker The ticker of the credit asset.
     * @param collateralTicker The ticker of the collateral asset.
     * @param interest The interest amount.
     * @param creditAmount The credit amount.
     * @param collateralAmount The collateral amount.
     * @return attributes_ The JSON string for the attributes.
     */
    function renderAttributes(
        string memory creditTicker,
        string memory collateralTicker,
        uint256 interest,
        uint256 creditAmount,
        uint256 collateralAmount
    ) internal pure returns (string memory attributes_) {
        attributes_ = string.concat(
            '{"display_type":"number","trait_type":"Credit Amount","value":',
            Strings.toString(creditAmount),
            '},{"trait_type":"Credit Asset","value":"',
            creditTicker,
            '"},{"display_type":"number","trait_type":"Collateral Amount","value":',
            Strings.toString(collateralAmount),
            '},{"trait_type":"Collateral Asset","value":"',
            collateralTicker,
            '"},{"display_type":"number","trait_type":"Interest Amount","value":',
            Strings.toString(interest),
            "}"
        );
    }
}
