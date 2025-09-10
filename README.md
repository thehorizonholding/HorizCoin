# HorizCoin

HorizCoin is a blockchain protocol implementing a Proof-of-Bandwidth consensus mechanism. This repository contains the reference implementation of the HorizCoin node software, wallet, and development tools.

## Quick Start

### Prerequisites

- Rust 1.70.0+ with Cargo
- Git
- RocksDB system dependencies (for storage features)

### Building

```bash
# Clone the repository
git clone https://github.com/thehorizonholding/HorizCoin.git
cd HorizCoin

# Set Rust version (recommended)
rustup override set 1.70.0

# Build all components
cargo build --workspace

# Run tests
cargo test --all
```

### Running the Node and CLI

```bash
# Start the HorizCoin node
cargo run -p horizcoin-node

# Use the CLI tool
cargo run -p horiz-cli -- --help
```

### Running a Local Development Network

```bash
# Start the HorizCoin node (prints banner and exits for now)
cargo run -p horizcoin-node

# Explore available CLI commands
cargo run -p horiz-cli -- --help
```

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
