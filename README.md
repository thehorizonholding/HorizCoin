# HorizCoin

**HorizCoin** is a comprehensive governance and treasury ecosystem designed to support proof-of-bandwidth protocols and decentralized funding mechanisms. Built on Ethereum with Solidity smart contracts, HorizCoin provides a complete infrastructure for token-based governance, treasury management, distribution mechanisms, and milestone-based project funding.

## 🌟 Features

### Core Infrastructure
- **🪙 ERC20 Governance Token**: Full voting capabilities with delegation support
- **🏛️ Decentralized Governance**: OpenZeppelin Governor with timelock protection
- **💰 Treasury Management**: Multi-token treasury with emission controls
- **⚙️ Parameter Management**: On-chain configuration with governance oversight

### Distribution Systems
- **🎁 Vesting Schedules**: Linear and cliff vesting with revocation capability
- **🪂 Merkle Airdrops**: Efficient mass distribution with multiple rounds
- **💸 Token Sales**: Configurable sale mechanisms (implementation pending)

### Funding Framework
- **🏗️ Milestone Escrow**: Project funding with deliverable-based releases
- **📊 Performance Tracking**: Comprehensive project monitoring and reporting
- **🔒 Security Controls**: Multi-signature approvals and timelock delays

### Security & Safety
- **⏸️ Emergency Pauses**: Multi-level pause mechanisms with auto-expiry
- **🔐 Access Control**: Role-based permissions with governance oversight
- **🛡️ Rate Limiting**: Optional spending controls with rolling windows
- **📈 Monitoring**: Real-time analytics and anomaly detection

