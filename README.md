# HorizCoin

An open, modular cryptocurrency project with fast deployment, global market connectivity, and optional payments + exchange scaffolding. The repo ships with production-friendly microservices, local orchestration, and CI/CD so you can go from code to public endpoints quickly.

- Public web + APIs you can deploy in minutes (server, pricing, CoinGecko proxy)
- Market integrations to get priced after mining (DEX → aggregators like CoinGecko)
- Optional payments and exchange scaffolding (ledger, fiat gateway, SWIFT adapter, matching engine)
- Secure supply chain: CI matrix builds, CodeQL, SBOM, Dependabot
- GHCR multi-arch image publishing with provenance and signing

## Repository structure

```
.
├─ services/
│  ├─ pricing-api/        # Aggregates prices from multiple sources (e.g., CoinGecko, Binance)
│  ├─ coingecko-api/      # Minimal CoinGecko proxy with caching
│  ├─ ledger/             # Double-entry ledger (idempotent postings)
│  ├─ payments-gateway/   # Fiat rails abstraction (connector-based; stub included)
│  ├─ swift-adapter/      # ISO20022 pain.001 XML generator (for bank/service-bureau integration)
│  └─ exchange-engine/    # Minimal limit order book + matching engine
├─ docs/
│  ├─ markets/            # Listing playbook, exchange checklist
│  ├─ payments/           # Payments + SWIFT architecture
│  ├─ compliance/         # Licensing and partnerships notes
│  ├─ exchange/           # Exchange architecture
│  └─ TECH_STACK.md       # Platform/tooling overview
├─ .github/workflows/     # CI matrix, CodeQL, SBOM, GHCR publisher
├─ docker-compose.yml     # Local multi-service orchestration
├─ Makefile / Justfile    # Common developer tasks
└─ .devcontainer/         # VS Code DevContainer for consistent dev env
```

## Key capabilities

- Global markets and pricing
  - Deployable HTTP server with health checks for quick public demos
  - Pricing API to aggregate market quotes and expose a stable endpoint
  - CoinGecko proxy service with small in-memory caching for rate-limit friendliness

- Post-mining path to global visibility
  - DEX-first liquidity (e.g., HORIZ/USDC)
  - Aggregator submissions (CoinGecko, CMC), exchange outreach checklist
  - Playbooks in docs/markets for a fast and safe listing process

- Optional payments and exchange scaffolding
  - Double-entry ledger with idempotent postings
  - Payments gateway abstraction for ACH/SEPA/wires/cards via providers or sponsor banks
  - SWIFT-like adapter generating ISO 20022 pain.001 from internal payment instructions
  - Minimal exchange matching engine with idempotent order intake

- Platform and supply chain
  - CI builds on Rust 1.70 for all services
  - CodeQL security scanning, Dependabot updates
  - SBOM (CycloneDX) generation
  - Multi-arch GHCR images with provenance and optional keyless signatures

## Quick start

Prerequisites
- Rust toolchain 1.70.0
- Docker and Docker Compose (or Colima/OrbStack on macOS)
- GitHub CLI (optional) for PRs and CI interactions

Build and run locally
```bash
# Set Rust toolchain and build
make toolchain build

# Build all services and start the local stack
make services-build
make compose-up

# Tear down when done
make compose-down
```

Or run a single service (example: pricing-api)
```bash
cd services/pricing-api
cargo run

# Health
curl -s http://localhost:8081/healthz

# Price (after setting envs post-listing)
export COINGECKO_ID=horizcoin
export BINANCE_PAIR=HORIZUSDT
curl -s "http://localhost:8081/v1/price?symbol=HORIZ&vs=USD" | jq
```

## Services and endpoints

- pricing-api (default port 8081)
  - GET /healthz
  - GET /v1/price?symbol=HORIZ&vs=USD
  - Env: COINGECKO_ID, BINANCE_PAIR

- coingecko-api (default port 8082)
  - GET /healthz
  - GET /v1/simple_price?ids=horizcoin&vs=usd
  - GET /v1/coins/:id/market_chart?vs=usd&days=7
  - Env: COINGECKO_BASE_URL, CG_DEFAULT_IDS, CG_DEFAULT_VS

- ledger (default port 8090)
  - GET /healthz
  - POST /v1/accounts
  - POST /v1/postings
  - GET /v1/balances/:account/:currency

- payments-gateway (default port 8091)
  - GET /healthz
  - POST /v1/payouts
  - Connector interface ready; example stub provided (replace with real provider)

