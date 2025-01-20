// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ITradeHelper {
    struct Route {
        address from;
        address to;
        bool stable;
    }

    function getAmountOutStable(uint amountIn, address tokenIn, address tokenOut) external view returns (uint amount);
    function getAmountOutVolatile(uint amountIn, address tokenIn, address tokenOut) external view returns (uint amount);
    function getAmountOut(
        uint amountIn,
        address tokenIn,
        address tokenOut
    ) external view returns (uint amount, bool stable);
    function getAmountsOut(uint amountIn, Route[] memory routes) external view returns (uint[] memory amounts);
    function getAmountInStable(uint amountOut, address tokenIn, address tokenOut) external view returns (uint amountIn);
    function pairFor(address tokenA, address tokenB, bool stable) external view returns (address pair);
    function sortTokens(address tokenA, address tokenB) external pure returns (address token0, address token1);
    function factory() external view returns (address);
}
