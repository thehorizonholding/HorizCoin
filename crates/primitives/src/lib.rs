//! HorizCoin primitives crate providing basic types, constants, and error handling.
//!
//! This crate defines the fundamental types used throughout the HorizCoin blockchain,
//! including hash types, transaction IDs, block IDs, and core error types.

use serde::{Deserialize, Serialize};
use std::fmt;

/// Length of SHA-256 hash in bytes
pub const HASH_LENGTH: usize = 32;

/// Block ID type - SHA-256 hash
#[derive(Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct BlockId([u8; HASH_LENGTH]);

impl BlockId {
    /// Create a new BlockId from bytes
    pub fn new(bytes: [u8; HASH_LENGTH]) -> Self {
        Self(bytes)
    }

    /// Get the inner bytes
    pub fn as_bytes(&self) -> &[u8; HASH_LENGTH] {
        &self.0
    }

    /// Convert to hex string
    pub fn to_hex(&self) -> String {
        hex::encode(self.0)
    }

    /// Parse from hex string
    pub fn from_hex(hex_str: &str) -> Result<Self, HorizError> {
        let bytes = hex::decode(hex_str)
            .map_err(|_| HorizError::InvalidHex)?;
        if bytes.len() != HASH_LENGTH {
            return Err(HorizError::InvalidHashLength);
        }
        let mut array = [0u8; HASH_LENGTH];
        array.copy_from_slice(&bytes);
        Ok(Self(array))
    }
}

impl fmt::Debug for BlockId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "BlockId({})", self.to_hex())
    }
}

impl fmt::Display for BlockId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.to_hex())
    }
}

/// Transaction ID type - SHA-256 hash
#[derive(Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct TxId([u8; HASH_LENGTH]);

impl TxId {
    /// Create a new TxId from bytes
    pub fn new(bytes: [u8; HASH_LENGTH]) -> Self {
        Self(bytes)
    }

    /// Get the inner bytes
    pub fn as_bytes(&self) -> &[u8; HASH_LENGTH] {
        &self.0
    }

    /// Convert to hex string
    pub fn to_hex(&self) -> String {
        hex::encode(self.0)
    }

    /// Parse from hex string
    pub fn from_hex(hex_str: &str) -> Result<Self, HorizError> {
        let bytes = hex::decode(hex_str)
            .map_err(|_| HorizError::InvalidHex)?;
        if bytes.len() != HASH_LENGTH {
            return Err(HorizError::InvalidHashLength);
        }
        let mut array = [0u8; HASH_LENGTH];
        array.copy_from_slice(&bytes);
        Ok(Self(array))
    }
}

impl fmt::Debug for TxId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "TxId({})", self.to_hex())
    }
}

impl fmt::Display for TxId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.to_hex())
    }
}

/// Generic hash type - SHA-256 hash
#[derive(Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct Hash([u8; HASH_LENGTH]);

impl Hash {
    /// Create a new Hash from bytes
    pub fn new(bytes: [u8; HASH_LENGTH]) -> Self {
        Self(bytes)
    }

    /// Get the inner bytes
    pub fn as_bytes(&self) -> &[u8; HASH_LENGTH] {
        &self.0
    }

    /// Convert to hex string
    pub fn to_hex(&self) -> String {
        hex::encode(self.0)
    }

    /// Parse from hex string
    pub fn from_hex(hex_str: &str) -> Result<Self, HorizError> {
        let bytes = hex::decode(hex_str)
            .map_err(|_| HorizError::InvalidHex)?;
        if bytes.len() != HASH_LENGTH {
            return Err(HorizError::InvalidHashLength);
        }
        let mut array = [0u8; HASH_LENGTH];
        array.copy_from_slice(&bytes);
        Ok(Self(array))
    }

    /// Zero hash (all zeros)
    pub fn zero() -> Self {
        Self([0u8; HASH_LENGTH])
    }
}

impl fmt::Debug for Hash {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "Hash({})", self.to_hex())
    }
}

impl fmt::Display for Hash {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.to_hex())
    }
}

/// Core error types for HorizCoin
#[derive(Debug, Clone, PartialEq, Eq, thiserror::Error)]
pub enum HorizError {
    /// Invalid hex string
    #[error("Invalid hex string")]
    InvalidHex,
    
    /// Invalid hash length
    #[error("Invalid hash length")]
    InvalidHashLength,
    
    /// Serialization error
    #[error("Serialization error: {0}")]
    Serialization(String),
    
    /// Cryptographic error
    #[error("Cryptographic error: {0}")]
    Crypto(String),
    
    /// Invalid transaction
    #[error("Invalid transaction: {0}")]
    InvalidTransaction(String),
    
    /// Invalid block
    #[error("Invalid block: {0}")]
    InvalidBlock(String),
    
    /// Storage error
    #[error("Storage error: {0}")]
    Storage(String),
    
    /// Network error
    #[error("Network error: {0}")]
    Network(String),
    
    /// Generic error
    #[error("Error: {0}")]
    Generic(String),
}

/// Amount type for HorizCoin values (satoshi-like precision)
pub type Amount = u64;

/// Protocol constants
pub mod constants {
    /// Maximum memo length in bytes (UTF-8)
    pub const MAX_MEMO_LENGTH: usize = 128;
    
    /// Timestamp future skew tolerance in seconds
    pub const TIMESTAMP_FUTURE_SKEW_SECS: u64 = 120;
    
    /// Genesis block timestamp
    pub const GENESIS_TIMESTAMP: u64 = 1640995200; // 2022-01-01 00:00:00 UTC
    
    /// Target block time in seconds
    pub const TARGET_BLOCK_TIME: u64 = 60;
    
    /// Initial block reward
    pub const INITIAL_BLOCK_REWARD: super::Amount = 1_000_000; // 1 HorizCoin
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_hash_creation_and_display() {
        let bytes = [1u8; 32];
        let hash = Hash::new(bytes);
        assert_eq!(hash.as_bytes(), &bytes);
        assert_eq!(hash.to_hex().len(), 64); // 32 bytes * 2 hex chars
    }

    #[test]
    fn test_hash_from_hex() {
        let hex_str = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
        let hash = Hash::from_hex(hex_str).unwrap();
        assert_eq!(hash.to_hex(), hex_str);
    }

    #[test]
    fn test_hash_from_invalid_hex() {
        assert!(Hash::from_hex("invalid").is_err());
        assert!(Hash::from_hex("0123").is_err()); // too short
    }

    #[test]
    fn test_block_id_creation() {
        let bytes = [2u8; 32];
        let block_id = BlockId::new(bytes);
        assert_eq!(block_id.as_bytes(), &bytes);
    }

    #[test]
    fn test_tx_id_creation() {
        let bytes = [3u8; 32];
        let tx_id = TxId::new(bytes);
        assert_eq!(tx_id.as_bytes(), &bytes);
    }

    #[test]
    fn test_zero_hash() {
        let zero = Hash::zero();
        assert_eq!(zero.as_bytes(), &[0u8; 32]);
    }

    #[test]
    fn test_constants() {
        assert_eq!(constants::MAX_MEMO_LENGTH, 128);
        assert_eq!(constants::TIMESTAMP_FUTURE_SKEW_SECS, 120);
        assert_eq!(constants::TARGET_BLOCK_TIME, 60);
    }
}
