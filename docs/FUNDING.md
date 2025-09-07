# HorizCoin Funding Framework

## Overview

The HorizCoin funding framework provides a comprehensive system for milestone-based project funding, token distribution, and community-driven resource allocation. The system is designed to support the development of proof-of-bandwidth protocols and related infrastructure through transparent, accountable funding mechanisms.

## Funding Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    HorizCoin Funding Ecosystem                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │   Treasury   │    │   Escrow     │    │ Distribution │      │
│  │              │    │              │    │              │      │
│  │ • Allocation │────│ • Milestones │────│ • Vesting    │      │
│  │ • Emission   │    │ • Approval   │    │ • Airdrop    │      │
│  │ • Reserves   │    │ • Release    │    │ • Sale       │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
│         │                     │                     │          │
│         └─────────────────────┼─────────────────────┘          │
│                               │                                │
│  ┌──────────────┐            │            ┌──────────────┐     │
│  │  Governance  │            │            │  Monitoring  │     │
│  │              │            │            │              │     │
│  │ • Proposals  │────────────┼────────────│ • Analytics  │     │
│  │ • Approval   │            │            │ • Reporting  │     │
│  │ • Oversight  │            │            │ • Alerts     │     │
│  └──────────────┘            │            └──────────────┘     │
│                               │                                │
│                    ┌──────────────┐                           │
│                    │ Applications │                           │
│                    │              │                           │
│                    │ • Projects   │                           │
│                    │ • Teams      │                           │
│                    │ • Grants     │                           │
│                    └──────────────┘                           │
└─────────────────────────────────────────────────────────────────┘
```

## Funding Mechanisms

### 1. Milestone-Based Escrow Funding

#### Purpose
- Support long-term development projects
- Ensure accountability through milestone delivery
- Reduce funding risk through incremental releases

#### Process Flow
```
Project Application → Governance Approval → Escrow Creation → 
Milestone Submission → Review & Approval → Fund Release
```

#### Project Structure
```solidity
struct Project {
    address beneficiary;         // Project team address
    IERC20 token;               // Funding token (HORIZ)
    uint256 totalAmount;        // Total project funding
    uint256 releasedAmount;     // Amount already released
    uint256 startTime;          // Project start timestamp
    uint256 endTime;            // Project completion deadline
    bool active;                // Project status
    string metadataHash;        // IPFS hash for project details
    uint256 milestoneCount;     // Number of milestones
}
```

#### Milestone Structure
```solidity
struct Milestone {
    string description;         // Milestone objectives
    uint256 amount;            // Funding amount for milestone
    uint256 deadline;          // Milestone deadline
    MilestoneStatus status;    // Current status
    uint256 submittedAt;       // Submission timestamp
    uint256 approvedAt;        // Approval timestamp
    address approver;          // Governance approver
    string deliverableHash;    // IPFS hash for deliverables
}
```

### 2. Token Distribution Mechanisms

#### Vesting Schedules
- **Linear Vesting**: Gradual token release over time
- **Cliff Vesting**: Initial lock period followed by release
- **Revocable Vesting**: Can be cancelled for non-performance

#### Airdrop Programs
- **Merkle Tree Airdrops**: Efficient mass distribution
- **Multi-Round Support**: Sequential distribution phases
- **Eligibility Verification**: Automated claim validation

#### Token Sales (Future)
- **Fixed Price Sales**: Simple purchase mechanism
- **Dutch Auctions**: Price discovery mechanism
- **Bonding Curves**: Continuous token sales

### 3. Grant Programs

#### Developer Grants
- Small-scale funding for individual developers
- Focus on tooling and infrastructure
- Simplified application process

#### Research Grants
- Academic and applied research funding
- Proof-of-bandwidth protocol research
- Economic model development

#### Community Grants
- Community building initiatives
- Educational content creation
- Ecosystem development

## Funding Categories

### 1. Core Protocol Development

#### Infrastructure Projects
- **Scope**: Core protocol enhancements
- **Funding Range**: 100K - 1M HORIZ
- **Duration**: 6-18 months
- **Requirements**: Technical specification, team credentials

#### Proof-of-Bandwidth Research
- **Scope**: Algorithm development and optimization
- **Funding Range**: 50K - 500K HORIZ  
- **Duration**: 3-12 months
- **Requirements**: Research proposal, academic backing

### 2. Ecosystem Development

#### Integration Projects
- **Scope**: Third-party protocol integrations
- **Funding Range**: 25K - 250K HORIZ
- **Duration**: 2-6 months
- **Requirements**: Integration plan, security audit

#### Developer Tools
- **Scope**: SDKs, APIs, documentation
- **Funding Range**: 10K - 100K HORIZ
- **Duration**: 1-4 months
- **Requirements**: Tool specification, usage metrics

### 3. Community & Education

#### Educational Content
- **Scope**: Documentation, tutorials, courses
- **Funding Range**: 1K - 25K HORIZ
- **Duration**: 1-3 months
- **Requirements**: Content plan, target audience

#### Community Events
- **Scope**: Conferences, hackathons, meetups
- **Funding Range**: 5K - 50K HORIZ
- **Duration**: 1-6 months
- **Requirements**: Event plan, expected outcomes

## Application Process

### 1. Pre-Application

#### Eligibility Check
- Technical feasibility assessment
- Team capability evaluation
- Alignment with HorizCoin mission
- Resource requirement analysis

#### Initial Consultation
- Community feedback gathering
- Technical advisory input
- Scope refinement
- Timeline estimation

### 2. Formal Application

#### Required Documentation
```
- Project Summary (1-2 pages)
- Technical Specification (5-10 pages)
- Team Information & Credentials
- Milestone Breakdown with Deliverables
- Budget Breakdown and Justification
- Timeline and Dependencies
- Risk Assessment and Mitigation
- Success Metrics and KPIs
```

#### Application Template
```markdown
# Project Title

