// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Governor} from "@openzeppelin/contracts/governance/Governor.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {GovernorCountingSimple} from "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import {GovernorVotes} from "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import {GovernorVotesQuorumFraction} from "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";

contract ReactorGovernor is Governor, GovernorCountingSimple, GovernorVotes, GovernorVotesQuorumFraction {
    address public team;
    uint256 public constant MAX_PROPOSAL_NUMERATOR = 100; // max 10%
    uint256 public constant PROPOSAL_DENOMINATOR = 1000;
    uint256 public proposalNumerator = 2; // start at 0.02%

    constructor(
        IVotes _ve
    )
        Governor("Reactor Governor")
        GovernorVotes(_ve)
        GovernorVotesQuorumFraction(4) // 4%
    {
        team = msg.sender;
    }

    function votingDelay() public pure override(Governor) returns (uint256) {
        return 15 minutes; // 1 block
    }

    function votingPeriod() public pure override(Governor) returns (uint256) {
        return 1 weeks;
    }

    function setTeam(address newTeam) external {
        require(msg.sender == team, "not team");
        team = newTeam;
    }

    function setProposalNumerator(uint256 numerator) external {
        require(msg.sender == team, "not team");
        require(numerator <= MAX_PROPOSAL_NUMERATOR, "numerator too high");
        proposalNumerator = numerator;
    }

    function proposalThreshold() public view override(Governor) returns (uint256) {
        return (token().getPastTotalSupply(block.timestamp) * proposalNumerator) / PROPOSAL_DENOMINATOR;
    }
}
