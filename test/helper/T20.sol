// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract T20 is ERC20 {
    bool blockTransfer;
    address blockedAddress;
    bool fee;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) { }

    function blockTransfers(bool blockTransfer_, address blockAddr) external {
        blockTransfer = blockTransfer_;
        blockedAddress = blockAddr;
    }

    function setFee(bool fee_) external {
        fee = fee_;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if (blockTransfer && recipient == blockedAddress) {
            revert("T20: transfer blocked");
        }
        if (fee) {
            amount -= 1;
        }
        return super.transfer(recipient, amount);
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        if (blockTransfer && to == blockedAddress) {
            revert("T20: transfer blocked");
        }
        if (fee) {
            value -= 1;
        }
        return super.transferFrom(from, to, value);
    }

    function mint(address owner, uint256 amount) external {
        _mint(owner, amount);
    }

    function burn(address owner, uint256 amount) external {
        _burn(owner, amount);
    }

    function mintAndApprove(address to, uint256 amount, address spender, uint256 value) external {
        _mint(to, amount);
        _approve(to, spender, value);
    }
}
