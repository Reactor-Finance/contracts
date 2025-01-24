// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBribe {
    function deposit(uint amount, uint tokenId) external;
    function withdraw(uint amount, uint tokenId) external;
    function getRewardForOwner(uint tokenId, address[] calldata tokens) external;
    function getRewardForAddress(address _owner, address[] memory tokens) external;
    function notifyRewardAmount(address token, uint amount) external;
    // function left(address token) external view returns (uint);
    function addRewardToken(address) external;
    function setVoter(address _voter) external;
    function setMinter(address _voter) external;
    function setOwner(address _voter) external;
    function emergencyRecoverERC20(address tokenAddress, uint256 tokenAmount) external;
    function recoverERC20AndUpdateData(address tokenAddress, uint256 tokenAmount) external;
}
