// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../interfaces/IGaugeFactory.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IMinter.sol";
import "../interfaces/IPairFactory.sol";
import "../interfaces/IVoter.sol";
import "../interfaces/IVotingEscrow.sol";
import "../Gauge.sol";
import "../Pair.sol";
import "../interfaces/IBribe.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "hardhat/console.sol";

interface IHypervisor {
    function pool() external view returns (address);
    function getTotalAmounts() external view returns (uint tot0, uint tot1);
}

contract PairHelper is Initializable {
    struct PairInfo {
        // pair info
        address pair_address; // pair contract address
        string symbol; // pair symbol
        string name; // pair name
        uint decimals; // pair decimals
        bool stable; // pair pool type (stable = false, means it's a variable type of pool)
        uint total_supply; // pair tokens supply
        // token pair info
        address token0; // pair 1st token address
        string token0_symbol; // pair 1st token symbol
        uint token0_decimals; // pair 1st token decimals
        uint reserve0; // pair 1st token reserves (nr. of tokens in the contract)
        uint claimable0; // claimable 1st token from fees (for unstaked positions)
        address token1; // pair 2nd token address
        string token1_symbol; // pair 2nd token symbol
        uint token1_decimals; // pair 2nd token decimals
        uint reserve1; // pair 2nd token reserves (nr. of tokens in the contract)
        uint claimable1; // claimable 2nd token from fees (for unstaked positions)
        // pairs gauge
        address gauge; // pair gauge address
        uint gauge_total_supply; // pair staked tokens (less/eq than/to pair total supply)
        address fee; // pair fees contract address
        address bribe; // pair bribes contract address
        uint emissions; // pair emissions (per second)
        address emissions_token; // pair emissions token address
        uint emissions_token_decimals; // pair emissions token decimals
        // User deposit
        uint account_lp_balance; // account LP tokens balance
        uint account_token0_balance; // account 1st token balance
        uint account_token1_balance; // account 2nd token balance
        uint account_gauge_balance; // account pair staked in gauge balance
        uint account_gauge_earned; // account earned emissions for this pair
    }

    struct TokenBribe {
        address token;
        uint8 decimals;
        uint256 amount;
        string symbol;
    }

    struct PairBribeEpoch {
        uint256 epochTimestamp;
        uint256 totalVotes;
        address pair;
        TokenBribe[] bribes;
    }

    uint256 public constant MAX_PAIRS = 1000;
    uint256 public constant MAX_EPOCHS = 200;
    uint256 public constant MAX_REWARDS = 16;
    uint256 public constant WEEK = 7 * 24 * 60 * 60;

    IPairFactory public pairFactory;
    IVoter public voter;

    address public underlyingToken;

    address public owner;

    event Owner(address oldOwner, address newOwner);
    event Voter(address oldVoter, address newVoter);
    // event WBF(address oldWBF, address newWBF);

    constructor() {}

    function initialize(address _voter) public initializer {
        owner = msg.sender;

        voter = IVoter(_voter);

        pairFactory = IPairFactory(voter.factory());
        underlyingToken = IVotingEscrow(voter.ve()).token();
    }

    // valid only for sAMM and vAMM
    function getAllPair(address _user, uint _quantity, uint _offset) external view returns (PairInfo[] memory pairs) {
        require(_quantity <= MAX_PAIRS, "too many pair");

        pairs = new PairInfo[](_quantity);

        uint i = _offset;
        uint totPairs = pairFactory.allPairsLength();
        address _pair;

        if (_quantity > totPairs) _quantity = totPairs;

        for (i; i < _offset + _quantity; i++) {
            _pair = pairFactory.allPairs(i);
            pairs[i - _offset] = _pairAddressToInfo(_pair, _user);
        }
    }

    function getPair(address _pair, address _account) external view returns (PairInfo memory _pairInfo) {
        _pairInfo = _pairAddressToInfo(_pair, _account);
    }

    function _pairAddressToInfo(address _pair, address _account) internal view returns (PairInfo memory _pairInfo) {
        Pair pair = Pair(_pair);

        address token_0 = pair.token0();
        address token_1 = pair.token1();
        uint r0;
        uint r1;

        // checkout is v2 or v3? if v3 then load algebra pool
        bool _type = IPairFactory(pairFactory).isPair(_pair);

        if (!_type) {
            // hypervisor totalAmounts = algebra.pool + gamma.unused
            (r0, r1) = IHypervisor(_pair).getTotalAmounts();
        } else {
            (r0, r1, ) = pair.getReserves();
        }

        Gauge _gauge = Gauge(voter.gauges(_pair));
        uint accountGaugeLPAmount = 0;
        uint earned = 0;
        uint gaugeTotalSupply = 0;
        uint emissions = 0;

        if (address(_gauge) != address(0)) {
            if (_account != address(0)) {
                accountGaugeLPAmount = _gauge.balanceOf(_account);
                earned = _gauge.earned(_account);
            } else {
                accountGaugeLPAmount = 0;
                earned = 0;
            }
            gaugeTotalSupply = _gauge.totalSupply();
            emissions = _gauge.rewardRate();
        }

        // Pair General Info
        _pairInfo.pair_address = _pair;
        _pairInfo.symbol = pair.symbol();
        _pairInfo.name = pair.name();
        _pairInfo.decimals = pair.decimals();
        _pairInfo.stable = !_type ? false : pair.isStable();
        _pairInfo.total_supply = pair.totalSupply();

        // Token0 Info
        _pairInfo.token0 = token_0;
        _pairInfo.token0_decimals = ERC20(token_0).decimals();
        _pairInfo.token0_symbol = ERC20(token_0).symbol();
        _pairInfo.reserve0 = r0;
        _pairInfo.claimable0 = _type == false ? 0 : pair.claimable0(_account);

        // Token1 Info
        _pairInfo.token1 = token_1;
        _pairInfo.token1_decimals = ERC20(token_1).decimals();
        _pairInfo.token1_symbol = ERC20(token_1).symbol();
        _pairInfo.reserve1 = r1;
        _pairInfo.claimable1 = _type == false ? 0 : pair.claimable1(_account);

        // Pair's gauge Info
        _pairInfo.gauge = address(_gauge);
        _pairInfo.gauge_total_supply = gaugeTotalSupply;
        _pairInfo.emissions = emissions;
        _pairInfo.emissions_token = underlyingToken;
        _pairInfo.emissions_token_decimals = ERC20(underlyingToken).decimals();

        // external address
        _pairInfo.fee = voter.internal_bribes(address(_gauge));
        _pairInfo.bribe = voter.external_bribes(address(_gauge));

        // Account Info
        _pairInfo.account_lp_balance = ERC20(_pair).balanceOf(_account);
        _pairInfo.account_token0_balance = ERC20(token_0).balanceOf(_account);
        _pairInfo.account_token1_balance = ERC20(token_1).balanceOf(_account);
        _pairInfo.account_gauge_balance = accountGaugeLPAmount;
        _pairInfo.account_gauge_earned = earned;
    }

    function getPairBribe(
        uint _quantity,
        uint _offset,
        address _pair
    ) external view returns (PairBribeEpoch[] memory _pairEpoch) {
        require(_quantity <= MAX_EPOCHS, "too many epochs");

        _pairEpoch = new PairBribeEpoch[](_quantity);

        address _gauge = voter.gauges(_pair);
        if (_gauge == address(0)) return _pairEpoch;

        IBribe bribe = IBribe(voter.external_bribes(_gauge));

        // check bribe and checkpoints exists
        if (address(0) == address(bribe)) return _pairEpoch;

        // scan bribes
        // get latest balance and epoch start for bribes
        uint _epochStartTimestamp = bribe.firstBribeTimestamp();

        // if 0 then no bribe created so far
        if (_epochStartTimestamp == 0) {
            return _pairEpoch;
        }

        uint _supply;
        uint i = _offset;

        for (i; i < _offset + _quantity; i++) {
            _supply = bribe.totalSupplyAt(_epochStartTimestamp);
            _pairEpoch[i - _offset].epochTimestamp = _epochStartTimestamp;
            _pairEpoch[i - _offset].pair = _pair;
            _pairEpoch[i - _offset].totalVotes = _supply;
            _pairEpoch[i - _offset].bribes = _bribe(_epochStartTimestamp, address(bribe));

            _epochStartTimestamp += WEEK;
        }
    }

    function _bribe(uint _ts, address _br) internal view returns (TokenBribe[] memory _tb) {
        IBribe _wb = IBribe(_br);
        uint tokenLen = _wb.rewardsListLength();

        _tb = new TokenBribe[](tokenLen);

        uint k;
        uint _rewPerEpoch;
        ERC20 _t;
        for (k = 0; k < tokenLen; k++) {
            _t = ERC20(_wb.rewardTokens(k));
            (uint256 periodFinish, uint256 rewardsPerEpoch, uint256 lastUpdateTime) = _wb.rewardData(address(_t), _ts);
            IBribe.Reward memory _reward = IBribe.Reward(periodFinish, rewardsPerEpoch, lastUpdateTime);
            _rewPerEpoch = _reward.rewardsPerEpoch;
            if (_rewPerEpoch > 0) {
                _tb[k].token = address(_t);
                _tb[k].symbol = _t.symbol();
                _tb[k].decimals = _t.decimals();
                _tb[k].amount = _rewPerEpoch;
            } else {
                _tb[k].token = address(_t);
                _tb[k].symbol = _t.symbol();
                _tb[k].decimals = _t.decimals();
                _tb[k].amount = 0;
            }
        }
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner, "not owner");
        require(_owner != address(0), "zeroAddr");
        owner = _owner;
        emit Owner(msg.sender, _owner);
    }

    function setVoter(address _voter) external {
        require(msg.sender == owner, "not owner");
        require(_voter != address(0), "zeroAddr");
        address _oldVoter = address(voter);
        voter = IVoter(_voter);

        // update variable depending on voter
        pairFactory = IPairFactory(voter.factory());
        underlyingToken = IVotingEscrow(voter.ve()).token();

        emit Voter(_oldVoter, _voter);
    }

    function left(address _pair, address _token) external view returns (uint256 _rewPerEpoch) {
        address _gauge = voter.gauges(_pair);
        IBribe bribe = IBribe(voter.internal_bribes(_gauge));

        uint256 _ts = bribe.getEpochStart();
        (uint256 periodFinish, uint256 rewardsPerEpoch, uint256 lastUpdateTime) = bribe.rewardData(_token, _ts);
        IBribe.Reward memory _reward = IBribe.Reward(periodFinish, rewardsPerEpoch, lastUpdateTime);
        _rewPerEpoch = _reward.rewardsPerEpoch;
    }
}