- swift-adapter (default port 8092)
  - GET /healthz
  - POST /v1/pain001 → returns a simplified ISO 20022 payment initiation XML (demo)

- exchange-engine (default port 8093)
  - GET /healthz
  - POST /v1/orders (limit orders; idempotent intake; simple matching demo)

Note: Ports shown match the docker-compose defaults; adjust via PORT env where required.

## CI/CD and images

- CI matrix builds for each service: .github/workflows/ci-matrix.yml
- CodeQL security scanning: .github/workflows/codeql.yml
- SBOM generation: .github/workflows/sbom.yml
- GHCR publishing: .github/workflows/ghcr-publish.yml
  - Images: ghcr.io/thehorizonholding/horizcoin-<service>
  - Architectures: linux/amd64, linux/arm64
  - Tags: edge (main), sha-<gitsha>, semver (vX.Y.Z), pr-<number> for PR builds
  - Provenance and SBOM attached; optional Cosign keyless signatures on tag builds

Example usage
```bash
docker pull ghcr.io/thehorizonholding/horizcoin-pricing-api:edge
docker run --rm -p 8081:8081 ghcr.io/thehorizonholding/horizcoin-pricing-api:edge
```

## Listing and pricing workflow (post-mining)

- Seed initial DEX liquidity (e.g., Uniswap v3 HORIZ/USDC) for price discovery
- Submit to aggregators:
  - CoinGecko: contract addresses, socials, website, pools
  - CoinMarketCap: similar; expect KYC and technical validation
- Turn on adapters in pricing-api by setting COINGECKO_ID and/or BINANCE_PAIR
- See docs:
  - docs/markets/LISTING.md
  - docs/markets/EXCHANGE_CHECKLIST.md

## Compliance and SWIFT

- For real fiat connectivity (ACH/SEPA/wires/SWIFT) you need a sponsor bank/BaaS and appropriate licensing (EMI/PI, MTL, or agency model)
- The swift-adapter builds ISO 20022 messages; production submission/status flows are via your bank/service bureau APIs
- See docs:
  - docs/payments/ARCHITECTURE.md
  - docs/compliance/LICENSING.md

Legal/compliance disclaimer: The payments and exchange components are provided as technical scaffolding. Operating them in production requires appropriate licensing, compliance programs, risk controls, and vetted partners.

## Development environment

- DevContainer for VS Code/Codespaces: .devcontainer/devcontainer.json
- Makefile and Justfile for common tasks:
  - make toolchain | build | test | services-build | compose-up | compose-down
- EditorConfig for consistent formatting
- Dependabot for automated dependency update PRs

## Roadmap (high level)

- Public web server enhancements (status, docs, auth)
- Pricing: additional adapters and staleness/alerting
- Payments: provider connectors (Wise, Currencycloud, Stripe Treasury, bank APIs)
- Exchange: persistence, per-order queues, websockets, market data streams
- Security: SLSA provenance + image signing policies; SBOM consumption
- Observability: structured logs, metrics, and traces across services

## Contributing

Contributions welcome. Please open issues/PRs with clear descriptions. For security-sensitive topics, prefer responsible disclosure channels.

## License

MIT

# HorizCoin Monorepo — HorizWallet Ecosystem

A modern, non‑custodial wallet suite for HorizCoin and EVM chains. This monorepo contains:
- Browser Extension (MV3) — onboarding, approvals, portfolio
- Mobile App (React Native, Expo) — onboarding and account view
- Dapp SDK — injected EIP‑1193 provider and helpers
- Core cryptography/signing — BIP‑39/32/44, EIP‑1559, EIP‑712
- Assets module — ERC‑20 discovery, balances, watchlist
- WalletConnect v2 scaffolding — QR pairing and deep links
- Docs, demo dapp, CI, and shared tooling

