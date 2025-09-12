//! Cryptographic primitives for HorizCoin.
//!
//! This crate provides cryptographic functionality including hashing, signatures,
//! and address encoding for the HorizCoin blockchain.

use horizcoin_primitives::{Hash, HorizError};
use k256::ecdsa::{signature::Signer, signature::Verifier, Signature, SigningKey, VerifyingKey};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

/// SHA-256 hashing function
pub fn sha256(data: &[u8]) -> Hash {
    let mut hasher = Sha256::new();
    hasher.update(data);
    let result = hasher.finalize();
    Hash::new(result.into())
}

/// Double SHA-256 hashing (Bitcoin-style)
pub fn double_sha256(data: &[u8]) -> Hash {
    let first = sha256(data);
    sha256(first.as_bytes())
}

/// Public key type for HorizCoin
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct PublicKey(VerifyingKey);

impl PublicKey {
    /// Create from verifying key
    pub fn from_verifying_key(key: VerifyingKey) -> Self {
        Self(key)
    }

    /// Get the inner verifying key
    pub fn verifying_key(&self) -> &VerifyingKey {
        &self.0
    }

    /// Serialize to compressed SEC1 format (33 bytes)
    pub fn to_bytes(&self) -> [u8; 33] {
        let point = self.0.to_encoded_point(true);
        let mut bytes = [0u8; 33];
        bytes.copy_from_slice(point.as_bytes());
        bytes
    }

    /// Deserialize from compressed SEC1 format
    pub fn from_bytes(bytes: &[u8; 33]) -> Result<Self, HorizError> {
        let key = VerifyingKey::from_sec1_bytes(bytes)
            .map_err(|e| HorizError::Crypto(format!("Invalid public key: {}", e)))?;
        Ok(Self(key))
    }

    /// Convert to HorizCoin address using bech32m
    pub fn to_address(&self) -> String {
        let pubkey_hash = sha256(&self.to_bytes());
        let hash160 = &pubkey_hash.as_bytes()[..20]; // Take first 20 bytes
        
        // Use bech32m encoding with "hz" prefix
        let hrp = bech32::Hrp::parse("hz").expect("valid hrp");
        bech32::encode::<bech32::Bech32m>(hrp, hash160)
            .unwrap_or_else(|_| "invalid_address".to_string())
    }

    /// Verify a signature for given message
    pub fn verify(&self, message: &[u8], signature: &[u8; 64]) -> bool {
        let sig = match Signature::from_slice(signature) {
            Ok(s) => s,
            Err(_) => return false,
        };
        
        let msg_hash = sha256(message);
        self.0.verify(msg_hash.as_bytes(), &sig).is_ok()
    }
}

impl Serialize for PublicKey {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::Serializer,
    {
        serializer.serialize_bytes(&self.to_bytes())
    }
}

impl<'de> Deserialize<'de> for PublicKey {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        let bytes: Vec<u8> = Vec::deserialize(deserializer)?;
        if bytes.len() != 33 {
            return Err(serde::de::Error::custom("Invalid public key length"));
        }
        let mut array = [0u8; 33];
        array.copy_from_slice(&bytes);
        PublicKey::from_bytes(&array).map_err(serde::de::Error::custom)
    }
}

/// Private key type for HorizCoin
#[derive(Clone)]
pub struct PrivateKey(SigningKey);

impl PrivateKey {
    /// Generate a new random private key
    pub fn generate() -> Self {
        let key = SigningKey::random(&mut rand::thread_rng());
        Self(key)
    }

    /// Create from raw bytes
    pub fn from_bytes(bytes: &[u8; 32]) -> Result<Self, HorizError> {
        let key = SigningKey::from_slice(bytes)
            .map_err(|e| HorizError::Crypto(format!("Invalid private key: {}", e)))?;
        Ok(Self(key))
    }

    /// Get the corresponding public key
    pub fn public_key(&self) -> PublicKey {
        PublicKey(*self.0.verifying_key())
    }

    /// Sign a message
    pub fn sign(&self, message: &[u8]) -> [u8; 64] {
        let msg_hash = sha256(message);
        let signature: Signature = self.0.sign(msg_hash.as_bytes());
        signature.to_bytes().into()
    }

    /// Get raw bytes (BE CAREFUL - this exposes the private key!)
    pub fn to_bytes(&self) -> [u8; 32] {
        self.0.to_bytes().into()
    }
}

impl std::fmt::Debug for PrivateKey {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "PrivateKey([REDACTED])")
    }
}

/// Address utilities
pub mod address {
    use super::*;
    
    /// Parse a HorizCoin address
    pub fn parse_address(addr: &str) -> Result<[u8; 20], HorizError> {
        let (hrp, data) = bech32::decode(addr)
            .map_err(|e| HorizError::Crypto(format!("Invalid address format: {}", e)))?;
        
        if hrp.as_str() != "hz" {
            return Err(HorizError::Crypto("Invalid address prefix".to_string()));
        }
        
        if data.len() != 20 {
            return Err(HorizError::Crypto("Invalid address length".to_string()));
        }
        
        let mut hash160 = [0u8; 20];
        hash160.copy_from_slice(&data);
        Ok(hash160)
    }
    
    /// Validate a HorizCoin address
    pub fn is_valid_address(addr: &str) -> bool {
        parse_address(addr).is_ok()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sha256() {
        let data = b"hello world";
        let hash = sha256(data);
        // SHA-256 of "hello world"
        let expected = "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9";
        assert_eq!(hash.to_hex(), expected);
    }

    #[test]
    fn test_double_sha256() {
        let data = b"hello";
        let hash = double_sha256(data);
        // Should be SHA-256(SHA-256("hello"))
        assert_eq!(hash.as_bytes().len(), 32);
    }

    #[test]
    fn test_key_generation() {
        let private_key = PrivateKey::generate();
        let public_key = private_key.public_key();
        
        // Test that we can serialize and deserialize
        let pub_bytes = public_key.to_bytes();
        let recovered_pub = PublicKey::from_bytes(&pub_bytes).unwrap();
        assert_eq!(public_key, recovered_pub);
    }

    #[test]
    fn test_signing_and_verification() {
        let private_key = PrivateKey::generate();
        let public_key = private_key.public_key();
        
        let message = b"test message";
        let signature = private_key.sign(message);
        
        assert!(public_key.verify(message, &signature));
        
        // Test with different message
        let wrong_message = b"wrong message";
        assert!(!public_key.verify(wrong_message, &signature));
    }

    #[test]
    fn test_address_generation() {
        let private_key = PrivateKey::generate();
        let public_key = private_key.public_key();
        let address = public_key.to_address();
        
        // Should start with "hz" prefix
        assert!(address.starts_with("hz"));
        
        // Should be valid bech32m
        assert!(address::is_valid_address(&address));
    }

    #[test]
    fn test_address_parsing() {
        let private_key = PrivateKey::generate();
        let public_key = private_key.public_key();
        let address = public_key.to_address();
        
        // Should be able to parse back
        let parsed = address::parse_address(&address);
        assert!(parsed.is_ok());
        
        // Invalid addresses should fail
        assert!(address::parse_address("invalid").is_err());
        assert!(address::parse_address("bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4").is_err()); // Bitcoin address
    }

    #[test]
    fn test_serde() {
        let private_key = PrivateKey::generate();
        let public_key = private_key.public_key();
        
        // Test serialization/deserialization
        let serialized = serde_json::to_string(&public_key).unwrap();
        let deserialized: PublicKey = serde_json::from_str(&serialized).unwrap();
        assert_eq!(public_key, deserialized);
    }
}
