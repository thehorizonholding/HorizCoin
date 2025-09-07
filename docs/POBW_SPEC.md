# Proof of Bandwidth (PoBW) Specification (Draft)

Status: Draft / Exploratory

## Goals
- Incentivize verifiable contribution of network bandwidth & availability.
- Minimize gaming via synthetic traffic or replay.
- Provide deterministic, aggregatable metrics per epoch.

## Entities
- Challenger: Issues probes to node endpoints.
- Node: Responds with signed proof payloads.
- Oracle Committee: Aggregates challenge results -> EpochReport.

## Challenge Flow (High-Level)
1. Scheduler selects target nodes & issues bandwidth probes (e.g., fixed-size payload transfers, RTT measurement, throughput test windows).
2. Node returns: (nonce, timestamp, size, duration, signature, optional attestation).
3. Oracle filters invalid / outlier samples.
4. Oracle computes normalized bandwidth score per node.
5. Oracle builds Merkle tree of (node, score) pairs; stores root + aggregate stats in EpochReport.
6. Report signatures collected; submitted on-chain.
7. RewardDistributor allocates proportional emissions.

## Anti-Gaming Considerations
- Nonce freshness & expiry.
- Multi-origin probing (avoid single vantage manipulation).
- Trimmed mean or percentile cut to drop extreme synthetic values.
- Minimum sample count per node for inclusion.

## Data Structures (Illustrative)
```json
{
  "epoch": 1234,
  "version": 1,
  "generated_at": 1712345678,
  "committee": ["0xabc...", "0xdef..."],
  "aggregate": {
    "total_nodes": 542,
    "total_effective_bandwidth": "1234567890"
  },
  "merkle_root": "0x...",
  "signature_bundle": [
    {"signer": "0xabc...", "sig": "0x..."}
  ]
}
```

## Open Questions
- Precise bandwidth normalization formula.
- Handling asymmetric routes / geographic bias.
- Incorporating uptime weighting.
- Attestation of real hardware / ASN uniqueness.

## Future Extensions
- Zero-knowledge proof for selective challenge disclosure.
- Multi-metric scoring (latency tier, jitter, loss rate).