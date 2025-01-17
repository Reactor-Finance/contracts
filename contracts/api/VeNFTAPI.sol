// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../libraries/Math.sol";
import "../interfaces/IBribeAPI.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IPair.sol";
import "../interfaces/IPairFactory.sol";
import "../interfaces/IVoter.sol";
import "../interfaces/IVotingEscrow.sol";
import "../interfaces/IRewardsDistributor.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "hardhat/console.sol";

interface IPairAPI {
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

    function getPair(address _pair, address _account) external view returns (PairInfo memory _PairInfo);

    function pair_factory() external view returns (address);
}

contract VeNFTAPI is Initializable {
    struct PairVotes {
        address pair;
        uint256 weight;
    }

    struct VeNFT {
        uint8 decimals;
        bool voted;
        uint256 attachments;
        uint256 id;
        uint128 amount;
        uint256 voting_amount;
        uint256 rebase_amount;
        uint256 lockEnd;
        uint256 vote_ts;
        PairVotes[] votes;
        address account;
        address token;
        string tokenSymbol;
        uint256 tokenDecimals;
    }

    struct Reward {
        uint256 id;
        uint256 amount;
        uint8 decimals;
        address pair;
        address token;
        address fee;
        address bribe;
        string symbol;
    }

    uint256 public constant MAX_RESULTS = 1000;
    uint256 public constant MAX_PAIRS = 30;

    IVoter public voter;
    address public underlyingToken;

    IVotingEscrow public ve;
    IRewardsDistributor public rewardDisitributor;

    address public pairAPI;
    IPairFactory public pairFactory;

    address public owner;
    event Owner(address oldOwner, address newOwner);

    struct AllPairRewards {
        Reward[] rewards;
    }
    constructor() {}

    function initialize(address _voter, address _rewarddistro, address _pairApi) public initializer {
        owner = msg.sender;

        pairAPI = _pairApi;
        voter = IVoter(_voter);
        rewardDisitributor = IRewardsDistributor(_rewarddistro);

        require(rewardDisitributor.voting_escrow() == voter.ve(), "ve!=ve");

        ve = IVotingEscrow(rewardDisitributor.voting_escrow());
        underlyingToken = IVotingEscrow(ve).token();

        pairFactory = IPairFactory(voter.factory());
    }

    function getAllNFT(uint256 _amounts, uint256 _offset) external view returns (VeNFT[] memory _VeNFT) {
        require(_amounts <= MAX_RESULTS, "too many nfts");
        _VeNFT = new VeNFT[](_amounts);

        uint i = _offset;
        address _owner;

        for (i; i < _offset + _amounts; i++) {
            _owner = ve.ownerOf(i);
            // if id_i has owner read data
            if (_owner != address(0)) {
                _VeNFT[i - _offset] = _getNFTFromId(i, _owner);
            }
        }
    }

    function getNFTFromId(uint256 id) external view returns (VeNFT memory) {
        return _getNFTFromId(id, ve.ownerOf(id));
    }

    function getNFTFromAddress(address _user) external view returns (VeNFT[] memory veNFT) {
        uint256 i = 0;
        uint256 _id;
        uint256 totNFTs = ve.balanceOf(_user);

        veNFT = new VeNFT[](totNFTs);

        for (i; i < totNFTs; i++) {
            _id = ve.tokenOfOwnerByIndex(_user, i);
            if (_id != 0) {
                veNFT[i] = _getNFTFromId(_id, _user);
            }
        }
    }

    function _getNFTFromId(uint256 id, address _owner) internal view returns (VeNFT memory veNFT) {
        if (_owner == address(0)) {
            return veNFT;
        }

        uint _totalPoolVotes = voter.poolVoteLength(id);
        PairVotes[] memory votes = new PairVotes[](_totalPoolVotes);

        IVotingEscrow.LockedBalance memory _lockedBalance;
        _lockedBalance = ve.locked(id);

        uint k;
        uint256 _poolWeight;
        address _votedPair;

        for (k = 0; k < _totalPoolVotes; k++) {
            _votedPair = voter.poolVote(id, k);
            if (_votedPair == address(0)) {
                break;
            }
            _poolWeight = voter.votes(id, _votedPair);
            votes[k].pair = _votedPair;
            votes[k].weight = _poolWeight;
        }

        veNFT.id = id;
        veNFT.account = _owner;
        veNFT.decimals = ve.decimals();
        veNFT.amount = uint128(_lockedBalance.amount);
        veNFT.voting_amount = ve.balanceOfNFT(id);
        veNFT.rebase_amount = rewardDisitributor.claimable(id);
        veNFT.lockEnd = _lockedBalance.end;
        veNFT.vote_ts = voter.lastVoted(id);
        veNFT.votes = votes;
        veNFT.token = ve.token();
        veNFT.tokenSymbol = IERC20(ve.token()).symbol();
        veNFT.tokenDecimals = IERC20(ve.token()).decimals();
        veNFT.voted = ve.voted(id);
        veNFT.attachments = ve.attachments(id);
    }

    // used only for sAMM and vAMM
    function allPairRewards(
        uint256 _amount,
        uint256 _offset,
        uint256 id
    ) external view returns (AllPairRewards[] memory rewards) {
        rewards = new AllPairRewards[](MAX_PAIRS);

        uint256 totalPairs = pairFactory.allPairsLength();

        uint i = _offset;
        address _pair;
        for (i; i < _offset + _amount; i++) {
            if (i >= totalPairs) {
                break;
            }
            _pair = pairFactory.allPairs(i);
            rewards[i].rewards = _pairReward(_pair, id);
        }
    }

    function singlePairReward(uint256 id, address _pair) external view returns (Reward[] memory _reward) {
        return _pairReward(_pair, id);
    }

    function _pairReward(address _pair, uint256 id) internal view returns (Reward[] memory _reward) {
        if (_pair == address(0)) {
            return _reward;
        }

        IPairAPI.PairInfo memory _pairApi = IPairAPI(pairAPI).getPair(_pair, address(0));

        address externalBribe = _pairApi.bribe;

        uint256 totBribeTokens = (externalBribe == address(0)) ? 0 : IBribeAPI(externalBribe).rewardsListLength();

        uint bribeAmount;

        _reward = new Reward[](2 + totBribeTokens);

        address _gauge = (voter.gauges(_pair));

        if (_gauge == address(0)) {
            return _reward;
        }

        address t0 = _pairApi.token0;
        address t1 = _pairApi.token1;
        uint256 _feeToken0 = IBribeAPI(_pairApi.fee).earned(id, t0);
        uint256 _feeToken1 = IBribeAPI(_pairApi.fee).earned(id, t1);

        if (_feeToken0 > 0) {
            _reward[0] = Reward({
                id: id,
                pair: _pair,
                amount: _feeToken0,
                token: t0,
                symbol: IERC20(t0).symbol(),
                decimals: IERC20(t0).decimals(),
                fee: _pairApi.fee,
                bribe: address(0)
            });
        }

        if (_feeToken1 > 0) {
            _reward[1] = Reward({
                id: id,
                pair: _pair,
                amount: _feeToken1,
                token: t1,
                symbol: IERC20(t1).symbol(),
                decimals: IERC20(t1).decimals(),
                fee: _pairApi.fee,
                bribe: address(0)
            });
        }

        //externalBribe point to Bribes.sol
        if (externalBribe == address(0)) {
            return _reward;
        }

        uint k = 0;
        address _token;

        for (k; k < totBribeTokens; k++) {
            _token = IBribeAPI(externalBribe).rewardTokens(k);
            bribeAmount = IBribeAPI(externalBribe).earned(id, _token);

            _reward[2 + k] = Reward({
                id: id,
                pair: _pair,
                amount: bribeAmount,
                token: _token,
                symbol: IERC20(_token).symbol(),
                decimals: IERC20(_token).decimals(),
                fee: address(0),
                bribe: externalBribe
            });
        }

        return _reward;
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner, "not owner");
        require(_owner != address(0), "zeroAddr");
        owner = _owner;
        emit Owner(msg.sender, _owner);
    }

    function setVoter(address _voter) external {
        require(msg.sender == owner);

        voter = IVoter(_voter);
    }

    function setRewardDistro(address _rewarddistro) external {
        require(msg.sender == owner);

        rewardDisitributor = IRewardsDistributor(_rewarddistro);
        require(rewardDisitributor.voting_escrow() == voter.ve(), "ve!=ve");

        ve = IVotingEscrow(rewardDisitributor.voting_escrow());
        underlyingToken = IVotingEscrow(ve).token();
    }

    function setPairAPI(address _pairApi) external {
        require(msg.sender == owner);

        pairAPI = _pairApi;
    }

    function setPairFactory(address _pairFactory) external {
        require(msg.sender == owner);
        pairFactory = IPairFactory(_pairFactory);
    }
}
