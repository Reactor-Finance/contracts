// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IBribe.sol";
import "../interfaces/IGauge.sol";
import "../interfaces/IGaugeFactory.sol";
import "../interfaces/IMinter.sol";
import "../interfaces/IPair.sol";
import "../interfaces/IPairFactory.sol";
import "../interfaces/IVotingEscrow.sol";
import "../interfaces/IVoter.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "hardhat/console.sol";

contract RewardHelper is Initializable {
    IPairFactory public pairFactory;
    IVoter public voter;
    address public underlyingToken;
    address public owner;

    struct Bribe {
        address[] tokens;
        string[] symbols;
        uint[] decimals;
        uint[] amounts;
    }

    struct Rewards {
        Bribe[] bribes;
    }

    constructor() {}

    function initialize(address _voter) public initializer {
        owner = msg.sender;
        voter = IVoter(_voter);
        pairFactory = IPairFactory(voter.factory());
        underlyingToken = IVotingEscrow(voter.ve()).token();
    }

    /// @notice Get the rewards available the next epoch.
    function getExpectedClaimForNextEpoch(
        uint tokenId,
        address[] memory pairs
    ) external view returns (Rewards[] memory) {
        uint i;
        uint len = pairs.length;
        address _gauge;
        address _bribe;

        Bribe[] memory _tempReward = new Bribe[](2);
        Rewards[] memory _rewards = new Rewards[](len);

        //external
        for (i = 0; i < len; i++) {
            _gauge = voter.gauges(pairs[i]);

            // get external
            _bribe = voter.external_bribes(_gauge);
            _tempReward[0] = _getEpochRewards(tokenId, _bribe);

            // get internal
            _bribe = voter.internal_bribes(_gauge);
            _tempReward[1] = _getEpochRewards(tokenId, _bribe);
            _rewards[i].bribes = _tempReward;
        }

        return _rewards;
    }

    function _getEpochRewards(uint tokenId, address _bribe) internal view returns (Bribe memory _rewards) {
        uint totTokens = IBribe(_bribe).rewardsListLength();
        uint[] memory _amounts = new uint[](totTokens);
        address[] memory _tokens = new address[](totTokens);
        string[] memory _symbol = new string[](totTokens);
        uint[] memory _decimals = new uint[](totTokens);
        uint ts = IBribe(_bribe).getEpochStart();
        uint i = 0;
        uint _supply = IBribe(_bribe).totalSupplyAt(ts);
        uint _balance = IBribe(_bribe).balanceOfAt(tokenId, ts);
        address _token;
        IBribe.Reward memory _reward;

        for (i; i < totTokens; i++) {
            _token = IBribe(_bribe).rewardTokens(i);
            _tokens[i] = _token;
            if (_balance == 0) {
                _amounts[i] = 0;
                _symbol[i] = "";
                _decimals[i] = 0;
            } else {
                _symbol[i] = ERC20(_token).symbol();
                _decimals[i] = ERC20(_token).decimals();
                (uint256 periodFinish, uint256 rewardsPerEpoch, uint256 lastUpdateTime) = IBribe(_bribe).rewardData(
                    _token,
                    ts
                );
                _reward = IBribe.Reward(periodFinish, rewardsPerEpoch, lastUpdateTime);
                _amounts[i] = (((_reward.rewardsPerEpoch * 1e18) / _supply) * _balance) / 1e18;
            }
        }

        _rewards.tokens = _tokens;
        _rewards.amounts = _amounts;
        _rewards.symbols = _symbol;
        _rewards.decimals = _decimals;
    }

    // read all the bribe available for a pair
    function getPairBribe(address pair) external view returns (Bribe[] memory) {
        address _gauge;
        address _bribe;

        Bribe[] memory _tempReward = new Bribe[](2);

        // get external
        _gauge = voter.gauges(pair);
        _bribe = voter.external_bribes(_gauge);
        _tempReward[0] = _getNextEpochRewards(_bribe);

        // get internal
        _bribe = voter.internal_bribes(_gauge);
        _tempReward[1] = _getNextEpochRewards(_bribe);
        return _tempReward;
    }

    function _getNextEpochRewards(address _bribe) internal view returns (Bribe memory _rewards) {
        uint totTokens = IBribe(_bribe).rewardsListLength();
        uint[] memory _amounts = new uint[](totTokens);
        address[] memory _tokens = new address[](totTokens);
        string[] memory _symbol = new string[](totTokens);
        uint[] memory _decimals = new uint[](totTokens);
        uint ts = IBribe(_bribe).getNextEpochStart();
        uint i = 0;
        address _token;
        IBribe.Reward memory _reward;

        for (i; i < totTokens; i++) {
            _token = IBribe(_bribe).rewardTokens(i);
            _tokens[i] = _token;
            _symbol[i] = ERC20(_token).symbol();
            _decimals[i] = ERC20(_token).decimals();
            (uint256 periodFinish, uint256 rewardsPerEpoch, uint256 lastUpdateTime) = IBribe(_bribe).rewardData(
                _token,
                ts
            );
            _reward = IBribe.Reward(periodFinish, rewardsPerEpoch, lastUpdateTime);
            _amounts[i] = _reward.rewardsPerEpoch;
        }

        _rewards.tokens = _tokens;
        _rewards.amounts = _amounts;
        _rewards.symbols = _symbol;
        _rewards.decimals = _decimals;
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner, "not owner");
        require(_owner != address(0), "zeroAddr");
        owner = _owner;
    }

    function setVoter(address _voter) external {
        require(msg.sender == owner, "not owner");
        require(_voter != address(0), "zeroAddr");
        voter = IVoter(_voter);
        // update variable depending on voter
        pairFactory = IPairFactory(voter.factory());
        underlyingToken = IVotingEscrow(voter.ve()).token();
    }
}
