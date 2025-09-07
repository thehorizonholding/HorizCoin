# HorizCoin Architecture (Draft)

## Components
- Smart Contracts
  - ERC20 governance + emission controller (future)
  - EpochReportRegistry: stores oracle committee signed bandwidth epoch summaries
  - RewardDistributor: maps bandwidth shares -> token emissions
- Oracle Node
  - Collects raw challenge responses (bandwidth probes)
  - Aggregates, filters outliers, produces per-epoch summary
  - Signs summary (future: threshold signature / BLS)
- Backend (Optional Off-Chain API)
  - Public REST for explorers / dashboards
  - Caches and indexes on-chain epochs + metrics
- Governance
  - Token-based voting (ERC20Votes)
  - Parameter changes (epoch length, committee size, emission curve)

## Data Flow
1. Peers perform bandwidth challenges (placeholder design).
2. Oracle nodes collect challenge artifacts.
3. Oracle committee aggregates + signs an EpochReport.
4. Contract verifies signatures, stores report.
5. RewardDistributor allocates emissions for epoch N.
6. Users claim rewards.

## Open Design Questions
- Signature scheme (BLS vs aggregated ECDSA)
- Sybil resistance: device / ASN attestation, stake weighting, reputation
- Challenge protocol cost optimization
- On-chain vs off-chain data compression (Merkle commitments)