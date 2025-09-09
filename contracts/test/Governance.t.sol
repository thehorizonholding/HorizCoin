// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/token/HorizCoinToken.sol";
import "../src/governance/HorizGovernor.sol";
import "../src/governance/HorizTimelock.sol";
import {IVotes} from "openzeppelin-contracts/contracts/governance/utils/IVotes.sol";

contract GovernanceTest is Test {
    HorizCoinToken token;
    HorizTimelock timelock;
    HorizGovernor governor;

    address deployer = address(0xD3PL0Y);
    address proposer = address(0xA11CE);
    address voter1 = address(0xBEEF);
    address voter2 = address(0xC0FFEE);

    uint256 constant MAX_SUPPLY = 1_000_000 ether;

    // Governance params (example)
    uint256 votingDelayBlocks = 1;      // 1 block
    uint256 votingPeriodBlocks = 10;    // 10 blocks
    uint256 proposalThresholdVotes = 0; // no threshold for test
    uint256 quorumPercent = 4;          // 4% quorum

    function setUp() public {
        vm.startPrank(deployer);
        token = new HorizCoinToken("HorizCoin", "HORIZ", MAX_SUPPLY);

        address[] memory proposers = new address[](1);
        proposers[0] = deployer;
        address[] memory executors = new address[](1);
        executors[0] = address(0); // open executor

        timelock = new HorizTimelock(
            2, // 2-second minDelay for test
            proposers,
            executors,
            deployer
        );

        governor = new HorizGovernor(
            IVotes(address(token)),
            timelock,
            votingDelayBlocks,
            votingPeriodBlocks,
            proposalThresholdVotes,
            quorumPercent
        );

        // Hand over token ownership to timelock for controlled mint (simulate post-setup)
        token.transferOwnership(address(timelock));

        // Set governor as proposer & executor roles in timelock
        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();
        bytes32 cancellerRole = timelock.CANCELLER_ROLE();

        timelock.grantRole(proposerRole, address(governor));
        timelock.grantRole(executorRole, address(0)); // anyone
        timelock.grantRole(cancellerRole, address(governor));
        vm.stopPrank();

        // Distribute voting power
        mintTo(voter1, 200_000 ether);
        mintTo(voter2, 150_000 ether);

        vm.prank(voter1);
        token.delegate(voter1);
        vm.prank(voter2);
        token.delegate(voter2);
    }

    function mintTo(address to, uint256 amount) internal {
        vm.startPrank(address(timelock));
        token.mint(to, amount);
        vm.stopPrank();
    }

    function testProposalLifecycle() public {
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        calldatas[0] = abi.encodeWithSelector(token.mint.selector, voter1, 10 ether);
        targets[0] = address(token);
        values[0] = 0;

        uint256 proposalId = governor.propose(
            targets,
            values,
            calldatas,
            "Proposal: mint 10 tokens to voter1"
        );

        vm.roll(block.number + votingDelayBlocks + 1);

        vm.prank(voter1);
        governor.castVote(proposalId, 1); // For
        vm.prank(voter2);
        governor.castVote(proposalId, 1);

        vm.roll(block.number + votingPeriodBlocks + 1);

        bytes32 descHash = keccak256(bytes("Proposal: mint 10 tokens to voter1"));
        governor.queue(targets, values, calldatas, descHash);

        vm.warp(block.timestamp + 2);

        governor.execute(targets, values, calldatas, descHash);

        assertEq(token.balanceOf(voter1), 200_000 ether + 10 ether);
    }
}