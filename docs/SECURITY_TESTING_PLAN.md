# Security Testing Plan (Draft)

Category | Tools | Cadence | Goal
-------- | ----- | ------- | ----
Unit Tests | Foundry | Per PR | Functional correctness
Invariants | Foundry | Per PR + CI | Economic & state safety
Fuzz | Foundry/Echidna | Nightly | Edge case discovery
Static Analysis | Slither/Semgrep | CI | Early pattern detection
Gas Profiling | Foundry | Weekly | Prevent pathological cost
Differential Tests | Custom harness | Weekly | Reward math consistency

Nightly job: full fuzz (time-boxed). Weekly: extended fuzz + mutation candidates.