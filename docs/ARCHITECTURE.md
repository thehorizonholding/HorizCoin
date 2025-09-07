# HorizCoin Architecture

## Overview

HorizCoin is a comprehensive governance and treasury ecosystem built on Ethereum, designed to support proof-of-bandwidth protocols and decentralized funding mechanisms. The system consists of modular smart contracts that work together to provide governance, treasury management, token distribution, and milestone-based funding.

## Core Principles

### 1. **Governance-First Design**
- All critical operations controlled by decentralized governance
- Timelock-protected execution for safety
- Configurable parameters through on-chain governance

### 2. **Security by Default**
- Conservative defaults to prevent accidental activation
- Emergency pause mechanisms with time limits
- Role-based access control throughout

### 3. **Modular Architecture**
- Independent modules that can be deployed selectively
- Clear separation of concerns
- Extensible design for future enhancements

### 4. **Transparency & Auditability**
- Comprehensive event logging
- Public parameter tracking
- Open-source with extensive documentation

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        HorizCoin Ecosystem                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │  Governance  │    │   Treasury   │    │ Distribution │      │
│  │              │    │              │    │              │      │
│  │ • Governor   │────│ • Treasury   │────│ • Vesting    │      │
│  │ • Timelock   │    │ • RateLimit  │    │ • Airdrop    │      │
│  │ • Parameters │    │ • Pause      │    │ • Sale       │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
│         │                     │                     │          │
│         └─────────────────────┼─────────────────────┘          │
│                               │                                │
│  ┌──────────────┐            │            ┌──────────────┐     │
│  │    Token     │            │            │   Funding    │     │
│  │              │            │            │              │     │
│  │ • ERC20      │────────────┼────────────│ • Escrow     │     │
│  │ • Voting     │            │            │ • Milestone  │     │
│  │ • Pausable   │            │            │ • Approval   │     │
│  └──────────────┘            │            └──────────────┘     │
│                               │                                │
│                    ┌──────────────┐                           │
│                    │ Utility Libs │                           │
│                    │              │                           │
│                    │ • Math       │                           │
│                    │ • Errors     │                           │
│                    │ • Events     │                           │
│                    └──────────────┘                           │
└─────────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. Token Layer

#### HorizCoinToken
- **Purpose**: ERC20 governance token with voting capabilities
- **Features**:
  - OpenZeppelin ERC20Votes for governance integration
  - Permit functionality for gasless approvals
  - Transfer pause capability for emergency situations
  - Maximum supply limit (1 billion tokens)
  - Initial mint to treasury

**Key Functions:**
```solidity
function setTransfersPaused(bool _paused) external onlyOwner
function delegate(address delegatee) external
function getPastVotes(address account, uint256 blockNumber) external view returns (uint256)
```

### 2. Governance Layer

#### HorizGovernor
- **Purpose**: OpenZeppelin-based governance with custom enhancements
- **Features**:
  - Configurable quorum (default 4%)
  - Timelock integration for execution delays
  - Emergency cancellation capabilities
  - Proposal threshold in basis points
  - Maximum actions per proposal limit

**Key Parameters:**
- Voting Delay: ~1 day (7200 blocks)
- Voting Period: ~7 days (50400 blocks)
- Quorum: 4% of total supply
- Timelock Delay: 2 days (production guidance)

#### TimelockController
- **Purpose**: Delayed execution for governance proposals
- **Features**:
  - Configurable minimum delay
  - Role-based proposer/executor permissions
  - Batch operation support

#### ParameterChangeModule
- **Purpose**: On-chain parameter storage and management
- **Features**:
  - Type-safe parameter storage (uint256, string, address, bool)
  - Governance-controlled updates through timelock
  - Parameter enumeration and querying
  - Emergency parameter updates

#### PauseModule (Optional)
- **Purpose**: Emergency pause functionality
- **Features**:
  - Governance-controlled pause/unpause
  - Emergency pause with automatic expiry (7 days)
  - Role-based pause permissions

### 3. Treasury Layer

#### HorizTreasury
- **Purpose**: Central treasury for fund management
- **Features**:
  - Multi-token support (ERC20 + ETH)
  - Emission system for scheduled distributions
  - Token reservation system
  - Batch operations for efficiency
  - Emergency withdrawal capabilities

**Core Operations:**
```solidity
function transferTokens(address token, address to, uint256 amount) external
function batchTransfer(...) external
function distributeEmissions(address token, address recipient) external
function reserveTokens(address token, uint256 amount) external
```

#### RateLimitedTreasuryAdapter (Optional)
- **Purpose**: Spending rate limits for additional security
- **Features**:
  - Rolling window rate limiting
  - Token-specific limits
  - Emergency bypass capability
  - Integration with main treasury

### 4. Distribution Layer

#### VestingVault
- **Purpose**: Linear and cliff vesting for token distribution
- **Features**:
  - Multiple vesting schedules per beneficiary
  - Cliff and linear vesting support
  - Revokable vesting schedules
  - Batch release operations

