// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TransferHelper} from "./libraries/TransferHelper.sol";
import {SafeMath} from "./libraries/SafeMath.sol";
import {IPair} from "./interfaces/IPair.sol";
import {IPairFactory} from "./interfaces/IPairFactory.sol";
import {ITradeHelper} from "./interfaces/ITradeHelper.sol";
import {IWETH} from "./interfaces/IWETH.sol";

contract Router {
    using SafeMath for uint256;

    ITradeHelper public tradeHelper;
    IWETH public wETH;

    address public ETHER = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, "Router: EXPIRED_TRANSACTION");
        _;
    }

    constructor(address _tradeHelper, IWETH _weth) {
        tradeHelper = ITradeHelper(_tradeHelper);
        wETH = _weth;
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quoteLiquidity(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, "Router: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "Router: INSUFFICIENT_LIQUIDITY");
        amountB = (amountA * reserveB) / reserveA;
    }

    function quoteRemoveLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint liquidity
    ) external view returns (uint amountA, uint amountB) {
        address _pair = IPairFactory(factory).getPair(tokenA, tokenB, stable);

        if (_pair == address(0)) {
            return (0, 0);
        }

        (uint reserveA, uint reserveB) = getReserves(tokenA, tokenB, stable);
        uint _totalSupply = IERC20(_pair).totalSupply();

        amountA = (liquidity * reserveA) / _totalSupply; // using balances ensures pro-rata distribution
        amountB = (liquidity * reserveB) / _totalSupply; // using balances ensures pro-rata distribution
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address tokenA,
        address tokenB,
        bool stable
    ) public view returns (uint reserveA, uint reserveB) {
        (address token0, ) = tradeHelper.sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1, ) = IPair(tradeHelper.pairFor(tokenA, tokenB, stable)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function _swap(uint[] memory amounts, ITradeHelper.Route[] memory routes, address _to) internal virtual {
        for (uint i = 0; i < routes.length; i++) {
            (address token0, ) = tradeHelper.sortTokens(routes[i].from, routes[i].to);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = routes[i].from == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < routes.length - 1
                ? tradeHelper.pairFor(routes[i + 1].from, routes[i + 1].to, routes[i + 1].stable)
                : _to;
            IPair(tradeHelper.pairFor(routes[i].from, routes[i].to, routes[i].stable)).swap(
                amount0Out,
                amount1Out,
                to,
                new bytes(0)
            );

            emit Swap(msg.sender, amounts[0], routes[i].from, to, routes[i].stable);
        }
    }

    function _swapSupportingFeeOnTransferTokens(ITradeHelper.Route[] calldata routes, address _to) internal virtual {
        for (uint i; i < routes.length; i++) {
            (address input, address output) = (routes[i].from, routes[i].to);
            (address token0, ) = tradeHelper.sortTokens(input, output);
            IPair pair = IPair(tradeHelper.pairFor(routes[i].from, routes[i].to, routes[i].stable));
            uint amountInput;
            uint amountOutput;
            {
                // scope to avoid stack too deep errors
                (uint reserve0, uint reserve1, ) = pair.getReserves();
                (uint reserveInput, ) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
                (amountOutput, ) = tradeHelper.getAmountOut(amountInput, input, output);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < routes.length - 1
                ? tradeHelper.pairFor(routes[i + 1].from, routes[i + 1].to, routes[i + 1].stable)
                : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));

            bool _stable = routes[i].stable;
            emit Swap(msg.sender, amountInput, input, to, _stable);
        }
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal returns (uint amountA, uint amountB) {
        require(amountADesired >= amountAMin);
        require(amountBDesired >= amountBMin);

        address _pair = tradeHelper.pairFor(tokenA, tokenB, stable);
        if (_pair == address(0)) {
            _pair = IPairFactory(factory).createPair(tokenA, tokenB, stable);
        }
        (uint reserveA, uint reserveB) = getReserves(tokenA, tokenB, stable);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = quoteLiquidity(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "Router: INSUFFICIENT_B_AMOUNT");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = quoteLiquidity(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, "Router: INSUFFICIENT_A_AMOUNT");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(
            tokenA,
            tokenB,
            stable,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );
        address pair = tradeHelper.pairFor(tokenA, tokenB, stable);
        TransferHelper._safeTransferFromERC20(tokenA, msg.sender, pair, amountA);
        TransferHelper._safeTransferFromERC20(tokenB, msg.sender, pair, amountB);
        liquidity = IPair(pair).mint(to);
    }

    function addLiquidityETH(
        address token,
        bool stable,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        (amountToken, amountETH) = _addLiquidity(
            token,
            address(wETH),
            stable,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = tradeHelper.pairFor(token, address(wETH), stable);
        TransferHelper._safeTransferFromERC20(token, msg.sender, pair, amountToken);
        wETH.deposit{value: amountETH}();
        assert(wETH.transfer(pair, amountETH));
        liquidity = IPair(pair).mint(to);
        // refund dust ETH, if any
        if (msg.value > amountETH) TransferHelper._safeTransferEther(msg.sender, msg.value - amountETH);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = tradeHelper.pairFor(tokenA, tokenB, stable);
        TransferHelper._safeTransferFromERC20(pair, msg.sender, pair, liquidity);
        (uint amount0, uint amount1) = IPair(pair).burn(to);
        (address token0, ) = tradeHelper.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, "Router: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "Router: INSUFFICIENT_B_AMOUNT");
    }

    function removeLiquidityETH(
        address token,
        bool stable,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool withFeeOnTransferTokens
    ) public ensure(deadline) returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            address(wETH),
            stable,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );

        uint out = withFeeOnTransferTokens ? IERC20(token).balanceOf(address(this)) : amountToken;
        TransferHelper._safeTransferERC20(token, to, out);
        wETH.withdraw(amountETH);
        TransferHelper._safeTransferEther(to, amountETH);
    }

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        bool stable,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB) {
        address pair = tradeHelper.pairFor(tokenA, tokenB, stable);
        {
            uint value = approveMax ? type(uint).max : liquidity;
            ERC20Permit(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        }

        (amountA, amountB) = removeLiquidity(tokenA, tokenB, stable, liquidity, amountAMin, amountBMin, to, deadline);
    }

    function removeLiquidityETHWithPermit(
        address token,
        bool stable,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool withFeeOnTransferTokens,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountETH) {
        address pair = tradeHelper.pairFor(token, address(wETH), stable);
        uint value = approveMax ? type(uint).max : liquidity;
        ERC20Permit(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(
            token,
            stable,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline,
            withFeeOnTransferTokens
        );
    }

    function swap(
        uint amountIn,
        uint amountOutMin,
        ITradeHelper.Route[] calldata routes,
        address to,
        uint deadline,
        bool withFeeOnTransferTokens
    ) external payable ensure(deadline) returns (uint[] memory amounts) {
        amounts = tradeHelper.getAmountsOut(amountIn, routes);
        if (!withFeeOnTransferTokens)
            require(amounts[amounts.length - 1] >= amountOutMin, "Router: INSUFFICIENT_OUTPUT_AMOUNT");
        address _pair = tradeHelper.pairFor(routes[0].from, routes[0].to, routes[0].stable);

        if (routes[0].from == address(wETH) || routes[0].from == ETHER) {
            require(amountIn == msg.value, "Router: AMOUNT_IN != MSG.VALUE");
            wETH.deposit{value: amounts[0]}();
            assert(wETH.transfer(_pair, amounts[0]));
            if (withFeeOnTransferTokens) {
                uint balanceBefore = IERC20(routes[routes.length - 1].to).balanceOf(to);
                _swapSupportingFeeOnTransferTokens(routes, to);
                require(
                    IERC20(routes[routes.length - 1].to).balanceOf(to).sub(balanceBefore) >= amountOutMin,
                    "Router: INSUFFICIENT_OUTPUT_AMOUNT"
                );
            } else _swap(amounts, routes, to);
        } else if (routes[routes.length - 1].to == address(wETH) || routes[routes.length - 1].to == ETHER) {
            TransferHelper._safeTransferFromERC20(routes[0].from, msg.sender, _pair, amounts[0]);
            uint sendAmount = amounts[amounts.length - 1];

            if (withFeeOnTransferTokens) {
                _swapSupportingFeeOnTransferTokens(routes, address(this));
                uint amountOut = IERC20(address(wETH)).balanceOf(address(this));
                require(amountOut >= amountOutMin, "Router: INSUFFICIENT_OUTPUT_AMOUNT");
                sendAmount = amountOut;
            } else _swap(amounts, routes, address(this));

            wETH.withdraw(sendAmount);
            TransferHelper._safeTransferEther(to, sendAmount);
        } else {
            TransferHelper._safeTransferFromERC20(routes[0].from, msg.sender, _pair, amounts[0]);

            if (withFeeOnTransferTokens) {
                uint balanceBefore = IERC20(routes[routes.length - 1].to).balanceOf(to);
                _swapSupportingFeeOnTransferTokens(routes, to);
                require(
                    IERC20(routes[routes.length - 1].to).balanceOf(to).sub(balanceBefore) >= amountOutMin,
                    "Router: INSUFFICIENT_OUTPUT_AMOUNT"
                );
            } else _swap(amounts, routes, to);
        }
    }
}
