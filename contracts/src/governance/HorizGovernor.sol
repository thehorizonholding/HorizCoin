// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Governor} from "openzeppelin-contracts/contracts/governance/Governor.sol";
import {GovernorSettings} from "openzeppelin-contracts/contracts/governance/extensions/GovernorSettings.sol";
import {GovernorCountingSimple} from "openzeppelin-contracts/contracts/governance/extensions/GovernorCountingSimple.sol";
import {GovernorVotes} from "openzeppelin-contracts/contracts/governance/extensions/GovernorVotes.sol";
import {GovernorVotesQuorumFraction} from "openzeppelin-contracts/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import {GovernorTimelockControl} from "openzeppelin-contracts/contracts/governance/extensions/GovernorTimelockControl.sol";
import {IVotes} from "openzeppelin-contracts/contracts/governance/utils/IVotes.sol";
import {HorizTimelock} from "./HorizTimelock.sol";

/// @title HorizGovernor
/// @notice On-chain governance contract controlling timelocked execution.
/// @dev Parameters are initially opinionated; can be adjusted via later governance upgrades.
contract HorizGovernor is
    Governor,
    GovernorSettings,
    GovernorCountingSimple,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorTimelockControl
{
    /// @param token Voting token (must implement IVotes — our ERC20Votes token).
    /// @param timelock Timelock controller instance that will execute queued proposals.
    /// @param votingDelayBlocks Delay (in blocks) before voting starts after proposal creation.
    /// @param votingPeriodBlocks Voting duration in blocks.
    /// @param proposalThresholdVotes Minimum number of votes required to create a proposal.
    /// @param quorumPercent Percent (e.g. 4 for 4%) of total supply required for quorum.
    constructor(
        IVotes token,
        HorizTimelock timelock,
        uint256 votingDelayBlocks,
        uint256 votingPeriodBlocks,
        uint256 proposalThresholdVotes,
        uint256 quorumPercent
    )
        Governor("HorizGovernor")
        GovernorSettings(votingDelayBlocks, votingPeriodBlocks, proposalThresholdVotes)
        GovernorVotes(token)
        GovernorVotesQuorumFraction(quorumPercent)
        GovernorTimelockControl(timelock)
    {}

    // --- Required overrides ---

    function quorum(uint256 blockNumber)
        public
        view
        override(Governor, GovernorVotesQuorumFraction)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    function state(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    )
        public
        override(Governor, IGovernor)
        returns (uint256)
    {
        return super.propose(targets, values, calldatas, description);
    }

    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    )
        internal
        override(Governor, GovernorTimelockControl)
        returns (uint256)
    {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor()
        internal
        view
        override(Governor, GovernorTimelockControl)
        returns (address)
    {
        return super._executor();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}