**Vesting Schedule:**
```solidity
struct VestingSchedule {
    address beneficiary;
    uint256 totalAmount;
    uint256 startTime;
    uint256 cliffDuration;
    uint256 vestingDuration;
    uint256 amountReleased;
    bool revoked;
    bool revocable;
}
```

#### MerkleAirdrop
- **Purpose**: Merkle tree-based token airdrops
- **Features**:
  - Multiple airdrop rounds
  - Merkle proof verification
  - IPFS metadata support
  - Time-bounded claiming

#### FixedPriceSale (STUB)
- **Purpose**: Token sale functionality (not implemented)
- **Status**: Stub contract with parameters set to 0
- **Safety**: Cannot be activated without explicit configuration

### 5. Funding Layer

#### EscrowMilestoneVault
- **Purpose**: Milestone-based project funding
- **Features**:
  - Multi-project support
  - Milestone approval workflow
  - Governance-controlled approvals
  - Automatic deadline enforcement

**Project Structure:**
```solidity
struct Project {
    address beneficiary;
    IERC20 token;
    uint256 totalAmount;
    uint256 releasedAmount;
    uint256 startTime;
    uint256 endTime;
    bool active;
    string metadataHash;
    uint256 milestoneCount;
}
```

## Security Architecture

### Access Control Matrix

| Role | Contract | Permissions |
|------|----------|-------------|
| Timelock | All | Execute governance proposals |
| Governor | Timelock | Propose operations |
| Emergency | Treasury, Pause | Emergency actions |
| Admin | Various | Initial configuration |
| Beneficiary | Vesting | Release vested tokens |

### Security Mechanisms

1. **Reentrancy Protection**: All external calls protected
2. **Role-Based Access**: Granular permissions using OpenZeppelin AccessControl
3. **Emergency Pauses**: Multiple pause mechanisms with time limits
4. **Parameter Validation**: Comprehensive input validation
5. **Rate Limiting**: Optional spending limits for treasury operations

### Upgrade Path

The system is designed to be non-upgradeable for security, with governance-controlled parameter updates providing flexibility:

1. **Parameter Updates**: Through ParameterChangeModule
2. **New Modules**: Deploy and integrate via governance
3. **Emergency Response**: Pause mechanisms and emergency roles

## Deployment Architecture

### Core Deployment Order
1. **HorizCoinToken** (mints to treasury)
2. **TimelockController** (with temp admin)
3. **HorizGovernor** (references token + timelock)
4. **HorizTreasury** (controlled by timelock)
5. **ParameterChangeModule** (executor = timelock)
6. **VestingVault** (admin = multisig)
7. **MerkleAirdrop** (admin = multisig)
8. **EscrowMilestoneVault** (approver = timelock)

### Optional Modules
- **PauseModule** (commented in deployment)
- **RateLimitedTreasuryAdapter** (commented in deployment)
- **FixedPriceSale** (stub only)

### Configuration Steps
1. Grant timelock proposer role to governor
2. Transfer treasury admin to timelock  
3. Configure parameter module executor
4. Set up emergency roles
5. Renounce temporary admin roles

## Integration Patterns

### Governance Integration
```solidity
// Proposal to update emission rate
targets = [address(treasury)]
values = [0]
calldatas = [abi.encodeWithSignature("setEmissionRate(uint256)", newRate)]
governor.propose(targets, values, calldatas, description)
```

### Treasury Integration
```solidity
// Vesting vault receives tokens from treasury
treasury.transferTokens(
    address(token),
    address(vestingVault),
    vestingAmount
)
```

### Parameter Management
```solidity
// Update system parameter via governance
parameterModule.setParameter("maxEmissionRate", newValue)
```

## Performance Considerations

### Gas Optimization
- Batch operations for multiple transfers
- Efficient storage patterns
- Minimal external calls

### Scalability
- Modular design allows selective deployment
- Rate limiting prevents spam
- Pagination for large datasets

## Monitoring & Observability

### Key Events
- Parameter changes
- Treasury operations
- Governance proposals
- Emergency actions

### Metrics to Track
- Governance participation
- Treasury balance changes
- Emission rates
- Vesting releases

## Future Enhancements

### Planned Features
- Dutch auction sale mechanism
- Bonding curve pricing
- Advanced vesting schedules
- Cross-chain governance

### Extension Points
- New distribution mechanisms
- Additional treasury modules
- Enhanced governance features
- Integration with external protocols

## References

- [OpenZeppelin Governance](https://docs.openzeppelin.com/contracts/4.x/governance)
- [ERC20Votes Standard](https://eips.ethereum.org/EIPS/eip-2612)
- [Timelock Security Patterns](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/governance/TimelockController.sol)
- [Merkle Tree Airdrops](https://github.com/Uniswap/merkle-distributor)