# HorizCoin Invariants Documentation

## Overview

This document defines the critical invariants that must hold true for the HorizCoin protocol to operate correctly and securely. These invariants form the foundation of our testing strategy and security assurance framework.

## Protocol Invariants

### 1. Token Supply Invariants

#### INV-1.1: Maximum Supply Limit
**Invariant**: `totalSupply() <= MAX_SUPPLY`
- **Description**: Total token supply must never exceed the maximum supply of 1 billion tokens
- **Critical Level**: HIGH
- **Test Strategy**: Fuzz testing with various mint scenarios

```solidity
// Invariant test example
function invariant_totalSupplyNeverExceedsMax() public {
    assertLe(token.totalSupply(), token.MAX_SUPPLY());
}
```

#### INV-1.2: Supply Conservation
**Invariant**: `totalSupply() == sum(all_balances)`
- **Description**: Sum of all individual balances equals total supply
- **Critical Level**: HIGH
- **Test Strategy**: Ghost variable tracking in invariant tests

#### INV-1.3: Non-Negative Balances
**Invariant**: `balanceOf(address) >= 0`
- **Description**: No account can have negative token balance
- **Critical Level**: HIGH
- **Test Strategy**: Balance manipulation fuzzing

### 2. Governance Invariants

#### INV-2.1: Voting Power Conservation
**Invariant**: `sum(all_voting_power) == totalSupply()`
- **Description**: Total voting power equals total token supply
- **Critical Level**: HIGH
- **Test Strategy**: Delegation tracking across operations

#### INV-2.2: Proposal State Transitions
**Invariant**: Valid state transitions only: `Pending → Active → {Succeeded|Defeated} → {Queued|Expired} → {Executed|Cancelled}`
- **Description**: Proposals follow valid state machine transitions
- **Critical Level**: MEDIUM
- **Test Strategy**: State transition fuzzing

#### INV-2.3: Quorum Requirements
**Invariant**: `executed_proposals.votes >= quorum_threshold`
- **Description**: Only proposals meeting quorum can be executed
- **Critical Level**: HIGH
- **Test Strategy**: Quorum boundary testing

#### INV-2.4: Timelock Delay Enforcement
**Invariant**: `execution_time >= queued_time + delay`
- **Description**: All executions respect minimum timelock delay
- **Critical Level**: CRITICAL
- **Test Strategy**: Time manipulation testing

### 3. Treasury Invariants

#### INV-3.1: Treasury Balance Accuracy
**Invariant**: `treasury.getAvailableBalance(token) == token.balanceOf(treasury) - reserved_amounts`
- **Description**: Available balance correctly accounts for reservations
- **Critical Level**: HIGH
- **Test Strategy**: Reservation and transfer fuzzing

#### INV-3.2: Emission Rate Bounds
**Invariant**: `emissionRate <= maxEmissionRate`
- **Description**: Emission rate never exceeds maximum allowed
- **Critical Level**: MEDIUM
- **Test Strategy**: Parameter update fuzzing

#### INV-3.3: Authorization Requirements
**Invariant**: All treasury operations require proper role authorization
- **Description**: Only authorized roles can execute treasury functions
- **Critical Level**: HIGH
- **Test Strategy**: Access control fuzzing

#### INV-3.4: Total Allocations <= Balance
**Invariant**: `totalAllocated <= actual_balance`
- **Description**: Cannot allocate more than available balance
- **Critical Level**: HIGH
- **Test Strategy**: Allocation exhaustion testing

### 4. Vesting Invariants

#### INV-4.1: Vesting Schedule Integrity
**Invariant**: `releasable_amount <= total_vested - already_released`
- **Description**: Cannot release more than allocated for vesting
- **Critical Level**: HIGH
- **Test Strategy**: Time manipulation and release fuzzing

#### INV-4.2: Time-Based Vesting Logic
**Invariant**: `vested_amount(t1) <= vested_amount(t2)` when `t1 <= t2`
- **Description**: Vested amount is monotonically increasing over time
- **Critical Level**: HIGH
- **Test Strategy**: Time progression testing