## Executive Summary
Brief overview of the project and its impact

## Team
- Team lead background
- Developer credentials
- Previous work examples
- Advisor information

## Technical Details
- Architecture overview
- Implementation approach
- Technology stack
- Integration points

## Milestones
| Milestone | Description | Deliverables | Timeline | Funding |
|-----------|-------------|--------------|----------|---------|
| M1        | ...         | ...          | ...      | ...     |

## Budget
- Development costs
- Infrastructure costs
- Audit costs
- Contingency

## Success Metrics
- Technical metrics
- Usage metrics
- Community metrics
```

### 3. Review Process

#### Technical Review
- Code quality assessment
- Security vulnerability analysis
- Performance evaluation
- Integration compatibility

#### Community Review
- Public comment period (7 days)
- Community feedback integration
- Stakeholder input gathering

#### Governance Approval
- Formal proposal submission
- Governance voting period
- Approval threshold: >50% + quorum
- Escrow contract creation

## Milestone Management

### 1. Milestone Definition

#### SMART Criteria
- **Specific**: Clear, well-defined objectives
- **Measurable**: Quantifiable success criteria
- **Achievable**: Realistic given resources
- **Relevant**: Aligned with project goals
- **Time-bound**: Clear deadlines

#### Example Milestones
```
Milestone 1: Protocol Design
- Deliverable: Technical specification document
- Success Criteria: Community review approval
- Timeline: 4 weeks
- Funding: 20% of total

Milestone 2: Core Implementation
- Deliverable: Working prototype
- Success Criteria: Unit test coverage >95%
- Timeline: 8 weeks
- Funding: 40% of total

Milestone 3: Security Audit
- Deliverable: Audit report with fixes
- Success Criteria: No critical vulnerabilities
- Timeline: 4 weeks
- Funding: 20% of total

