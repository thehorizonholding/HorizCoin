//! Hash utilities and types for HorizCoin
//!
//! This module provides a 32-byte hash type with utilities for SHA-256 hashing,
//! hex encoding/decoding, and a trait for hashing arbitrary serializable types.

use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::fmt;
use thiserror::Error;

/// A 32-byte hash value used throughout HorizCoin
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct Hash([u8; 32]);

/// Errors that can occur during hash operations
#[derive(Debug, Error)]
pub enum HashError {
    /// Invalid hex string format
    #[error("Invalid hex string: {0}")]
    InvalidHex(#[from] hex::FromHexError),
    /// Invalid hash length (must be 32 bytes)
    #[error("Invalid hash length: expected 32 bytes, got {0}")]
    InvalidLength(usize),
}

impl Hash {
    /// Create a new Hash from a 32-byte array
    pub fn new(bytes: [u8; 32]) -> Self {
        Hash(bytes)
    }

    /// Create a Hash from a slice of bytes
    pub fn from_bytes(bytes: &[u8]) -> Result<Self, HashError> {
        if bytes.len() != 32 {
            return Err(HashError::InvalidLength(bytes.len()));
        }
        let mut array = [0u8; 32];
        array.copy_from_slice(bytes);
        Ok(Hash(array))
    }

    /// Create a Hash from a hex string
    pub fn from_hex(hex_str: &str) -> Result<Self, HashError> {
        let bytes = hex::decode(hex_str)?;
        Self::from_bytes(&bytes)
    }

    /// Get the bytes of this hash
    pub fn as_bytes(&self) -> &[u8; 32] {
        &self.0
    }

    /// Convert to a hex string
    pub fn to_hex(&self) -> String {
        hex::encode(self.0)
    }

    /// Create a zero hash (all bytes are 0)
    pub fn zero() -> Self {
        Hash([0u8; 32])
    }

    /// Check if this is a zero hash
    pub fn is_zero(&self) -> bool {
        self.0 == [0u8; 32]
    }
}

impl fmt::Display for Hash {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.to_hex())
    }
}

impl From<[u8; 32]> for Hash {
    fn from(bytes: [u8; 32]) -> Self {
        Hash(bytes)
    }
}

impl From<Hash> for [u8; 32] {
    fn from(hash: Hash) -> Self {
        hash.0
    }
}

impl AsRef<[u8]> for Hash {
    fn as_ref(&self) -> &[u8] {
        &self.0
    }
}

/// Trait for types that can be hashed using SHA-256
pub trait Hashable {
    /// Compute the SHA-256 hash of this object
    fn hash(&self) -> Hash;
}

/// Hash arbitrary serializable data using SHA-256
pub fn hash_data<T: Serialize>(data: &T) -> anyhow::Result<Hash> {
    let serialized = bincode::serialize(data)?;
    let hash_bytes = Sha256::digest(&serialized);
    Ok(Hash::from_bytes(&hash_bytes)?)
}

/// Hash raw bytes using SHA-256
pub fn hash_bytes(data: &[u8]) -> Hash {
    let hash_bytes = Sha256::digest(data);
    Hash::from_bytes(&hash_bytes).expect("SHA-256 always produces 32 bytes")
}

/// Hash multiple byte slices together using SHA-256
pub fn hash_concat(data: &[&[u8]]) -> Hash {
    let mut hasher = Sha256::new();
    for chunk in data {
        hasher.update(chunk);
    }
    let hash_bytes = hasher.finalize();
    Hash::from_bytes(&hash_bytes).expect("SHA-256 always produces 32 bytes")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_hash_creation_and_conversion() {
        let bytes = [1u8; 32];
        let hash = Hash::new(bytes);
        assert_eq!(hash.as_bytes(), &bytes);
        assert_eq!(hash.to_hex().len(), 64); // 32 bytes = 64 hex chars
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
        assert!(Hash::from_hex("0123456789abcdef").is_err()); // too short
    }

    #[test]
    fn test_zero_hash() {
        let zero = Hash::zero();
        assert!(zero.is_zero());
        assert_eq!(zero.to_hex(), "0000000000000000000000000000000000000000000000000000000000000000");
    }

    #[test]
    fn test_hash_bytes() {
        let data = b"hello world";
        let hash1 = hash_bytes(data);
        let hash2 = hash_bytes(data);
        assert_eq!(hash1, hash2); // Same input should produce same hash
        
        let different_data = b"hello world!";
        let hash3 = hash_bytes(different_data);
        assert_ne!(hash1, hash3); // Different input should produce different hash
    }

    #[test]
    fn test_hash_data_serializable() {
        #[derive(Serialize)]
        struct TestData {
            value: u64,
            name: String,
        }

        let data1 = TestData { value: 42, name: "test".to_string() };
        let data2 = TestData { value: 42, name: "test".to_string() };
        let data3 = TestData { value: 43, name: "test".to_string() };

        let hash1 = hash_data(&data1).unwrap();
        let hash2 = hash_data(&data2).unwrap();
        let hash3 = hash_data(&data3).unwrap();

        assert_eq!(hash1, hash2); // Same data should produce same hash
        assert_ne!(hash1, hash3); // Different data should produce different hash
    }

    #[test]
    fn test_hash_concat() {
        let data1 = b"hello";
        let data2 = b"world";
        
        let hash1 = hash_concat(&[data1, data2]);
        let hash2 = hash_concat(&[data1, data2]);
        let hash3 = hash_concat(&[data2, data1]); // Different order
        
        assert_eq!(hash1, hash2);
        assert_ne!(hash1, hash3); // Order matters
    }
}