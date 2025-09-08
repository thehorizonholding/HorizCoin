//! # HorizCoin Core
//!
//! This crate provides the fundamental data structures and validation logic
//! for the HorizCoin blockchain. It implements the core types needed for
//! transactions, hashing, and basic validation.
//!
//! ## Features
//!
//! - **Hash utilities**: 32-byte hash type with SHA-256 support and hex encoding
//! - **Transaction model**: Simple transfer transactions with validation
//! - **Serialization**: JSON and binary serialization support via serde
//! - **Type safety**: Strong typing to prevent common mistakes
//!
//! ## Quick Start
//!
//! ```rust
//! use horizcoin::{Hash, Transaction, TransactionBuilder, Hashable};
//!
//! // Create addresses
//! let from = [1u8; 32];
//! let to = [2u8; 32];
//!
//! // Build a transaction
//! let tx = TransactionBuilder::new()
//!     .from(from)
//!     .to(to)
//!     .amount(100)
//!     .fee(10)
//!     .nonce(1)
//!     .build_unsigned()
//!     .expect("Valid transaction");
//!
//! // Validate the transaction
//! tx.validate().expect("Transaction should be valid");
//!
//! // Get the transaction hash
//! let hash = tx.hash();
//! println!("Transaction hash: {}", hash);
//! ```
//!
//! ## Architecture
//!
//! The crate is organized into the following modules:
//!
//! - [`hash`]: Hash utilities and the core Hash type
//! - [`tx`]: Transaction types and validation logic
//!
//! ## Error Handling
//!
//! The crate uses structured error types with [`thiserror`] for all operations
//! that can fail. All errors implement the standard [`std::error::Error`] trait.

#![deny(missing_docs)]
#![warn(clippy::all)]

pub mod hash;
pub mod tx;

// Re-export commonly used types for convenience
pub use hash::{Hash, HashError, Hashable, hash_data, hash_bytes, hash_concat};
pub use tx::{Transaction, TransactionBuilder, TransactionError, UnsignedTransaction};

/// Current version of the HorizCoin protocol
pub const PROTOCOL_VERSION: u32 = 1;

/// Maximum transaction size in bytes (1 MB)
pub const MAX_TRANSACTION_SIZE: usize = 1024 * 1024;

/// Minimum transaction fee (1 unit)
pub const MIN_TRANSACTION_FEE: u64 = 1;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_full_workflow() {
        // Create test addresses
        let from = [1u8; 32];
        let to = [2u8; 32];

        // Create an unsigned transaction
        let tx = TransactionBuilder::new()
            .from(from)
            .to(to)
            .amount(1000)
            .fee(MIN_TRANSACTION_FEE)
            .nonce(42)
            .build_unsigned()
            .expect("Should create valid transaction");

        // Validate the transaction
        tx.validate().expect("Transaction should be valid");

        // Get the hash for signing
        let _tx_hash = tx.unsigned_data().hash();
        
        // Simulate signing (in real implementation, this would be cryptographic signing)
        let signature = vec![0x42u8; 64]; // Mock signature
        
        // Create signed transaction
        let signed_tx = tx.with_signature(signature);
        assert!(signed_tx.is_signed());

        // Validate the signed transaction
        signed_tx.validate().expect("Signed transaction should be valid");

        // Test serialization
        let json = serde_json::to_string(&signed_tx).expect("Should serialize to JSON");
        let deserialized: Transaction = serde_json::from_str(&json).expect("Should deserialize from JSON");
        assert_eq!(signed_tx, deserialized);

        // Test hash consistency
        assert_eq!(signed_tx.hash(), deserialized.hash());
    }

    #[test]
    fn test_hash_operations() {
        // Test hash creation and conversion
        let data = b"Hello, HorizCoin!";
        let hash1 = hash_bytes(data);
        let hash2 = hash_bytes(data);
        assert_eq!(hash1, hash2);

        // Test hex conversion
        let hex_str = hash1.to_hex();
        let hash3 = Hash::from_hex(&hex_str).expect("Should parse hex");
        assert_eq!(hash1, hash3);

        // Test zero hash
        let zero = Hash::zero();
        assert!(zero.is_zero());
        assert_ne!(hash1, zero);
    }

    #[test]
    fn test_transaction_edge_cases() {
        let from = [1u8; 32];
        let to = [2u8; 32];

        // Test maximum values
        let max_tx = TransactionBuilder::new()
            .from(from)
            .to(to)
            .amount(u64::MAX - 1000) // Leave room for fee
            .fee(1000)
            .nonce(u64::MAX)
            .build_unsigned()
            .expect("Should create transaction with max values");

        max_tx.validate().expect("Max value transaction should be valid");

        // Test minimum values
        let min_tx = TransactionBuilder::new()
            .from(from)
            .to(to)
            .amount(1)
            .fee(0) // Zero fee should be allowed (though not recommended)
            .nonce(0)
            .build_unsigned()
            .expect("Should create transaction with min values");

        min_tx.validate().expect("Min value transaction should be valid");
    }
}