# HorizCoin Network (HZC)

> DISCLAIMER: HorizCoin is an experimental decentralized protocol for incentivizing verifiable network bandwidth contribution (“Proof of Bandwidth” / PoBW). Nothing herein constitutes (a) an offer or solicitation of securities, (b) a promise that HZC converts into equity of Google (Alphabet), Microsoft, NBCUniversal (Comcast), Meta, or any other issuer, or (c) a guarantee of ownership in any company. Brokerage, equities, or regulated financial functionality MUST be integrated only through properly licensed partners subject to KYC/AML, sanctions screening, and applicable law. Use at your own risk; unaudited code.
>
> FORWARD-LOOKING STATEMENT NOTICE: Any references to potential scale, adoption, or hypothetical economic capacity are speculative and not guarantees. The token is designed for protocol coordination and security; it is not an equity instrument or claim on external assets.

## Vision

HorizCoin aims to:
- Reward contributors for providing measurable, verifiable bandwidth & availability (PoBW)
- Aggregate challenge metrics via an oracle committee that submits signed epoch reports
- Support governance‑driven evolution (committee size, emission schedule, parameters)
- Later (separate, optional layer): integrate regulated brokerage rails so users may voluntarily acquire equities via licensed third parties. HZC itself is *not* an equity instrument.

## Repository Structure

```
.
├─ README.md
├─ LICENSE
├─ COMPLIANCE.md
├─ SECURITY_NOTES.md
├─ docs/
│  ├─ ARCHITECTURE.md
│  ├─ ROADMAP.md
│  ├─ POBW_SPEC.md
│  ├─ TOKENOMICS.md
│  ├─ GOVERNANCE.md
│  ├─ SECURITY_MODEL.md
│  ├─ MATURITY_MODEL.md
│  ├─ LAUNCH_CHECKLIST.md
│  ├─ TOKEN_UTILITY_MATRIX.md
│  ├─ ORACLE_DESIGN.md
│  ├─ SECURITY_TESTING_PLAN.md
│  ├─ KEY_MANAGEMENT.md
│  ├─ OPERATIONS_RUNBOOK.md
│  └─ COMMUNICATIONS_POLICY.md
├─ risk/
│  └─ RISK_REGISTER.md
├─ contracts/
│  ├─ foundry.toml
│  ├─ README.md
│  └─ src/
│     └─ token/
│        └─ HorizCoinToken.sol
├─ oracle/
│  └─ node/
│     └─ main.go
├─ backend/
│  ├─ package.json
│  └─ api/
│     └─ server.ts
├─ package.json
└─ .gitignore
```

## Quick Start (Contracts)

```bash
cd contracts
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge build
forge test
```

## Current Status

STATUS: PRE-ALPHA  
- Threshold sig verification: NOT IMPLEMENTED  
- Oracle staking / slashing: NOT IMPLEMENTED  
- Real bandwidth challenge protocol: PLACEHOLDER  
- Not audited: DO NOT USE IN PRODUCTION

## Initial Task Board

| Priority | Task |
|----------|------|
| P0 | Confirm final emission curve in TOKENOMICS.md |
| P0 | Implement EpochReportRegistry contract |
| P1 | Oracle report signature aggregation verification |
| P1 | PoBW challenge simulation prototype |
| P1 | Invariant & fuzz tests |
| P2 | Device / node attestation design |
| P2 | Governance parameter bounding & quorum |
| P3 | External security audit |
| P3 | Brokerage partner technical due diligence (later) |

## Naming

- Token: HorizCoin
- Symbol: HZC (modifiable pre‑TGE)
- Governance Variant: ERC20Votes (future extension)

## Contributing

All changes via Pull Request + review. Security-impacting changes must update docs/SECURITY_MODEL.md.

## License

Distributed under the MIT License. See LICENSE.