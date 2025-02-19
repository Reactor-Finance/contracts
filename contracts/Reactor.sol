// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {IReactor} from "./interfaces/IReactor.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract Reactor is IReactor, ERC20Permit {
    bool public initialMinted;
    address public minter;

    constructor() ERC20("REACTOR", "RCT") ERC20Permit("REACTOR") {
        minter = msg.sender;
    }

    // No checks as its meant to be once off to set minting rights to BaseV1 Minter
    function setMinter(address _minter) external {
        require(msg.sender == minter);
        minter = _minter;
    }

    function initialMint(address _recipient) external {
        require(msg.sender == minter && !initialMinted);
        initialMinted = true;
        _mint(_recipient, 100 * 1e6 * 1e18);
    }
    function mintRct(address account, uint amount) external  returns (bool) {
        _mint(account, amount);
        return true;
    }

    function mint(address account, uint amount) external returns (bool) {
        require(msg.sender == minter, "not allowed");
        _mint(account, amount);
        return true;
    }
}
