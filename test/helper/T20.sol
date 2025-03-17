// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract T20 is ERC20 {
    bool blockTransfer;
    address blockedAddress;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) { }

    function blockTransfers(bool blockTransfer_, address blockAddr) external {
        blockTransfer = blockTransfer_;
        blockedAddress = blockAddr;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if (blockTransfer && recipient == blockedAddress) {
            revert("T20: transfer blocked");
        }
        return super.transfer(recipient, amount);
    }

    function mint(address owner, uint256 amount) external {
        _mint(owner, amount);
    }

    function burn(address owner, uint256 amount) external {
        _burn(owner, amount);
    }
}