Track progress under the epic: [#120](https://github.com/thehorizonholding/HorizCoin/issues/120)

---

## Status

Merged
- Monorepo scaffolding with pnpm workspaces and CI
- Core + SDK + Extension vertical slice: PR [#132](https://github.com/thehorizonholding/HorizCoin/pull/132)
  - wallet-core: BIP‑39/32/44, EIP‑1559 signing, EIP‑712 typed‑data signing, in‑memory vault with auto‑lock
  - wallet-sdk: EIP‑1193 provider injection (connect/accounts/chain switch, sendTransaction, signTypedData), demo dapp integration
  - Extension (MV3): onboarding (create/import), first account address + Sepolia balance, approvals for connect/sign
- Mobile MVP (React Native, Expo): PR [#133](https://github.com/thehorizonholding/HorizCoin/pull/133)
  - Onboarding/import, account view with Sepolia balance, basic settings (auto‑lock)

In progress (open PRs)
- Assets: ERC‑20 portfolio basics (watchlist, balances, portfolio UI): PR [#134](https://github.com/thehorizonholding/HorizCoin/pull/134), progresses [#125](https://github.com/thehorizonholding/HorizCoin/issues/125)
- WalletConnect v2 scaffolding (QR + deep links, sessions): PR [#135](https://github.com/thehorizonholding/HorizCoin/pull/135), progresses [#129](https://github.com/thehorizonholding/HorizCoin/issues/129)

Planned
- Transaction simulation and risk flags: [#128](https://github.com/thehorizonholding/HorizCoin/issues/128)
- Swaps/bridges adapters and flows: [#126](https://github.com/thehorizonholding/HorizCoin/issues/126)
- Hardware wallets (Ledger/Trezor): [#127](https://github.com/thehorizonholding/HorizCoin/issues/127)
- Account abstraction (ERC‑4337): [#130](https://github.com/thehorizonholding/HorizCoin/issues/130)
- Extension polish to close out: [#122](https://github.com/thehorizonholding/HorizCoin/issues/122)

---

## Monorepo layout

- packages/
  - wallet-core — cryptography, HD derivation, signing, vault abstraction
  - wallet-sdk — injected EIP‑1193 provider + dapp helpers
  - wallet-assets — token list parsing, ERC‑20 metadata validation, balances, watchlist persistence, spam heuristics
- apps/
  - extension — MV3 extension (service worker, UI, content script), onboarding, account, approvals, portfolio
  - mobile — React Native (Expo) app, onboarding and account view
- examples/
  - demo-dapp — sample dapp using injected EIP‑1193 provider for connect, accounts, signTypedData, sendTransaction
- docs/wallet/
  - DEVELOPMENT.md, SECURITY.md, OVERVIEW.md, ARCHITECTURE.md, ASSETS.md, WALLETCONNECT.md

---

## Quick start

Prerequisites
- Node 18+, pnpm, Git, Chrome (for extension), iOS/Android simulators or devices (for mobile, via Expo)

Install and build
```bash
pnpm i
pnpm -w build
```

Run the browser extension (dev)
```bash
pnpm --filter @horiz/extension dev
```
- In Chrome: open chrome://extensions → Enable Developer mode → Load unpacked → select apps/extension/dist
- The extension is named “HorizWallet (Dev)”

Run the demo dapp
```bash
pnpm --filter demo-dapp dev
```
- Open in browser and connect to “HorizWallet (Dev)”

Run the mobile app (Expo)
```bash
pnpm --filter @horiz/wallet-mobile start
```
- Follow Expo prompts to launch on iOS/Android simulator or device

Run tests and lint
```bash
pnpm -w test
pnpm -w lint
```

---

## Configuration

Default network
- Ethereum Sepolia via public RPC (no keys required)
- Override via environment variables; see docs/wallet/DEVELOPMENT.md

Environment variables (examples)
- RPC and chain
  - WALLET_RPC_SEPOLIA_URL=https://ethereum-sepolia.publicnode.com
- WalletConnect v2 (feature‑gated)
  - HORIZWALLET_FEATURE_WC=true
  - WALLETCONNECT_PROJECT_ID=<your_project_id>
  - WALLETCONNECT_RELAY_URL=wss://relay.walletconnect.com

Create a .env or use your shell environment to provide these values. No production secrets should be committed.

---

## Features

Implemented
- Non‑custodial seed management (BIP‑39/32/44 derivation)
- Signing: EIP‑1559 transactions and EIP‑712 typed data
- EIP‑1193 provider SDK and injected provider for dapps
- Extension onboarding and approvals for connect/sign
- Mobile onboarding and account view with live Sepolia balance

In progress
- ERC‑20 assets: discovery, watchlist, balances, portfolio UI (extension)
- WalletConnect v2 scaffolding: QR code pairing (desktop), deep links (mobile), session lifecycle

Planned
- Transaction simulation and risk flags prior to approval
- Swaps and bridges integrations with modular adapters
- Hardware wallet support (WebHID/WebUSB, native bridges)
- Account abstraction (ERC‑4337) with bundler/paymaster UX

---

## Architecture

Components and responsibilities
- wallet-core
  - BIP‑39/32/44 mnemonic and HD derivation
  - Signing: EIP‑1559 transactions, EIP‑712 typed data
  - In‑memory vault with auto‑lock timer; keystore/hardware TODO hooks
- wallet-sdk
  - Injected EIP‑1193 provider with permissions
  - Request routing to approvals UI (connect/sign/send)
  - Dapp helpers and types
- wallet-assets
  - Token list parsing and contract validation (decimals/symbol)
  - ERC‑20 balance fetching with caching and rate limiting
  - Watchlist persistence, spam heuristics and denylist stubs
- apps/extension (MV3)
  - Service worker background, React UI, content script for injection
  - Onboarding, account, approvals drawer, portfolio screen
- apps/mobile (Expo)
  - Navigation, onboarding/import, account view, settings
  - Deep link handler for WalletConnect

High‑level flow
1) Dapp → Injected Provider (EIP‑1193)
2) Provider → Extension approval UI (connect/sign/send)
3) Approved request → wallet-core signing → RPC submission
4) Assets module refreshes balances/metadata for portfolio
5) WalletConnect path: dapp QR/deep link → session → approvals → request handling via wallet-sdk → signing/RPC

Build tooling and CI
- pnpm workspaces, shared tsconfig/eslint/jest setup
- GitHub Actions workflow builds, lints, and tests packages and extension on PRs
- Mobile CI runs lint/build steps (no store publishing)

---

## Security model

- In‑memory secrets: no persistent storage by default; auto‑lock clears vault
- Strict origin checks and explicit user approvals for connect/sign
- Redacted logs; minimal telemetry
- No production keys committed; env‑based configuration only
- Future work: OS keystore integration, hardware wallets, transaction simulation and risk analysis
- See docs/wallet/SECURITY.md for details

---

## Roadmap & tracking

- Epic: [#120](https://github.com/thehorizonholding/HorizCoin/issues/120)
- Sub‑issues:
  - Core: [#121](https://github.com/thehorizonholding/HorizCoin/issues/121) — delivered
  - Extension: [#122](https://github.com/thehorizonholding/HorizCoin/issues/122)
  - Mobile: [#123](https://github.com/thehorizonholding/HorizCoin/issues/123) — MVP delivered
  - Provider/SDK: [#124](https://github.com/thehorizonholding/HorizCoin/issues/124) — delivered
  - Tokens/NFTs: [#125](https://github.com/thehorizonholding/HorizCoin/issues/125) — in progress
  - Swaps/Bridges: [#126](https://github.com/thehorizonholding/HorizCoin/issues/126)
  - Hardware wallets: [#127](https://github.com/thehorizonholding/HorizCoin/issues/127)
  - Simulation/Risk: [#128](https://github.com/thehorizonholding/HorizCoin/issues/128)
  - WalletConnect v2: [#129](https://github.com/thehorizonholding/HorizCoin/issues/129) — in progress
  - Account Abstraction (ERC‑4337): [#130](https://github.com/thehorizonholding/HorizCoin/issues/130)

Recent PRs
- Core + SDK + Extension vertical slice: [#132](https://github.com/thehorizonholding/HorizCoin/pull/132) (merged)
- Mobile MVP: [#133](https://github.com/thehorizonholding/HorizCoin/pull/133) (merged)
- Assets: [#134](https://github.com/thehorizonholding/HorizCoin/pull/134) (open)
- WalletConnect v2: [#135](https://github.com/thehorizonholding/HorizCoin/pull/135) (open)
- README overhaul: [#136](https://github.com/thehorizonholding/HorizCoin/pull/136) (open)

---

## Contributing

- Read docs/wallet/DEVELOPMENT.md for environment and commands
- Use conventional commits if possible (feat:, fix:, docs:, chore:, etc.)
- Open an issue or PR; CI will run lint/build/tests
- Please avoid committing secrets or production credentials

---

## License

- Individual packages are MIT‑licensed (see each package.json "license")
- Repository‑level licensing TBD

---

## Acknowledgements

Built on the EVM ecosystem and standards including EIP‑1193 (Provider), EIP‑1559 (Transactions), EIP‑712 (Typed Data), and ERC‑4337 (Account Abstraction). Thanks to open‑source tooling in the Ethereum and React Native communities.

---

For development use only. Do not store or commit production secrets.