#### INV-4.3: Cliff Enforcement
**Invariant**: `vested_amount == 0` when `current_time < start_time + cliff_duration`
- **Description**: No tokens vest before cliff period
- **Critical Level**: MEDIUM
- **Test Strategy**: Cliff boundary testing

#### INV-4.4: Revocation Consistency
**Invariant**: Revoked schedules cannot release additional tokens
- **Description**: Revoked vesting schedules are permanently stopped
- **Critical Level**: MEDIUM
- **Test Strategy**: Revocation state testing

### 5. Airdrop Invariants

#### INV-5.1: Single Claim Per User
**Invariant**: `hasClaimed[round][user]` can only transition from `false` to `true`
- **Description**: Users can only claim each airdrop round once
- **Critical Level**: HIGH
- **Test Strategy**: Double claiming attempts

#### INV-5.2: Merkle Proof Verification
**Invariant**: All successful claims have valid Merkle proofs
- **Description**: Claims require cryptographic proof of eligibility
- **Critical Level**: HIGH
- **Test Strategy**: Proof forgery attempts

#### INV-5.3: Round Balance Consistency
**Invariant**: `claimed_amount <= total_round_allocation`
- **Description**: Claims cannot exceed round allocation
- **Critical Level**: HIGH
- **Test Strategy**: Over-claiming scenarios

### 6. Escrow Invariants

#### INV-6.1: Milestone Fund Conservation
**Invariant**: `project.totalAmount == sum(milestone.amounts)`
- **Description**: Project total equals sum of milestone amounts
- **Critical Level**: HIGH
- **Test Strategy**: Milestone amount manipulation

#### INV-6.2: Release Authorization
**Invariant**: Only approved milestones can release funds
- **Description**: Fund release requires proper milestone approval
- **Critical Level**: HIGH
- **Test Strategy**: Unauthorized release attempts

#### INV-6.3: Progressive Release
**Invariant**: `project.releasedAmount <= project.totalAmount`
- **Description**: Cannot release more than project allocation
- **Critical Level**: HIGH
- **Test Strategy**: Over-release testing

#### INV-6.4: Deadline Enforcement
**Invariant**: Expired milestones cannot be submitted
- **Description**: Submissions respect deadline constraints
- **Critical Level**: MEDIUM
- **Test Strategy**: Deadline boundary testing

### 7. Access Control Invariants

#### INV-7.1: Role Assignment Integrity
**Invariant**: Role changes require proper authorization
- **Description**: Only role admins can grant/revoke roles
- **Critical Level**: CRITICAL
- **Test Strategy**: Privilege escalation attempts

#### INV-7.2: Emergency Role Limitations
**Invariant**: Emergency actions have time or scope limitations
- **Description**: Emergency powers are bounded and temporary
- **Critical Level**: HIGH
- **Test Strategy**: Emergency abuse scenarios

#### INV-7.3: Multi-Signature Requirements
**Invariant**: Critical operations require multiple signatures
- **Description**: High-value operations need consensus
- **Critical Level**: HIGH
- **Test Strategy**: Single-signature bypass attempts

## Economic Invariants

### 8. Market Dynamics

#### INV-8.1: Price Impact Bounds
**Invariant**: Large operations don't cause excessive price impact
- **Description**: Protocol operations consider market impact
- **Critical Level**: MEDIUM
- **Test Strategy**: Large operation simulation

#### INV-8.2: Liquidity Preservation
**Invariant**: Core protocol maintains minimum liquidity
- **Description**: Protocol doesn't drain all available liquidity
- **Critical Level**: MEDIUM
- **Test Strategy**: Liquidity exhaustion scenarios

### 9. Rate Limiting Invariants

#### INV-9.1: Window-Based Limits
**Invariant**: Spending within any window period <= limit
- **Description**: Rate limits are properly enforced
- **Critical Level**: MEDIUM
- **Test Strategy**: Burst spending patterns

#### INV-9.2: Rate Limit Bypass Prevention
**Invariant**: No operations can bypass rate limits
- **Description**: All relevant operations respect rate limits
- **Critical Level**: MEDIUM
- **Test Strategy**: Bypass attempt fuzzing

