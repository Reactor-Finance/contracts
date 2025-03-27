pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./api/veNFTHelper.sol";

contract VoterActionsSingleton is Ownable, ReentrancyGuard {
    using Address for address;

    veNFTHelper public helper;

    struct TokenVoteCache {
        address[] internal_bribes;
        address[] external_bribes;
        address[][] internal_bribes_tokens;
        address[][] external_bribes_tokens;
    }

    mapping(uint256 => TokenVoteCache) private voteCache;

    bytes4 public voterClaimBribesSelector = bytes4(keccak256(bytes("claimBribes(address[],address[][],uint256)")));
    bytes4 public voterClaimFeesSelector = bytes4(keccak256(bytes("claimFees(address[],address[][],uint256)")));

    constructor(address _helper) Ownable(msg.sender) {
        setHelper(_helper);
    }

    function setHelper(address _helper) public onlyOwner {
        helper = veNFTHelper(_helper);
    }

    function _checkInRecord(address[] memory _record, address _item) internal pure returns (bool, int256) {
        for (uint i; i < _record.length; i++) {
            if (_record[i] == _item) return (true, int256(i));
        }
        return (false, -1);
    }

    function updateRecordForTokenId(uint256 tokenId) public {
        veNFTHelper.veNFT memory veNFT = helper.getNFTFromId(tokenId);
        veNFTHelper.PairVote[] memory votes = veNFT.votes;
        TokenVoteCache storage vc = voteCache[tokenId];

        // First loop
        for (uint i; i < votes.length; i++) {
            if (votes[i].pair != address(0)) {
                veNFTHelper.Reward[] memory pairRewards = helper.singlePairReward(tokenId, votes[i].pair);
                // Loop through rewards
                for (uint j; j < pairRewards.length; j++) {
                    if (pairRewards[j].fee != address(0)) {
                        address fee = pairRewards[j].fee;
                        (bool found, int256 index) = _checkInRecord(vc.internal_bribes, fee);
                        if (!found) {
                            vc.internal_bribes.push(fee);
                        }
                        uint256 feeRewardsLength = IBribe(fee).rewardsListLength();
                        address[] memory _rewardTokens = new address[](feeRewardsLength);
                        for (uint k; k < feeRewardsLength; k++) {
                            _rewardTokens[k] = IBribe(fee).rewardTokens(k);
                        }
                        if (index == -1) {
                            vc.internal_bribes_tokens.push(_rewardTokens);
                        } else {
                            vc.internal_bribes_tokens[uint256(index)] = _rewardTokens;
                        }
                    }
                    if (pairRewards[j].bribe != address(0)) {
                        address bribe = pairRewards[j].bribe;
                        (bool found, int256 index) = _checkInRecord(vc.external_bribes, bribe);
                        if (!found) {
                            vc.external_bribes.push(bribe);
                        }
                        uint256 bribeRewardsLength = IBribe(bribe).rewardsListLength();
                        address[] memory _rewardTokens = new address[](bribeRewardsLength);
                        for (uint k; k < bribeRewardsLength; k++) {
                            _rewardTokens[k] = IBribe(bribe).rewardTokens(k);
                        }
                        if (index == -1) {
                            vc.external_bribes_tokens.push(_rewardTokens);
                        } else {
                            vc.external_bribes_tokens[uint256(index)] = _rewardTokens;
                        }
                    }
                }
            }
        }
    }

    function _claimRewardsForTokenId(uint256 tokenId) internal {
        updateRecordForTokenId(tokenId);
        TokenVoteCache memory vc = voteCache[tokenId];
        address voter = address(helper.voter());
        voter.functionCall(
            abi.encodeWithSelector(voterClaimBribesSelector, vc.external_bribes, vc.external_bribes_tokens, tokenId)
        );
        voter.functionCall(
            abi.encodeWithSelector(voterClaimFeesSelector, vc.internal_bribes, vc.internal_bribes_tokens, tokenId)
        );
    }

    function claimRewardsForTokenId(uint256 tokenId) public nonReentrant {
        _claimRewardsForTokenId(tokenId);
    }

    function claimRewardsForTokenIds(uint256[] memory tokenIds) external nonReentrant {
        for (uint i; i < tokenIds.length; i++) {
            _claimRewardsForTokenId(tokenIds[i]);
        }
    }
}
