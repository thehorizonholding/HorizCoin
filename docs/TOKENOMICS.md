# Tokenomics (Draft)

Status: Draft

## Objectives
- Reward real bandwidth contribution (earn emissions).
- Encourage long-term alignment via staking.
- Bound inflation & provide predictable schedule.

## Supply Model (TBD)
Option A: Exponential decay emission (continuous half-life).  
Option B: Two-phase (bootstrap high emissions -> steady low tail).  
Option C: Logistic (front-loaded growth -> plateau).

Decision pending simulation.

## Emission Controller
- Epoch-based minting: emission(epoch) -> token amount
- Parameter bounds: max delta% change per governance action.

## Reward Allocation
Reward for node i = (score_i / total_scores) * epoch_emission.

## Staking
- Oracle staking to secure report honesty.
- Slash conditions: equivocation, invalid data inclusion, downtime threshold.

## Metrics to Track
- Staked / circulating ratio
- Effective inflation vs target
- Average reward per bandwidth unit

## Open Items
- Exact initial emission rate
- Vesting / lockups for foundation or contributors
- Long-term burn / sink mechanisms (if any)