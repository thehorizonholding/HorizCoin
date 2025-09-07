// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title HorizGovernor
 * @notice Governor contract for HorizCoin governance with configurable parameters
 * @dev Implements OpenZeppelin Governor with timelock control and quorum requirements
 */
contract HorizGovernor is 
    Governor,
    GovernorSettings,
    GovernorCountingSimple,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorTimelockControl,
    ReentrancyGuard,
    AccessControl
{
    /// @notice Role for emergency actions
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");
    
    /// @notice Role for parameter updates
    bytes32 public constant PARAMETER_ADMIN_ROLE = keccak256("PARAMETER_ADMIN_ROLE");
    
    /// @notice Minimum votes required to create a proposal (in basis points of total supply)
    uint256 public proposalCreationMinVotesBps;
    
    /// @notice Maximum number of actions allowed in a single proposal
    uint256 public constant MAX_PROPOSAL_ACTIONS = 10;
    
    /// @notice Emitted when proposal creation minimum votes is updated
    event ProposalCreationMinVotesUpdated(uint256 oldBps, uint256 newBps);
    
    /// @notice Error thrown when proposal has too many actions
    error TooManyActions();
    
    /// @notice Error thrown when invalid basis points provided
    error InvalidBasisPoints();

    /**
     * @notice Constructs the HorizGovernor
     * @param _token Governance token contract
     * @param _timelock Timelock controller contract
     * @param _votingDelay Delay before voting starts (in blocks)
     * @param _votingPeriod Duration of voting period (in blocks)
     * @param _quorumFraction Quorum as fraction of total supply (in basis points)
     * @param _proposalCreationMinVotesBps Minimum votes to create proposal (in basis points)
     */
    constructor(
        IVotes _token,
        TimelockController _timelock,
        uint256 _votingDelay,
        uint256 _votingPeriod,
        uint256 _quorumFraction,
        uint256 _proposalCreationMinVotesBps
    )
        Governor("HorizGovernor")
        GovernorSettings(_votingDelay, _votingPeriod, 0) // proposalThreshold set to 0, managed separately
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(_quorumFraction)
        GovernorTimelockControl(_timelock)
    {
        if (_proposalCreationMinVotesBps > 10000) revert InvalidBasisPoints();
        proposalCreationMinVotesBps = _proposalCreationMinVotesBps;
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(EMERGENCY_ROLE, msg.sender);
        _grantRole(PARAMETER_ADMIN_ROLE, msg.sender);
        
        emit ProposalCreationMinVotesUpdated(0, _proposalCreationMinVotesBps);
    }

    /**
     * @notice Override proposal threshold to use basis points calculation
     */
    function proposalThreshold() public view override(Governor, GovernorSettings) returns (uint256) {
        uint256 totalSupply = token.getPastTotalSupply(block.number - 1);
        return (totalSupply * proposalCreationMinVotesBps) / 10000;
    }

    /**
     * @notice Updates the minimum votes required to create a proposal
     * @param _newBps New minimum votes in basis points
     */
    function setProposalCreationMinVotes(uint256 _newBps) external onlyRole(PARAMETER_ADMIN_ROLE) {
        if (_newBps > 10000) revert InvalidBasisPoints();
        uint256 oldBps = proposalCreationMinVotesBps;
        proposalCreationMinVotesBps = _newBps;
        emit ProposalCreationMinVotesUpdated(oldBps, _newBps);
    }

    /**
     * @notice Override to limit number of actions in a proposal
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override(Governor, IGovernor) returns (uint256) {
        if (targets.length > MAX_PROPOSAL_ACTIONS) revert TooManyActions();
        return super.propose(targets, values, calldatas, description);
    }

    /**
     * @notice Emergency cancel function for malicious proposals
     * @param proposalId ID of the proposal to cancel
     */
    function emergencyCancel(uint256 proposalId) external onlyRole(EMERGENCY_ROLE) {
        _cancel(proposalId);
    }

    /**
     * @notice Updates voting delay
     * @param newVotingDelay New voting delay in blocks
     */
    function setVotingDelay(uint256 newVotingDelay) public override onlyRole(PARAMETER_ADMIN_ROLE) {
        _setVotingDelay(newVotingDelay);
    }

    /**
     * @notice Updates voting period
     * @param newVotingPeriod New voting period in blocks
     */
    function setVotingPeriod(uint256 newVotingPeriod) public override onlyRole(PARAMETER_ADMIN_ROLE) {
        _setVotingPeriod(newVotingPeriod);
    }

    /**
     * @notice Updates quorum fraction
     * @param newQuorumNumerator New quorum numerator
     */
    function updateQuorumNumerator(uint256 newQuorumNumerator) external override onlyRole(PARAMETER_ADMIN_ROLE) {
        _updateQuorumNumerator(newQuorumNumerator);
    }

    // Required overrides
    function votingDelay() public view override(IGovernor, GovernorSettings) returns (uint256) {
        return super.votingDelay();
    }

    function votingPeriod() public view override(IGovernor, GovernorSettings) returns (uint256) {
        return super.votingPeriod();
    }

    function quorum(uint256 blockNumber)
        public
        view
        override(IGovernor, GovernorVotesQuorumFraction)
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
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _executor() internal view override(Governor, GovernorTimelockControl) returns (address) {
        return super._executor();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(Governor, GovernorTimelockControl, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}