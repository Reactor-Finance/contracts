// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IPairFactory {
    function allPairsLength() external view returns (uint);
    function isPair(address pair) external view returns (bool);
    function allPairs(uint index) external view returns (address);
    function getPair(address tokenA, address token, bool stable) external view returns (address);
    function createPair(address tokenA, address tokenB, bool stable) external returns (address pair);
    function dibs() external view returns (address);
    function stakingFeehandler() external view returns (address);
    function stableFee() external view returns (uint256);
    function volatileFee() external view returns (uint256);
    function stakingNFTFee() external view returns (uint256);
    function MAX_REFERRAL_FEE() external view returns (uint256);
    function MAX_FEE() external view returns (uint256);
    function feeManager() external view returns (address);
    function pendingFeeManager() external view returns (address);
}
