# HorizCoin Governance

## Overview

HorizCoin implements a comprehensive on-chain governance system based on OpenZeppelin's Governor framework, enhanced with custom features for the HorizCoin ecosystem. The governance system controls all critical aspects of the protocol including treasury operations, parameter updates, and system upgrades.

## Governance Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Governance Flow                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Token Holders                                             │
│       │                                                    │
│       │ delegate voting power                              │
│       ▼                                                    │
│  ┌──────────────┐                                          │
│  │   Voters     │                                          │
│  │              │                                          │
│  │ • Delegates  │──┐                                       │
│  │ • Direct     │  │                                       │
│  └──────────────┘  │                                       │
│                     │                                      │
│                     │ create proposals                     │
│                     ▼                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Governor   │──│  Timelock    │──│   Execution  │      │
│  │              │  │              │  │              │      │
│  │ • Proposals  │  │ • 2 day delay│  │ • Treasury   │      │
│  │ • Voting     │  │ • Security   │  │ • Parameters │      │
│  │ • Execution  │  │ • Cancel     │  │ • Modules    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

## Governance Parameters

### Core Parameters
- **Voting Delay**: 7,200 blocks (~1 day at 12s block time)
- **Voting Period**: 50,400 blocks (~7 days at 12s block time)
- **Quorum**: 4% (400 basis points) of total token supply
- **Proposal Threshold**: 0% initially (can be raised via governance)
- **Timelock Delay**: 2 days (172,800 seconds)

### Parameter Rationale

#### Voting Delay (1 Day)
- Provides time for proposal review and analysis
- Allows token holders to delegate if needed
- Prevents flash governance attacks

#### Voting Period (7 Days)
- Sufficient time for community participation
- Accommodates different time zones and schedules
- Balances deliberation with execution speed

#### Quorum (4%)
- Ensures meaningful participation threshold
- Prevents governance by small minorities
- Adjustable through governance process

#### Timelock Delay (2 Days)
- Security buffer for critical operations
- Time for emergency response if needed
- Industry standard for DeFi governance

## Governance Process

### 1. Proposal Creation

#### Requirements
- Must hold minimum voting power (initially 0, configurable)
- Maximum 10 actions per proposal
- Valid target contracts and function calls

#### Proposal Structure
```solidity
struct Proposal {
    uint256 id;
    address proposer;
    address[] targets;     // Contract addresses to call
    uint256[] values;      // ETH values for each call
    bytes[] calldatas;     // Function call data
    uint256 startBlock;    // When voting starts
    uint256 endBlock;      // When voting ends
    string description;    // Human-readable description
}
```

#### Creating a Proposal
```solidity
// Example: Update emission rate
address[] memory targets = new address[](1);
uint256[] memory values = new uint256[](1);
bytes[] memory calldatas = new bytes[](1);

targets[0] = address(treasury);
values[0] = 0;
calldatas[0] = abi.encodeWithSignature("setEmissionRate(uint256)", 1000e18);

uint256 proposalId = governor.propose(
    targets,
    values,
    calldatas,
    "Update emission rate to 1000 tokens per block"
);
```

### 2. Voting Process

#### Voting Options
- **For (1)**: Support the proposal
- **Against (0)**: Oppose the proposal  
- **Abstain (2)**: Abstain from voting (counts toward quorum)

#### Voting Power
- Based on token balance at proposal creation block
- Includes delegated voting power
- Snapshot prevents manipulation after proposal

#### Voting Methods
```solidity
// Direct voting
governor.castVote(proposalId, support);

// Voting with reason
governor.castVoteWithReason(proposalId, support, "Reason for vote");

// Voting by signature (meta-transaction)
governor.castVoteBySig(proposalId, support, v, r, s);
```

### 3. Proposal States

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Pending   │───▶│   Active    │───▶│ Succeeded   │
└─────────────┘    └─────────────┘    └─────────────┘
                          │                   │
                          ▼                   ▼
                   ┌─────────────┐    ┌─────────────┐
                   │  Defeated   │    │   Queued    │
                   └─────────────┘    └─────────────┘
                                             │
                                             ▼
                                      ┌─────────────┐
                                      │  Executed   │
                                      └─────────────┘
```

- **Pending**: Waiting for voting delay to pass
- **Active**: Currently accepting votes
- **Succeeded**: Passed quorum and majority thresholds
- **Defeated**: Failed to meet requirements
- **Queued**: Succeeded and queued in timelock
- **Executed**: Successfully executed

### 4. Execution

#### Timelock Queue
```solidity
// After proposal succeeds, it must be queued
governor.queue(proposalId);

