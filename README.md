# HorizCoin

HorizCoin is a blockchain protocol implementing a Proof-of-Bandwidth consensus mechanism. This repository contains the reference implementation of the HorizCoin node software, wallet, and development tools.

## Quick Start

### Prerequisites

- Rust 1.70+ with Cargo
- Git

### Building

```bash
# Clone the repository
git clone https://github.com/thehorizonholding/HorizCoin.git
cd HorizCoin

# Set Rust version for project
rustup override set 1.70.0

# Build all components
cargo build --workspace

# Run the node
cargo run -p horizcoin-node

# Run the CLI (see help)
cargo run -p horiz-cli -- --help

# Run tests
cargo test
```

### Run on the Web

HorizCoin includes a web demo that can be deployed on GitHub Copilot Spaces for public access:

#### Deploy to Copilot Spaces

1. Create a new Copilot Space from this repository
2. The included Dockerfile will automatically build and run the web demo
3. Access the live demo at the provided public URL

#### Run Locally with Docker

```bash
# Build the Docker image
docker build -t horizcoin-web .

# Run the container
docker run -p 3000:3000 -e PORT=3000 horizcoin-web
```

Then visit http://localhost:3000 to see the web interface.

#### Run Locally with Cargo

```bash
# Start the web server
cargo run -p horizcoin-web

# Or specify a custom port
PORT=8080 cargo run -p horizcoin-web
```

The web interface provides:
- **/** - Project overview with version information
- **/healthz** - Health check endpoint for monitoring

### Running a Local Development Network

```bash
# Start a single-node development network
cargo run --bin horizd -- --dev

# In another terminal, create a wallet and send a transaction
cargo run --bin horiz-cli -- wallet create
cargo run --bin horiz-cli -- wallet fund --amount 1000000
cargo run --bin horiz-cli -- send --to <address> --amount 100
```

### Quick Transaction Example

```bash
# Generate a new address
ADDR=$(cargo run --bin horiz-cli -- wallet address)

# Send funds to the address
cargo run --bin horiz-cli -- send --to $ADDR --amount 1000

# Check balance
cargo run --bin horiz-cli -- balance $ADDR
```

## Architecture Overview

HorizCoin is built as a modular Rust workspace with clear separation of concerns:

### Core Components

- **primitives**: Basic types (Hash, TxId, BlockId), constants, and error handling
- **crypto**: Cryptographic primitives (secp256k1, SHA-256, bech32m addresses)
- **codec**: Canonical serialization with serde and length-prefixing
- **tx**: Transaction structure, verification, and memo handling (128-byte UTF-8 limit)
- **merkle**: Merkle tree implementation with SHA-256 and proof generation
- **block**: Block structure and validation (including timestamp skew limits)
- **state**: UTXO set management with apply/rollback capabilities
- **storage**: RocksDB backend with in-memory fallback for testing

### Network and Consensus

- **consensus**: Pluggable consensus interface with DevConsensus (PoA) for development
- **p2p**: Gossip-based networking with headers-first sync and anti-DoS protection
- **mempool**: Transaction pool with admission rules and propagation

### Applications

- **rpc**: JSON-RPC interface for external applications
- **node (horizd)**: Main node executable with configuration and logging
- **wallet + horiz-cli**: Key management, transaction building, and CLI interface

## Protocol Parameters

- **Hashing**: SHA-256 throughout the system
- **Signatures**: secp256k1 via k256 crate
- **Addresses**: bech32m encoding for forward compatibility and safety
- **Memo Limit**: 128 bytes UTF-8 with proper multi-byte boundary handling
- **Timestamp Future Skew**: +120 seconds tolerance (configurable via `TIMESTAMP_FUTURE_SKEW_SECS`)
- **Consensus**: Pluggable interface (DevConsensus for development, PoB for production)

## Development

### Testing

```bash
# Run all tests
cargo test

# Run tests with property-based testing
cargo test --features proptest

# Run integration tests
cargo test --test integration

# Run with test coverage
cargo llvm-cov --html
```

