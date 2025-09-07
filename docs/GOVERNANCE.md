# Governance (Draft)

Status: Draft / Pre‑Launch

## Objectives
- Parameter stewardship (emission parameters, epoch length, committee size).
- Security responsiveness (pause / mitigate critical flaws while early).
- Progressive decentralization (reduce privileged roles over stages).

## Phases
Phase 0 (Pre‑Alpha): Multisig (n-of-m) with narrow scope (pause, mint emission adjustments within bounds).
Phase 1 (Beta): Introduce ERC20Votes governor + timelock; multisig only emergency pause.
Phase 2 (Launch Candidate): Reduce emergency powers; bounded parameter changes on-chain.
Phase 3 (Mature): Remove guardians; add proposal thresholds / quorum formulas; delegate set diversification.

## Roles
- Governor (contract)
- Timelock
- Emergency Guardian (sunset date)
- Oracle Committee (off-chain)
- Delegates (token holders with delegated voting power)

## Quorum & Threshold (Illustrative)
- Proposal threshold: min(X, 0.25% of circulating voting power) – finalize before launch.
- Quorum: Y% (e.g. 5–8%) of circulating voting power in favor for passage.

## Proposal Lifecycle
1. Proposal Created (metadata: IPFS / off-chain description)
2. Voting Delay (e.g. 1 epoch)
3. Voting Period (e.g. 7 epochs)
4. Queue in Timelock
5. Execution / Expiration

## Parameter Bounds
Parameter | Bound Rule (Illustrative)
--------- | -------------------------
Emission Rate | Max ±2% change per proposal
Epoch Length | Cannot reduce below MIN_EPOCH_SECONDS
Committee Size | Range [MIN_COMMITTEE, MAX_COMMITTEE]
Slash Percent | Max increase per proposal: +5% absolute

## Upgrade Philosophy
- Prefer immutability for critical core (reward math) once audited.
- If proxy upgrades retained: restrict admin to timelock after Phase 1.
- Publish storage layout & upgrade diff rationale for every upgrade.

## Transparency Artifacts
- CHANGELOG.md
- Proposal index (Governance forum or docs/governance/proposals/)
- Delegate registry + contact channels

## Progressive Decentralization KPIs
- Top 5 delegate voting power share < 50%
- Active voter participation rate > 20% of total voting power
- Governance proposal execution median time within SLA

## Open Questions
- Exact initial quorum
- Emergency pause scope (which functions)
- Minimum stake weight for oracle committee membership

## Security Considerations
- Timelock latency vs response speed tradeoff
- Guardian misuse risk – mandate public sunset date
- Vote buying and collusion monitoring
