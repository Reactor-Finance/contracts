// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IBribe.sol";
import "../interfaces/IPair.sol";
import "../interfaces/IPairFactory.sol";
import "../interfaces/IVoter.sol";
import "../interfaces/IVotingEscrow.sol";
import "../interfaces/IRewardsDistributor.sol";
import "./PairHelper.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "hardhat/console.sol";

contract veNFTHelper is Initializable {
    struct PairVote {
        address pair;
        uint256 weight;
    }

    struct veNFT {
        uint8 decimals;
        bool voted;
        uint256 attachments;
        uint256 id;
        uint128 amount;
        uint256 voting_amount;
        uint256 rebase_amount;
        uint256 lockEnd;
        uint256 vote_ts;
        PairVote[] votes;
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

    address public pairHelper;
    IPairFactory public pairFactory;

    address public owner;
    event Owner(address oldOwner, address newOwner);

    struct AllPairRewards {
        Reward[] rewards;
    }
    constructor() {}

    function initialize(address _voter, address _rewardDistro, address _pairHelper) public initializer {
        owner = msg.sender;

        pairHelper = _pairHelper;
        voter = IVoter(_voter);
        rewardDisitributor = IRewardsDistributor(_rewardDistro);

        require(rewardDisitributor.voting_escrow() == voter.ve(), "ve!=ve");

        ve = IVotingEscrow(rewardDisitributor.voting_escrow());
        underlyingToken = IVotingEscrow(ve).token();

        pairFactory = IPairFactory(voter.factory());
    }

    function getAllNFT(uint256 _amounts, uint256 _offset) external view returns (veNFT[] memory _veNFT) {
        require(_amounts <= MAX_RESULTS, "too many nfts");
        _veNFT = new veNFT[](_amounts);

        uint i = _offset;
        address _owner;

        for (i; i < _offset + _amounts; i++) {
            _owner = ve.ownerOf(i);
            // if id_i has owner read data
            if (_owner != address(0)) {
                _veNFT[i - _offset] = _getNFTFromId(i, _owner);
            }
        }
    }

    function getNFTFromId(uint256 id) external view returns (veNFT memory) {
        return _getNFTFromId(id, ve.ownerOf(id));
    }

    function getNFTFromAddress(address _user) external view returns (veNFT[] memory venft) {
        uint256 i = 0;
        uint256 _id;
        uint256 totNFTs = ve.balanceOf(_user);

        venft = new veNFT[](totNFTs);

        for (i; i < totNFTs; i++) {
            _id = ve.tokenOfOwnerByIndex(_user, i);
            if (_id != 0) {
                venft[i] = _getNFTFromId(_id, _user);
            }
        }
    }

    function _getNFTFromId(uint256 id, address _owner) internal view returns (veNFT memory venft) {
        if (_owner == address(0)) {
            return venft;
        }

        uint _totalPoolVotes = voter.poolVoteLength(id);
        PairVote[] memory votes = new PairVote[](_totalPoolVotes);

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

        venft.id = id;
        venft.account = _owner;
        venft.decimals = ve.decimals();
        venft.amount = uint128(_lockedBalance.amount);
        venft.voting_amount = ve.balanceOfNFT(id);
        venft.rebase_amount = rewardDisitributor.claimable(id);
        venft.lockEnd = _lockedBalance.end;
        venft.vote_ts = voter.lastVoted(id);
        venft.votes = votes;
        venft.token = ve.token();
        venft.tokenSymbol = ERC20(ve.token()).symbol();
        venft.tokenDecimals = ERC20(ve.token()).decimals();
        venft.voted = ve.voted(id);
        venft.attachments = ve.attachments(id);
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

        PairHelper.PairInfo memory _pairInfo = PairHelper(pairHelper).getPair(_pair, address(0));

        address externalBribe = _pairInfo.bribe;

        uint256 totBribeTokens = (externalBribe == address(0)) ? 0 : IBribe(externalBribe).rewardsListLength();

        uint bribeAmount;

        _reward = new Reward[](2 + totBribeTokens);

        address _gauge = (voter.gauges(_pair));

        if (_gauge == address(0)) {
            return _reward;
        }

        address t0 = _pairInfo.token0;
        address t1 = _pairInfo.token1;
        uint256 _feeToken0 = IBribe(_pairInfo.fee).earned(id, t0);
        uint256 _feeToken1 = IBribe(_pairInfo.fee).earned(id, t1);

        if (_feeToken0 > 0) {
            _reward[0] = Reward({
                id: id,
                pair: _pair,
                amount: _feeToken0,
                token: t0,
                symbol: ERC20(t0).symbol(),
                decimals: ERC20(t0).decimals(),
                fee: _pairInfo.fee,
                bribe: address(0)
            });
        }

        if (_feeToken1 > 0) {
            _reward[1] = Reward({
                id: id,
                pair: _pair,
                amount: _feeToken1,
                token: t1,
                symbol: ERC20(t1).symbol(),
                decimals: ERC20(t1).decimals(),
                fee: _pairInfo.fee,
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
            _token = IBribe(externalBribe).rewardTokens(k);
            bribeAmount = IBribe(externalBribe).earned(id, _token);

            _reward[2 + k] = Reward({
                id: id,
                pair: _pair,
                amount: bribeAmount,
                token: _token,
                symbol: ERC20(_token).symbol(),
                decimals: ERC20(_token).decimals(),
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

    function setRewardDistro(address _rewardDistro) external {
        require(msg.sender == owner);

        rewardDisitributor = IRewardsDistributor(_rewardDistro);
        require(rewardDisitributor.voting_escrow() == voter.ve(), "ve!=ve");

        ve = IVotingEscrow(rewardDisitributor.voting_escrow());
        underlyingToken = IVotingEscrow(ve).token();
    }

    function setpairHelper(address _pairInfo) external {
        require(msg.sender == owner);

        pairHelper = _pairInfo;
    }

    function setPairFactory(address _pairFactory) external {
        require(msg.sender == owner);
        pairFactory = IPairFactory(_pairFactory);
    }
}
