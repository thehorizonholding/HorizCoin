# HorizCoin

HorizCoin – Proof-of-Bandwidth protocol implementation

## Overview

HorizCoin is a cryptocurrency implementation focused on proof-of-bandwidth consensus. This repository contains the core functionality including transaction processing, block validation, and Merkle tree construction.

## Key Parameters

The implementation enforces the following defaults:

- **Hashing**: SHA-256 (single hash, not double hash)
- **Merkle tree**: Single SHA-256 with Bitcoin-style odd-leaf duplication
- **Transaction memo cap**: 128 bytes (UTF-8)
- **Block timestamp skew tolerance**: +120 seconds future, 24 hours past

## Technical Specifications

### Hashing
- All hashing uses SHA-256
- Transaction IDs computed as `sha256(canonical_tx_bytes)`
- Merkle internal nodes computed as `sha256(left || right)`

### Merkle Tree
- Uses single SHA-256 throughout (not double-hash like Bitcoin)
- Leaves are transaction IDs (SHA-256 of transaction bytes)
- Internal nodes: `sha256(left_hash || right_hash)`
- Odd leaf count: duplicate the last leaf (Bitcoin-style duplication)

### Transaction Validation
- Memo field limited to 128 bytes UTF-8
- Multi-byte UTF-8 characters handled correctly at byte boundaries
- Basic validation checks amounts, memo length, and structure

### Block Validation
- Timestamp must be within +120 seconds of current time
- Timestamp cannot be more than 24 hours in the past
- Merkle root must match computed tree from transactions
- No duplicate transactions allowed in a block

## Economic Design

The long-term economic design targets $80T market cap over 10 years as tracked in issue #33. This target serves as a design constraint but is not coupled to the hashing layer implementation.

## Building and Testing

```bash
# Build the project
cargo build

# Run tests
cargo test

# Check code style
cargo clippy -- -D warnings
cargo fmt -- --check
```

## Usage

```rust
use horizcoin::*;

// Create a transaction
let tx = Transaction::new(
    "sender".to_string(),
    "recipient".to_string(),
    1000,  // amount
    10,    // fee
    Some("Hello world".to_string()), // memo (max 128 bytes)
    1,     // nonce
    1234567890, // timestamp
).unwrap();

// Create a block
let block = Block::new(
    [0u8; 32],  // previous block hash
    vec![tx],   // transactions
    1234567890, // timestamp
    1,          // height
);

// Validate the block
validate_block_basic(&block).unwrap();
```

## License

MIT OR Apache-2.0
