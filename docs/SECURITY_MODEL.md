# Security Model (Draft)

Status: Draft

## Threat Surfaces
1. Smart Contracts (EpochReportRegistry, RewardDistributor, Token, Staking)
2. Oracle / PoBW pipeline (data integrity, spoofed bandwidth)
3. Governance (parameter abuse, rushed malicious upgrade if proxies)
4. Key Management (multisig keys, oracle signing keys)
5. Economic Manipulation (inflation misconfiguration, reward skew)

## Core Invariants (Target List)
Code / Economic:
- TotalSupply <= MaxSupply (if cap chosen) or emission schedule upper envelope.
- Single reward claim per node per epoch.
- Epoch IDs strictly increasing.
- Emission delta per epoch within configured bounds.
- No unauthorized mint (only emission controller or reward logic).

Oracle:
- Report signatures >= threshold.
- Report committee set matches expected set for epoch.
- Merkle root matches bandwidth allocation proofs (off-chain verification harness).

Staking:
- Slash reduces slashable stake; cannot underflow.
- Unlock respects cooldown period.
- No stake can be simultaneously “locked” and “withdrawable”.

## Roles & Permissions
Role | Capability | Mitigation
---- | ---------- | ----------
Multisig (Phase 0) | Pause, parameter adjust within bounds | Sunset, on-chain bounds
Governor | Execute queued proposals | Timelock delay
Oracle | Submit reports | Stake + slashing
Emergency Guardian (temporary) | Pause only | Hard-coded expiry

## Known Early Weaknesses
- No finalized aggregated signature scheme (initial multisig overhead).
- Bandwidth challenge spoofing mitigations incomplete.
- Attestation of unique physical nodes absent.

## Security Controls Roadmap
Phase | Control
----- | -------
Prototype | Basic unit tests, ownership checks
Closed Alpha | Invariants + initial fuzz, static analysis
Public Beta | Expanded fuzz, gas benchmarks, threat model stable
Audit-Ready | Formal verification candidates + external audits
Launch Candidate | Bug bounty live, incident runbooks executed

## Incident Response (Outline)
1. Detect (monitor alerts / community report)
2. Triage severity (critical vs mitigable)
3. Pause (if permissible & necessary)
4. Public notice (transparency window target < 24h)
5. Patch or parameter rollback
6. Postmortem (root cause + corrective actions)

## Tooling
- Foundry (unit, fuzz, invariant)
- Slither / Mythril (static)
- Echidna (extended fuzz)
- Semgrep (Go/TS)
- Differential test harness for reward math

## Open Questions
- Do we adopt proxies or use immutable architecture + migration pattern?
- Minimal slashing criteria definition timeline?
- Formal verification scope selection.