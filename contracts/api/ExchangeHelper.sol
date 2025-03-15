pragma solidity ^0.8.0;

import "../interfaces/IPairFactory.sol";
import "../interfaces/IBribe.sol";
import "../Pair.sol";
import "../oracle/Oracle.sol";
import "../interfaces/ITradeHelper.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../Voter.sol";

contract ExchangeHelper is Initializable {
    using Address for address;

    IPairFactory public pairFactory;
    ITradeHelper public tradeHelper;
    Oracle public priceOracle;
    address public wETH;
    Voter public voter;

    // Selectors
    bytes4 public rewardPerTokenSelector = bytes4(keccak256(bytes("rewardPerToken(address,uint256)")));

    constructor() {}

    function initialize(address _tradeHelper, address _voter, address _priceOracle, address _wETH) public initializer {
        tradeHelper = ITradeHelper(_tradeHelper);
        pairFactory = IPairFactory(tradeHelper.factory());
        priceOracle = Oracle(_priceOracle);
        wETH = _wETH;
        voter = Voter(_voter);
    }

    function getTVLInUSDForPair(Pair pair) public view returns (uint256 token0VL, uint256 token1VL, uint256 totalVL) {
        (uint256 token0USD, ) = priceOracle.getAverageValueInUSD(pair.token0(), pair.reserve0());
        (uint256 token1USD, ) = priceOracle.getAverageValueInUSD(pair.token1(), pair.reserve1());
        token0VL = token0USD;
        token1VL = token1USD;
        totalVL = token0VL + token1VL;
    }

    function getTVLInUSDForAllPairs()
        external
        view
        returns (uint256 totalTVL, uint256[] memory tvls, Pair[] memory pairs)
    {
        uint256 pairsLength = pairFactory.allPairsLength();
        pairs = new Pair[](pairsLength);
        tvls = new uint256[](pairsLength);
        for (uint i; i < pairsLength; i++) {
            Pair pair = Pair(pairFactory.allPairs(i));
            (, , uint256 pairTVL) = getTVLInUSDForPair(pair);
            totalTVL += pairTVL;
            pairs[i] = pair;
            tvls[i] = pairTVL;
        }
    }

    /**
     *
     * @param pair Address of pair
     * @param from Start timestamp
     * @param to End timestamp
     * @return token0Volume
     * @return token1Volume
     */
    function getVolumeLockedPerTimeForPair(
        Pair pair,
        uint256 from,
        uint256 to
    )
        public
        view
        returns (
            uint256 token0Volume,
            uint256 token1Volume,
            uint256 token0VolumeUSD,
            uint256 token1VolumeUSD,
            uint256 totalVolumeUSD
        )
    {
        uint256 observationsLength = pair.observationLength();
        for (uint i = 1; i < observationsLength; i++) {
            (uint timestampCurrent, uint reserve0CumulativeCurrent, uint reserve1CumulativeCurrent) = pair.observations(
                i
            );
            (uint timestampPrevious, uint reserve0CumulativePrevious, uint reserve1CumulativePrevious) = pair
                .observations(i - 1);
            if (timestampPrevious >= from && timestampCurrent >= from && timestampCurrent <= to) {
                uint256 timeElapsed = timestampCurrent - timestampPrevious;
                uint256 _reserve0 = (reserve0CumulativeCurrent - reserve0CumulativePrevious) / timeElapsed;
                uint256 _reserve1 = (reserve1CumulativeCurrent - reserve1CumulativePrevious) / timeElapsed;

                token0Volume += _reserve0;
                token1Volume += _reserve1;
            }
        }

        (token0VolumeUSD, ) = priceOracle.getAverageValueInUSD(pair.token0(), token0Volume);
        (token1VolumeUSD, ) = priceOracle.getAverageValueInUSD(pair.token1(), token1Volume);
        totalVolumeUSD = token0VolumeUSD + token1VolumeUSD;
    }

    function getTotalVolumeLockedPerTime(
        uint256 from,
        uint256 to
    ) external view returns (uint256 tvlPerTime, uint256[] memory volumes, Pair[] memory pairs) {
        uint256 pairsLength = pairFactory.allPairsLength();
        pairs = new Pair[](pairsLength);
        volumes = new uint256[](pairsLength);
        for (uint i; i < pairsLength; i++) {
            Pair pair = Pair(pairFactory.allPairs(i));
            (, , , , uint256 pairTVLPerTime) = getVolumeLockedPerTimeForPair(pair, from, to);
            tvlPerTime += pairTVLPerTime;
            pairs[i] = pair;
            volumes[i] = pairTVLPerTime;
        }
    }

    function calculatePriceImpact(
        address tokenA,
        address tokenB,
        uint256 amountIn,
        bool multiHops
    ) external view returns (uint256) {
        uint256 amountInETH;
        if (multiHops) {
            (amountInETH, ) = tradeHelper.getAmountOut(amountIn, tokenA, wETH);
        }
        (uint256 amountOut, bool stable) = amountInETH > 0
            ? tradeHelper.getAmountOut(amountInETH, wETH, tokenB)
            : tradeHelper.getAmountOut(amountIn, tokenA, tokenB);
        address pair = amountInETH > 0
            ? tradeHelper.pairFor(wETH, tokenB, stable)
            : tradeHelper.pairFor(tokenA, tokenB, stable);
        //Get reserve
        if (pair != address(0)) {
            Pair p = Pair(pair);
            uint256 reserve = p.token0() == tokenB ? p.reserve0() : p.reserve1();
            uint256 projectedReserve = reserve - amountOut;
            return (amountOut * 10 ** 18) / projectedReserve;
        }
        return 0;
    }

    function getFeesInUSDForPair(Pair pair) public view returns (uint256 totalValue) {
        address gauge = voter.gauges(address(pair));

        totalValue = 0;

        if (gauge != address(0)) {
            IBribe bribe = IBribe(voter.internal_bribes(gauge));
            uint256 rewardTokensLength = bribe.rewardsListLength();
            for (uint i; i < rewardTokensLength; i++) {
                address rewardToken = bribe.rewardTokens(i);
                bytes memory data = address(bribe).functionStaticCall(
                    abi.encodeWithSelector(rewardPerTokenSelector, rewardToken, block.timestamp)
                );
                uint256 reward = abi.decode(data, (uint256));
                (uint256 rewardInUsd, ) = priceOracle.getAverageValueInUSD(rewardToken, reward);
                totalValue += rewardInUsd;
            }
        }
    }

    function getFeesInUSDForAllPairs()
        external
        view
        returns (uint256 totalValue, uint256[] memory fees, Pair[] memory pairs)
    {
        uint256 pairsLength = pairFactory.allPairsLength();
        pairs = new Pair[](pairsLength);
        fees = new uint256[](pairsLength);
        for (uint i; i < pairsLength; i++) {
            Pair pair = Pair(pairFactory.allPairs(i));
            uint256 pairFeeUSD = getFeesInUSDForPair(pair);
            totalValue += pairFeeUSD;
            pairs[i] = pair;
        }
    }
}