// After timelock delay, it can be executed
governor.execute(proposalId);
```

#### Automatic Execution
- Anyone can execute a queued proposal after timelock delay
- Execution attempts the proposed actions in order
- Failed actions cause the entire proposal to revert

## Governance Scenarios

### 1. Treasury Operations

#### Transferring Funds
```solidity
// Proposal to fund a project
targets = [address(treasury)];
values = [0];
calldatas = [abi.encodeWithSignature(
    "transferTokens(address,address,uint256)",
    address(token),
    projectAddress,
    fundingAmount
)];
```

#### Setting Emission Rate
```solidity
// Update token emission rate
targets = [address(treasury)];
values = [0];
calldatas = [abi.encodeWithSignature(
    "setEmissionRate(uint256)",
    newEmissionRate
)];
```

### 2. Parameter Updates

#### Governance Parameters
```solidity
// Update voting period
targets = [address(governor)];
values = [0];
calldatas = [abi.encodeWithSignature(
    "setVotingPeriod(uint256)",
    newVotingPeriod
)];
```

#### System Parameters
```solidity
// Update system parameter
targets = [address(parameterModule)];
values = [0];
calldatas = [abi.encodeWithSignature(
    "setParameter(string,uint256)",
    "maxTransferAmount",
    newMaxAmount
)];
```

### 3. Emergency Actions

#### Emergency Pause
```solidity
// Emergency pause (if PauseModule deployed)
targets = [address(pauseModule)];
values = [0];
calldatas = [abi.encodeWithSignature("emergencyPause()")];
```

#### Role Management
```solidity
// Grant emergency role
targets = [address(treasury)];
values = [0];
calldatas = [abi.encodeWithSignature(
    "grantRole(bytes32,address)",
    EMERGENCY_ROLE,
    emergencyResponder
)];
```

## Delegation System

### Voting Power Delegation

#### Self-Delegation
```solidity
// Token holders must delegate to participate in governance
token.delegate(msg.sender); // Self-delegate
```

#### Delegate to Others
```solidity
// Delegate voting power to trusted representative
token.delegate(delegateAddress);
```

#### Delegation by Signature
```solidity
// Gasless delegation using permit
token.delegateBySig(delegatee, nonce, expiry, v, r, s);
```

### Delegate Responsibilities
- Vote on behalf of delegators
- Communicate voting rationale
- Stay informed on proposals
- Act in best interest of protocol

## Governance Security

### Security Mechanisms

#### Timelock Protection
- 2-day delay for all critical operations
- Prevents immediate execution of malicious proposals
- Allows time for emergency response

#### Emergency Cancellation
```solidity
// Emergency role can cancel malicious proposals
governor.emergencyCancel(proposalId);
```

#### Proposal Limits
- Maximum 10 actions per proposal
- Prevents complex attack vectors
- Ensures proposal clarity

#### Flash Loan Protection
- Voting power based on historical snapshots
- Prevents same-block manipulation
- Delegation delay mechanisms

### Attack Vectors & Mitigations

#### Flash Governance Attacks
- **Mitigation**: Voting delay and snapshot-based voting power
- **Detection**: Monitor large token movements before proposals

#### Governance Capture
- **Mitigation**: Broad token distribution and delegation incentives
- **Detection**: Monitor voting power concentration

#### Malicious Proposals
- **Mitigation**: Emergency cancellation and timelock delay
- **Response**: Emergency pause and community alert

## Governance Participation

### For Token Holders

#### Getting Started
1. Acquire HORIZ tokens
2. Delegate voting power (to self or representative)
3. Monitor governance forum and proposals
4. Participate in voting

#### Best Practices
- Research proposals thoroughly
- Consider long-term protocol health
- Communicate with other community members
- Vote consistently

### For Delegates

#### Becoming a Delegate
1. Announce delegation candidacy
2. Communicate governance philosophy
3. Build trust with token holders
4. Maintain active participation

#### Delegate Guidelines
- Vote on all proposals
- Provide voting rationale
- Engage with community
- Maintain transparency

## Governance Tools

### On-Chain Tools
- **Governor Contract**: Core governance logic
- **Timelock**: Execution delay and security
- **Parameter Module**: System configuration

### Off-Chain Tools
- **Governance Dashboard**: Proposal tracking and voting
- **Discussion Forum**: Community debate and analysis
- **Voting Analytics**: Participation metrics and trends

### Integration APIs
```solidity
// Get voting power at specific block
uint256 votingPower = token.getPastVotes(account, blockNumber);

// Get proposal state
ProposalState state = governor.state(proposalId);

// Get proposal details
(
    uint256 id,
    address proposer,
    uint256 eta,
    uint256 startBlock,
    uint256 endBlock,
    uint256 forVotes,
    uint256 againstVotes,
    uint256 abstainVotes,
    bool canceled,
    bool executed
) = governor.proposals(proposalId);
```

## Governance Evolution

### Upgrading Governance
- Deploy new governor contract
- Propose migration through current governance
- Transfer roles and permissions
- Sunset old governance

### Parameter Adjustments
- Regularly review governance parameters
- Adjust based on participation metrics
- Consider ecosystem changes
- Maintain security properties

## Emergency Procedures

### Emergency Response Team
- Multi-signature emergency responders
- Authority to pause operations
- Limited time emergency powers
- Governance oversight and accountability

### Emergency Scenarios
1. **Smart Contract Bug**: Emergency pause and funds protection
2. **Governance Attack**: Proposal cancellation and investigation
3. **Economic Attack**: Parameter adjustment and stabilization
4. **Oracle Failure**: Fallback mechanisms and manual intervention

### Communication Protocol
- Immediate public disclosure
- Technical analysis and response plan
- Community updates and coordination
- Post-incident review and improvements

## Governance Metrics

### Participation Metrics
- Voter turnout percentage
- Proposal success rate
- Average voting power per proposal
- Delegate concentration

### Health Indicators
- Quorum achievement rate
- Proposal quality scores
- Community engagement levels
- Emergency activation frequency

### Success Criteria
- Consistent quorum achievement (>4%)
- Diverse participation (>100 unique voters)
- Timely execution (95% of queued proposals)
- Security incidents (target: 0)

## Future Enhancements

### Planned Improvements
- **Quadratic Voting**: Reduce whale influence
- **Liquid Democracy**: Dynamic delegation
- **Conviction Voting**: Time-weighted preferences
- **Cross-Chain Governance**: Multi-chain coordination

### Research Areas
- Governance attack prevention
- Participation incentive mechanisms
- Proposal quality frameworks
- Emergency response optimization

---

*For more information, see [SECURITY.md](SECURITY.md) and [OPERATIONS.md](OPERATIONS.md)*