Milestone 4: Mainnet Deployment
- Deliverable: Production deployment
- Success Criteria: Live integration
- Timeline: 2 weeks
- Funding: 20% of total
```

### 2. Submission & Review

#### Milestone Submission
```solidity
function submitMilestone(
    uint256 projectId,
    uint256 milestoneId,
    string calldata deliverableHash  // IPFS hash
) external;
```

#### Required Deliverables
- Technical deliverables (code, docs)
- Progress report
- Next milestone preparation
- Updated timeline if needed

#### Review Process
1. **Technical Review** (3 days): Code/deliverable quality
2. **Community Review** (7 days): Public feedback period
3. **Governance Vote** (3 days): Formal approval process
4. **Fund Release** (Immediate): Automatic upon approval

### 3. Approval & Release

#### Approval Criteria
- Deliverable quality meets standards
- Timeline adherence (or justified delays)
- Budget utilization transparency
- Next milestone readiness

#### Automatic Release
```solidity
function approveMilestone(
    uint256 projectId,
    uint256 milestoneId
) external onlyRole(MILESTONE_APPROVER_ROLE) {
    // Release funds automatically upon approval
    _releaseFunds(projectId, milestoneId);
}
```

## Risk Management

### 1. Project Risks

#### Technical Risks
- **Mitigation**: Detailed technical review, milestone structure
- **Response**: Additional technical support, scope adjustment

#### Team Risks
- **Mitigation**: Team credential verification, milestone accountability
- **Response**: Team replacement, project reassignment

#### Timeline Risks
- **Mitigation**: Buffer time allocation, dependency tracking
- **Response**: Timeline extension, scope reduction

### 2. Financial Risks

#### Budget Overruns
- **Prevention**: Detailed budget breakdown, milestone funding
- **Response**: Additional funding approval, scope reduction

#### Market Volatility
- **Mitigation**: Stablecoin conversion options, budget buffers
- **Response**: Funding adjustment, timeline modification

### 3. Security Risks

#### Code Security
- **Requirements**: Mandatory security audits for protocol changes
- **Process**: Multi-stage security review, bug bounty programs

#### Fund Security
- **Mechanisms**: Multi-signature controls, timelock delays
- **Monitoring**: Real-time fund tracking, anomaly detection

## Performance Metrics

### 1. Project Success Metrics

#### Technical Metrics
- Code quality scores
- Test coverage percentages
- Performance benchmarks
- Security audit results

#### Delivery Metrics
- Milestone completion rate
- Timeline adherence
- Budget utilization
- Scope change frequency

#### Impact Metrics
- Protocol adoption rate
- Developer engagement
- Community feedback scores
- Ecosystem integration

### 2. Program Success Metrics

#### Funding Efficiency
- Average cost per deliverable
- Return on investment calculations
- Resource utilization rates

#### Community Engagement
- Application volume
- Community participation in reviews
- Stakeholder satisfaction

#### Ecosystem Growth
- Number of active projects
- Developer ecosystem size
- Protocol usage growth

## Funding Governance

### 1. Funding Committee

#### Composition
- Technical experts (3)
- Community representatives (2)
- Economic advisors (2)
- Governance delegates (3)

#### Responsibilities
- Application screening
- Technical review coordination
- Milestone evaluation
- Program optimization

### 2. Decision Making

#### Funding Approval Process
1. Committee recommendation
2. Community comment period
3. Governance proposal
4. Token holder vote
5. Execution through timelock

#### Appeal Process
- Rejected applications can appeal
- Community advocate assignment
- Secondary review process
- Final governance decision

## Integration with Treasury

### 1. Funding Allocation

#### Treasury Reserves
- Development fund: 30% of treasury
- Grants program: 15% of treasury
- Emergency reserves: 10% of treasury
- Community initiatives: 5% of treasury

#### Emission Schedule
- Quarterly funding rounds
- Sustainable emission rates
- Market condition adjustments
- Long-term sustainability

### 2. Financial Controls

#### Budget Management
```solidity
// Reserve funds for approved projects
treasury.reserveTokens(token, projectFunding);

// Release milestone payments
treasury.transferTokens(token, beneficiary, milestoneAmount);
```

#### Transparency Measures
- Real-time treasury tracking
- Public funding reports
- Milestone payment logs
- Budget utilization dashboards

## Future Enhancements

### 1. Planned Features

#### Advanced Funding Models
- Retroactive funding
- Continuous funding streams
- Performance-based releases
- Equity-like arrangements

#### Technology Improvements
- Cross-chain funding
- Automated milestone verification
- AI-assisted project screening
- Real-time collaboration tools

### 2. Research Areas

#### Economic Models
- Optimal funding allocation strategies
- Incentive mechanism design
- Market maker models for token distribution
- Sustainability frameworks

#### Governance Evolution
- Liquid democracy for funding decisions
- Quadratic funding mechanisms
- Futarchy-based outcome prediction
- Delegation marketplace

---

*For implementation details, see [ARCHITECTURE.md](ARCHITECTURE.md) and [GOVERNANCE.md](GOVERNANCE.md)*