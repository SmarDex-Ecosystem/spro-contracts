// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";
import { T20 } from "test/helper/T20.sol";

import { ERC20Wrapper } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Wrapper.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IAllowanceTransfer } from "permit2/src/interfaces/IAllowanceTransfer.sol";
import { PermitSignature } from "permit2/test/utils/PermitSignature.sol";

import { Spro } from "src/spro/Spro.sol";
import { SproLoan } from "src/spro/SproLoan.sol";

contract wethMock is ERC20, ERC20Wrapper, ERC20Permit {
    constructor(IERC20 token) ERC20("Wrapped Token", "wTKN") ERC20Permit("Wrapped Token") ERC20Wrapper(token) {
        _mint(msg.sender, 1e27);
    }

    function decimals() public view virtual override(ERC20, ERC20Wrapper) returns (uint8) {
        return ERC20.decimals();
    }
}

abstract contract SproForkBase is Test, PermitSignature {
    address payable constant PERMIT = payable(address(0x000000000022D473030F116dDEE9F6B43aC78BA3));
    uint256 public constant FEE = 20e18;
    uint16 public constant PARTIAL_POSITION_PERCENTAGE = 500;

    string public deploymentsSubpath;

    uint256[] deployedChains;
    Deployment deployment;

    // Properties need to be in alphabetical order
    struct Deployment {
        Spro config;
        SproLoan loanToken;
        address proxyAdmin;
        address protocolAdmin;
        T20 sdex;
        IAllowanceTransfer permit2;
    }

    function setUp() public virtual {
        string memory url = vm.rpcUrl("mainnet");
        vm.createSelectFork(url);
        deployment.proxyAdmin = makeAddr("proxyAdmin");
        deployment.protocolAdmin = address(this);

        // Deploy SDEX token
        deployment.sdex = new T20();

        deployment.permit2 = IAllowanceTransfer(PERMIT);

        vm.startPrank(deployment.protocolAdmin);

        // Deploy protocol
        deployment.config =
            new Spro(address(deployment.sdex), address(deployment.permit2), FEE, PARTIAL_POSITION_PERCENTAGE);
        vm.stopPrank();
        deployment.loanToken = deployment.config.loanToken();

        // Labels
        vm.label(deployment.proxyAdmin, "proxyAdmin");
        vm.label(deployment.protocolAdmin, "protocolAdmin");
        vm.label(address(deployment.sdex), "sdex");
        vm.label(address(deployment.permit2), "permit2");
        vm.label(address(deployment.config), "config");
        vm.label(address(deployment.loanToken), "loanToken");
    }
}
