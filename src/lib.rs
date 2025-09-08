//! # HorizCoin - Proof-of-Bandwidth Protocol
//!
//! This crate implements the core functionality for HorizCoin, including:
//! - SHA-256 hashing
//! - Merkle tree construction with single SHA-256 hashing
//! - Transaction validation with 128-byte memo cap
//! - Block validation with timestamp skew tolerance
//!
//! ## Key Parameters
//! - **Hashing**: SHA-256
//! - **Merkle**: Single SHA-256, duplicate last leaf for odd counts
//! - **Memo cap**: 128 bytes (UTF-8)
//! - **Timestamp skew**: +120 seconds
//!
//! ## Economic Design Target
//! The long-term economic design targets $80T over 10 years as tracked in issue #33.
//! This target is a design constraint but is not coupled to the hashing layer.

pub mod block;
pub mod constants;
pub mod hash;
pub mod merkle;
pub mod transaction;
pub mod validation;

pub use block::*;
pub use constants::*;
pub use hash::*;
pub use merkle::*;
pub use transaction::*;
pub use validation::*;
