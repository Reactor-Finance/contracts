// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBribe {
    struct Reward {
        uint256 periodFinish;
        uint256 rewardsPerEpoch;
        uint256 lastUpdateTime;
    }
    function rewardData(address _token, uint256 ts) external view returns (uint256, uint256, uint256);
    function rewardsListLength() external view returns (uint);
    function getEpochStart() external view returns (uint);
    function getNextEpochStart() external view returns (uint);
    function rewardTokens(uint index) external view returns (address);
    function earned(uint tokenId, address token) external view returns (uint);
    function firstBribeTimestamp() external view returns (uint);
    function totalSupplyAt(uint256 _timestamp) external view returns (uint256);
    function balanceOfAt(uint256 tokenId, uint256 _timestamp) external view returns (uint256);
    function deposit(uint amount, uint tokenId) external;
    function withdraw(uint amount, uint tokenId) external;
    function getRewardForOwner(uint tokenId, address[] calldata tokens) external;
    function getRewardForAddress(address _owner, address[] memory tokens) external;
    function notifyRewardAmount(address token, uint amount) external;
    function addRewardToken(address) external;
    function setVoter(address _voter) external;
    function setMinter(address _voter) external;
    function setOwner(address _voter) external;
    function emergencyRecoverERC20(address tokenAddress, uint256 tokenAmount) external;
    function recoverERC20AndUpdateData(address tokenAddress, uint256 tokenAmount) external;
}