## Security Invariants

### 10. Reentrancy Protection

#### INV-10.1: State Consistency
**Invariant**: External calls don't allow state manipulation
- **Description**: Reentrancy guards prevent state corruption
- **Critical Level**: CRITICAL
- **Test Strategy**: Reentrancy attack simulation

#### INV-10.2: Function Atomicity
**Invariant**: State-changing functions complete atomically
- **Description**: Functions either fully succeed or revert
- **Critical Level**: HIGH
- **Test Strategy**: Failure injection testing

### 11. Pause Mechanism Invariants

#### INV-11.1: Pause Effectiveness
**Invariant**: Paused contracts reject non-admin operations
- **Description**: Pause mechanism properly restricts access
- **Critical Level**: HIGH
- **Test Strategy**: Paused state operation attempts

#### INV-11.2: Emergency Pause Expiry
**Invariant**: Emergency pauses auto-expire after time limit
- **Description**: Emergency pauses don't become permanent
- **Critical Level**: MEDIUM
- **Test Strategy**: Time progression in paused state

## Invariant Testing Framework

### Test Categories

#### Unit Invariant Tests
- Test individual contract invariants in isolation
- Fast execution for development workflow
- Basic property verification

#### Integration Invariant Tests
- Test cross-contract invariant preservation
- Moderate execution time
- Complex interaction verification

#### System-Wide Invariant Tests
- Test protocol-level invariants
- Longer execution for comprehensive verification
- End-to-end property verification

### Testing Tools

#### Foundry Invariant Testing
```solidity
contract InvariantTest is Test {
    function setUp() public {
        // Initialize test environment
    }
    
    function invariant_totalSupplyNeverExceedsMax() public {
        assertLe(token.totalSupply(), token.MAX_SUPPLY());
    }
    
    function invariant_treasuryBalanceConsistency() public {
        uint256 available = treasury.getAvailableBalance(token);
        uint256 actual = token.balanceOf(address(treasury));
        uint256 reserved = treasury.totalReserved(token);
        assertEq(available, actual - reserved);
    }
}
```

#### Echidna Property Testing
```solidity
contract EchidnaTest {
    function echidna_supply_never_exceeds_max() public view returns (bool) {
        return token.totalSupply() <= token.MAX_SUPPLY();
    }
}
```

#### Formal Verification
- Critical invariants verified using formal methods
- Mathematical proof of invariant preservation
- High assurance for security-critical properties

### Test Execution Strategy

#### Continuous Testing
- Invariant tests run on every commit
- Fast feedback for development
- Regression prevention

#### Nightly Comprehensive Testing
- Extended fuzzing campaigns
- Complex scenario exploration
- Performance impact assessment

#### Pre-Release Validation
- Comprehensive invariant test suite
- Formal verification re-run
- Security audit validation

## Invariant Violation Response

### Detection and Alerting

#### Automated Detection
- Continuous monitoring systems
- Real-time invariant checking
- Immediate alerting on violations

#### Manual Verification
- Expert review of potential violations
- False positive filtering
- Impact assessment

### Response Procedures

#### Critical Invariant Violations
1. Immediate system pause if possible
2. Emergency response team activation
3. Root cause analysis
4. Fix development and testing
5. Gradual system restoration

#### Non-Critical Violations
1. Issue tracking and prioritization
2. Impact assessment and monitoring
3. Fix development in regular cycle
4. Enhanced monitoring during fix deployment

### Post-Incident Analysis

#### Invariant Review
- Assess if additional invariants needed
- Strengthen existing invariant definitions
- Update testing strategies

#### Process Improvement
- Enhance detection capabilities
- Improve response procedures
- Update team training

## Documentation Maintenance

### Regular Updates
- Quarterly invariant review and updates
- New feature invariant definition
- Removal of obsolete invariants

### Version Control
- Track invariant changes over time
- Link invariants to specific protocol versions
- Maintain backwards compatibility analysis

---

*These invariants form the core of our security and correctness assurance. Any changes to protocol logic must consider invariant preservation.*