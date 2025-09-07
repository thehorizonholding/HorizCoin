# Security Notes

DO NOT deploy contracts controlling real value before:
1. Formal third-party audits
2. Completed fuzzing/invariant suite
3. Governance + pause mechanism finalization
4. Key management runbooks

## Reporting
(Define responsible disclosure email or form before public testnet.)

## Temporary Safeguards
- Until decentralized governance matures, a limited-scope multisig may control upgrade / pause for narrowly-defined critical functions. Sunset date must be published.

## Known Missing Items
- No reentrancy-sensitive external calls yet (token is simple), but future reward distribution may introduce complexity.
- No signature aggregation verification implemented (oracle path incomplete).