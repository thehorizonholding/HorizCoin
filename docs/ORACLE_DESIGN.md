# Oracle & Epoch Report Design (Draft)

## Pipeline
Collect -> Validate -> Normalize -> Aggregate -> Sign -> Submit

## Normalization
- Adjust raw bandwidth by test duration & packet loss factor.
- Trim extreme top/bottom p% (configurable).

## Report Fields (Illustrative)
Field | Description
----- | -----------
epoch | Monotonic counter
version | Schema version
committee | Signer addresses
aggregate.total_nodes | Count included
aggregate.total_effective_bandwidth | Sum of normalized scores
merkle_root | Commitment to (node, score)
sig_bundle | Array (signer, signature)

## Signature Evolution
1. Simple multisig (M-of-N ECDSA)
2. Weighted multisig (stake weight)
3. Aggregated BLS (gas optimized)

## Failure Modes & Fallback
Mode | Fallback
---- | --------
Partial Committee | Accept if ≥ threshold & quorum metric satisfied
No Report | Use previous emission escrow or pause rewards
Invalid Root | Slash signers presenting invalid data (upon proof)

## Security Considerations
- Replay resistant nonces
- Timestamp drift tolerance window
- Distinct vantage points to avoid localized inflation