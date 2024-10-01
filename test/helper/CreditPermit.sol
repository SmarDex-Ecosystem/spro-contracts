// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { ERC20, ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract CreditPermit is ERC20Permit {
    constructor() ERC20("CREDIT", "CREDIT") ERC20Permit("CREDIT") { }

    function mint(address owner, uint256 amount) external {
        _mint(owner, amount);
    }

    function burn(address owner, uint256 amount) external {
        _burn(owner, amount);
    }
}