## 🏗 Architecture

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
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites
- [Foundry](https://getfoundry.sh/) for smart contract development
- Node.js 18+ (for frontend tools)
- Git for version control

### Installation

```bash
# Clone the repository
git clone https://github.com/thehorizonholding/HorizCoin.git
cd HorizCoin

# Install Foundry dependencies
forge install

# Copy environment configuration
cp config/env/.env.example .env
# Edit .env with your configuration

# Build contracts
forge build

# Run tests
forge test

# Deploy locally (requires Anvil or testnet)
forge script script/DeployAll.s.sol --rpc-url $RPC_URL --broadcast
```

### Post-Deployment Verification

```bash
# Run the post-deployment checklist
./scripts/post-deploy-checklist.sh

# Verify contract addresses and configuration
cat addresses.json
```

## 📋 Contract Overview

### Core Contracts

| Contract | Purpose | Key Features |
|----------|---------|-------------|
| **HorizCoinToken** | ERC20 governance token | Voting, delegation, pause controls |
| **HorizGovernor** | Governance management | Proposals, voting, timelock integration |
| **HorizTreasury** | Fund management | Multi-token support, emissions, reservations |
| **TimelockController** | Execution delays | 2-day delay, security buffer |
| **ParameterChangeModule** | System configuration | On-chain parameters, governance control |

### Distribution Contracts

| Contract | Purpose | Key Features |
|----------|---------|-------------|
| **VestingVault** | Token vesting | Linear/cliff vesting, revocation |
| **MerkleAirdrop** | Token airdrops | Merkle proofs, multiple rounds |
| **FixedPriceSale** | Token sales | **STUB - Configuration required** |

### Funding Contracts

| Contract | Purpose | Key Features |
|----------|---------|-------------|
| **EscrowMilestoneVault** | Project funding | Milestone-based releases, approvals |

### Optional Modules

| Contract | Purpose | Status |
|----------|---------|--------|
| **PauseModule** | Emergency controls | Optional deployment |
| **RateLimitedTreasuryAdapter** | Spending limits | Optional deployment |

## 🔧 Configuration

### Governance Parameters
- **Voting Delay**: 1 day (7,200 blocks)
- **Voting Period**: 7 days (50,400 blocks)
- **Quorum**: 4% of total supply (400 basis points)
- **Proposal Threshold**: 0% initially (configurable)
- **Timelock Delay**: 2 days (172,800 seconds)

### Token Economics
- **Max Supply**: 1,000,000,000 HORIZ (1 billion)
- **Initial Mint**: To treasury address
- **Emission Rate**: Configurable (max 1,000 tokens/block)
- **Transfer Controls**: Pausable by governance

### Security Settings
- **Emergency Pause**: 7-day auto-expiry
- **Rate Limits**: Configurable windows and amounts
- **Multi-Signature**: Required for critical operations
- **Role-Based Access**: Granular permission system

## 📚 Documentation

Comprehensive documentation is available in the `/docs` directory:

- **[Architecture](docs/ARCHITECTURE.md)**: System design and component overview
- **[Governance](docs/GOVERNANCE.md)**: Governance mechanisms and procedures
- **[Funding](docs/FUNDING.md)**: Project funding framework and processes
- **[Security](docs/SECURITY.md)**: Security framework and best practices
- **[Operations](docs/OPERATIONS.md)**: Day-to-day operational procedures
- **[Risk Assessment](docs/RISK.md)**: Risk analysis and mitigation strategies
- **[Threat Model](docs/THREAT_MODEL.md)**: Security threat analysis
- **[Invariants](docs/INVARIANTS.md)**: Protocol invariants and testing

## 🧪 Testing

### Test Suite
```bash
# Run all tests
forge test

# Run with verbosity
forge test -vvv

# Run specific test file
forge test --match-path test/unit/HorizCoinToken.t.sol

# Run invariant tests
forge test --match-path test/invariant/

# Generate coverage report
forge coverage
```

### Test Categories
- **Unit Tests**: Individual contract testing
- **Integration Tests**: Cross-contract interactions
- **Invariant Tests**: Property-based testing
- **Fuzz Tests**: Input randomization testing
- **Gas Tests**: Gas usage optimization

## 🔐 Security

### Security Measures
- **Audits**: Professional security audits before mainnet
- **Bug Bounty**: Community-driven vulnerability discovery
- **Formal Verification**: Mathematical proof of critical properties
- **Monitoring**: Real-time security monitoring and alerting

### Security Contact
- **Email**: security@horizcoin.org
- **Response Time**: 24 hours for critical issues
- **Disclosure**: Responsible disclosure encouraged

### Audit Status
- [ ] Initial development complete
- [ ] Internal security review
- [ ] External security audit
- [ ] Bug bounty program
- [ ] Mainnet deployment

## 🏛️ Governance

### Participation
1. **Acquire HORIZ tokens** from authorized distribution
2. **Delegate voting power** to yourself or a representative
3. **Monitor proposals** on governance forum
4. **Vote on proposals** during voting periods
5. **Track execution** of approved proposals

### Proposal Process
1. **Discussion** in community forum
2. **Formal proposal** submission
3. **Voting period** (7 days)
4. **Timelock queue** (if approved)
5. **Execution** (after 2-day delay)

## 💼 Use Cases

### For Projects
- **Milestone Funding**: Structured project funding with deliverable-based releases
- **Team Compensation**: Vesting schedules for team token allocation
- **Community Distribution**: Airdrops and community reward programs

### For DAOs
- **Treasury Management**: Sophisticated treasury operations with governance oversight
- **Parameter Control**: On-chain configuration management
- **Emergency Response**: Multi-level pause and recovery mechanisms

### For Developers
- **Building Blocks**: Modular contracts for custom implementations
- **Integration**: APIs for governance and treasury integration
- **Extensions**: Framework for additional functionality

## 🛣️ Roadmap

### Phase 1: Core Infrastructure ✅
- [x] Token and governance contracts
- [x] Treasury and distribution systems
- [x] Basic security measures
- [x] Testing framework

### Phase 2: Enhanced Features 🚧
- [ ] Advanced sale mechanisms (Dutch auction, bonding curves)
- [ ] Cross-chain governance support
- [ ] Enhanced monitoring and analytics
- [ ] Governance optimization

### Phase 3: Ecosystem Growth 📋
- [ ] Partner integrations
- [ ] Developer tooling
- [ ] Community programs
- [ ] Scaling solutions

## 🤝 Contributing

We welcome contributions from the community! Please see our contributing guidelines:

1. **Fork** the repository
2. **Create** a feature branch
3. **Implement** changes with tests
4. **Submit** a pull request
5. **Address** review feedback

### Development Setup
```bash
# Install pre-commit hooks
forge fmt --check
forge test

# Run linting
solhint 'src/**/*.sol'

# Check gas usage
forge test --gas-report
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- **Website**: [horizcoin.org](https://horizcoin.org) (coming soon)
- **Documentation**: [docs.horizcoin.org](https://docs.horizcoin.org) (coming soon)
- **Governance**: [gov.horizcoin.org](https://gov.horizcoin.org) (coming soon)
- **Discord**: [discord.gg/horizcoin](https://discord.gg/horizcoin) (coming soon)
- **Twitter**: [@HorizCoin](https://twitter.com/HorizCoin) (coming soon)

## ⚠️ Disclaimer

**IMPORTANT**: This software is provided "as is" without warranties. The FixedPriceSale contract is a STUB with parameters set to zero - DO NOT deploy to production without proper configuration. Always perform thorough testing and security audits before mainnet deployment.

---

*Built with ❤️ for the decentralized future*
