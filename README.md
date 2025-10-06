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
