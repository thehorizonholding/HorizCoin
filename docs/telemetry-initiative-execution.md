# Telemetry Initiative Execution Plan

## 1. Overview
This document defines the scope, objectives, success measures, phases, and operational mechanics for the HorizCoin Telemetry Initiative. It serves as the single execution source of truth during the scaffold & rollout period.

## 2. Objectives
- Establish a minimal, evolvable telemetry collection layer without blocking core development.
- Provide observable signals for: version adoption, command usage, demo runs, and error conditions (later phases).
- Build automation to keep progress transparent and low-friction.

## 3. Success Metrics
### Leading Indicators
| Metric | Definition | Target (Phase 1) |
|--------|------------|------------------|
| Progress cadence | At least 3 logged progress entries per week | >=3/week |
| Automation health | Workflow success rate | >95% |
| Documentation freshness | No section >14 days stale (no update) | 100% |

### Lagging Indicators (Later Phases)
| Metric | Definition | Target (Phase 3+) |
|--------|------------|-------------------|
| Version adoption signal | % binaries reporting version | >80% of distributed builds |
| Command usage distribution | Top 3 commands coverage | 90% of executions |
| Error reporting reliability | % structured events parsed | >98% |

## 4. Scope
### In-Scope (Phases 0–2)
- Documentation & execution tracking
- Baseline CLI structure (version, demo)
- Version string & build metadata plumbing
- Progress automation & meta issue (#25) updates

### Out-of-Scope (Until Later Phases)
- External ingestion pipeline
- Persistent storage / data warehouse wiring
- PII / compliance review (deferred until real data)
- Real-time dashboards

## 5. Stakeholders & Roles
| Role | Responsibility | Current Owner |
|------|----------------|---------------|
| Maintainer | Approves scope changes | TBD |
| Implementer | Adds code & automation | thehorizonholding |
| Reviewer | Sanity checks plan | TBD |
| Automation | Posts periodic summaries | GitHub Actions bot |

## 6. Architecture Overview (Placeholder)
Initial architecture will be a lightweight event emission layer (internal package TBD) producing structured records (JSON) routed to stdout / log surface. Collection & forwarding deferred until Phase 2+.

## 7. Metrics / Event Taxonomy (Forward Looking)
| Event | Phase | Purpose | Notes |
|-------|-------|---------|-------|
| cli.start | 1 | Basic invocation count | Minimal fields |
| cli.command.executed | 2 | Command usage distribution | command, duration |
| cli.error | 2 | Error surface & classification | error_type |
| telemetry.flush | 3 | Transport reliability | batch_size |

## 8. Rollout Phases
| Phase | Name | Focus | Exit Criteria |
|-------|------|-------|---------------|
| 0 | Scaffold | Repo structure, plan, automation | Doc + workflow + version pkg in place |
| 1 | Baseline Signals | Version & command stubs | Version printed + placeholder emission |
| 2 | Structured Events | Internal event structs | Event schema draft + demo emits JSON |
| 3 | Aggregation | Batch + sink adapter | Flush logic + configurable sink |
| 4 | Hardening | Reliability & integrity | Retry, backoff, validation |

## 9. Change Control
- Minor textual doc edits: direct commit on feature branch.
- Structural scope changes: note in Progress Log + mark with tag [SCOPE].
- Phase advancement: add explicit log line beginning with PHASE ADVANCE:.

## 10. Automation Conventions
- Workflow (.github/workflows/telemetry-progress.yml) runs daily @03:00 UTC + on manual dispatch.
- It extracts last N (default 10) progress entries and updates meta issue (#25) comment.
- Manual progress entry insertion supported via workflow_dispatch input or local script (scripts/update-progress.sh).

## 11. Progress Logging Format
Each progress line MUST start with a dash, space, ISO date (UTC), space, hyphen, space, then message.
Example: `- 2025-09-07 - Added baseline execution plan document.`

Optional tags (uppercase in brackets) at end or beginning: [SCOPE] [RISK] [PHASE] [BLOCKED].

## 12. Open Risks (Initial)
| Risk | Status | Mitigation |
|------|--------|------------|
| Scope creep before baseline events | Open | Enforce phased gating |
| Over-engineering transport early | Open | Defer sink until Phase 3 |
| Lack of reviewers slows merge | Open | Recruit maintainer after Phase 1 |

## 13. TODO Backlog (Pre-Issue Granularity)
- Define internal telemetry event struct (Phase 2)
- Add CLI flag to disable telemetry (Phase 2)
- Implement JSON emitter (Phase 2)
- Add sink abstraction (Phase 3)
- Add reliability features (Phase 4)

## 14. Review Cadence
- Weekly review of: risks, backlog, stale sections.
- Auto reminder can be added later if needed.

## 15. Dependencies / External
None yet (intentionally isolated).

## 16. Deferments
- Data retention policy (await real data design)
- Privacy statement (post schema stabilization)

## 17. Exit Criteria (Initiative)
- Core telemetry events reliably emitted & flushed.
- Documentation stabilized (no substantive changes for 14 days).
- Metrics integrated into downstream consumer (future repository / service).

## Progress Log

- 2025-09-07 - Initialized execution plan document.
- 2025-09-07 - Added version package & CLI scaffold (baseline).