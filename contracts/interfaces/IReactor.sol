// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IReactor {
    function mint(address, uint) external returns (bool);
    function minter() external returns (address);
}