### Linting and Formatting

```bash
# Format code
cargo fmt

# Run clippy
cargo clippy --all-targets --all-features -- -D warnings

# Check documentation
cargo doc --no-deps --document-private-items
```

### Fuzzing

```bash
# Install cargo-fuzz
cargo install cargo-fuzz

# Run fuzz tests
cargo fuzz run codec_decode
cargo fuzz run tx_verify
```

## Documentation

- [Architecture Guide](docs/architecture.md) - System design and module interactions
- [Protocol Specifications](docs/protocol/) - Detailed protocol documentation
- [Contributing Guide](CONTRIBUTING.md) - Development workflow and guidelines
- [Security Policy](SECURITY.md) - Security reporting and practices

## Vercel Deployment

**Framework Detected**: Rust web application using Axum with static build generation

This repository is configured for deployment on Vercel with a static build that generates the homepage as a standalone HTML file.

### How to Deploy

1. **Automatic Preview Deployments**: Any PR will automatically create a Preview deployment on Vercel
2. **Promote to Production**: After this PR creates a successful Preview deployment:
   - Go to your Vercel dashboard
   - Find the Preview deployment for this PR
   - Click "Promote to Production" to make it live at your production domain

### Fix Current 404 Error

The production domain `https://horiz-coin.vercel.app/` currently returns 404 with `DEPLOYMENT_NOT_FOUND` because:
- The Production alias is pointing to a missing/invalid deployment
- After this PR builds as a Preview, promote it to Production in Vercel
- If Production still shows errors, go to Project → Settings → Domains and remove/re-add the domain, or simply promote the latest Ready Preview

### Local Testing

To test the static build locally:

```bash
# Generate the static build
npm install
npm run build

# Serve the static files
cd dist
python3 -m http.server 8080
# Visit http://localhost:8080
```

The static build generates the same homepage content as the Rust server but as a standalone HTML file suitable for Vercel's static hosting.

## Public deployment (AWS Lightsail)

This repository includes automation to deploy the web demo (`horizcoin-web`) to AWS Lightsail Containers and expose a public URL.

Prerequisites
- An AWS account and an IAM access key with Lightsail permissions (recommended policy: `AmazonLightsailFullAccess` for a dedicated CI user).

Repository secrets
- `AWS_ACCESS_KEY_ID` – from the IAM user
- `AWS_SECRET_ACCESS_KEY` – from the IAM user
- `AWS_REGION` – e.g., `us-east-1`
- Optional: `LIGHTSAIL_SERVICE_NAME` – defaults to `horizcoin-web`

Deploy
- Push to `main`, or
- Manually run the "Deploy to AWS Lightsail" workflow from the Actions tab (you can provide `service_name` and `region`).

Result
- After the workflow completes, the app will be available at `https://<generated>.<region>.cs.amazonlightsail.com`.
- Health check: `https://<generated>.<region>.cs.amazonlightsail.com/healthz`.

Troubleshooting
- Verify the workflow run summary for the printed public URL.
- Ensure the container listens on `PORT=3000` and `/healthz` returns HTTP 200 locally:
  ```bash
  cargo run -p horizcoin-web
  # or with Docker
  docker build -t horizcoin-web .
  docker run -p 3000:3000 -e PORT=3000 horizcoin-web
  ```

## Economic Design

HorizCoin targets a novel Proof-of-Bandwidth consensus mechanism designed for long-term sustainability. The economic model aims for $80T total economic activity over 10 years (see [issue #33](https://github.com/thehorizonholding/HorizCoin/issues/33) for detailed analysis). However, the current implementation keeps consensus pluggable and does not couple economic parameters to core hashing or validation logic.

## License

Licensed under either of

- Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
- MIT License ([LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT)

at your option.

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details on our development process, coding standards, and how to submit patches.

## Security

For security-related issues, please see [SECURITY.md](SECURITY.md) for our responsible disclosure policy.

## Support

- GitHub Issues: Bug reports and feature requests
- Discussions: General questions and community support
- Documentation: In-code documentation and guides in `docs/`
