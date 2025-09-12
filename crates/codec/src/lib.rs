//! Canonical serialization and encoding for HorizCoin.
//!
//! This crate provides consistent encoding/decoding functionality with length-prefixing
//! and canonical serialization for the HorizCoin blockchain.

use horizcoin_primitives::HorizError;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

/// Encode a serializable value to bytes using canonical encoding
pub fn encode<T: Serialize>(value: &T) -> Result<Vec<u8>, HorizError> {
    bincode::serialize(value)
        .map_err(|e| HorizError::Serialization(format!("Encoding error: {}", e)))
}

/// Decode bytes to a deserializable value using canonical encoding
pub fn decode<T: for<'de> Deserialize<'de>>(bytes: &[u8]) -> Result<T, HorizError> {
    bincode::deserialize(bytes)
        .map_err(|e| HorizError::Serialization(format!("Decoding error: {}", e)))
}

/// Encode with length prefix (4-byte little-endian length + data)
pub fn encode_with_length<T: Serialize>(value: &T) -> Result<Vec<u8>, HorizError> {
    let data = encode(value)?;
    let len = data.len() as u32;
    let mut result = Vec::with_capacity(4 + data.len());
    result.extend_from_slice(&len.to_le_bytes());
    result.extend_from_slice(&data);
    Ok(result)
}

/// Decode from length-prefixed data
pub fn decode_with_length<T: for<'de> Deserialize<'de>>(bytes: &[u8]) -> Result<(T, usize), HorizError> {
    if bytes.len() < 4 {
        return Err(HorizError::Serialization("Insufficient data for length prefix".to_string()));
    }
    
    let len_bytes: [u8; 4] = bytes[0..4].try_into()
        .map_err(|_| HorizError::Serialization("Invalid length prefix".to_string()))?;
    let len = u32::from_le_bytes(len_bytes) as usize;
    
    if bytes.len() < 4 + len {
        return Err(HorizError::Serialization("Insufficient data for declared length".to_string()));
    }
    
    let data = &bytes[4..4 + len];
    let value = decode(data)?;
    Ok((value, 4 + len))
}

/// Compute canonical hash of a serializable value
pub fn canonical_hash<T: Serialize>(value: &T) -> Result<horizcoin_primitives::Hash, HorizError> {
    let encoded = encode(value)?;
    let digest = Sha256::digest(&encoded);
    Ok(horizcoin_primitives::Hash::new(digest.into()))
}

/// Trait for types that can be canonically encoded
pub trait Encodable: Serialize + for<'de> Deserialize<'de> {
    /// Encode to bytes
    fn encode(&self) -> Result<Vec<u8>, HorizError> {
        encode(self)
    }
    
    /// Decode from bytes
    fn decode(bytes: &[u8]) -> Result<Self, HorizError> {
        decode(bytes)
    }
    
    /// Compute canonical hash
    fn hash(&self) -> Result<horizcoin_primitives::Hash, HorizError> {
        canonical_hash(self)
    }
}

/// Implement Encodable for all types that are Serialize + Deserialize
impl<T> Encodable for T where T: Serialize + for<'de> Deserialize<'de> {}

/// Utilities for working with variable-length integers (varint)
pub mod varint {
    use super::*;
    
    /// Encode a u64 as a variable-length integer
    pub fn encode_u64(mut value: u64) -> Vec<u8> {
        let mut result = Vec::new();
        
        while value >= 0x80 {
            result.push((value & 0x7F) as u8 | 0x80);
            value >>= 7;
        }
        result.push(value as u8);
        
        result
    }
    
    /// Decode a variable-length integer to u64
    pub fn decode_u64(bytes: &[u8]) -> Result<(u64, usize), HorizError> {
        let mut value = 0u64;
        let mut shift = 0;
        let mut consumed = 0;
        
        for &byte in bytes {
            consumed += 1;
            
            if shift >= 64 {
                return Err(HorizError::Serialization("Varint overflow".to_string()));
            }
            
            value |= ((byte & 0x7F) as u64) << shift;
            
            if byte & 0x80 == 0 {
                return Ok((value, consumed));
            }
            
            shift += 7;
            
            if consumed > 10 {
                return Err(HorizError::Serialization("Varint too long".to_string()));
            }
        }
        
        Err(HorizError::Serialization("Incomplete varint".to_string()))
    }
}

/// Utilities for working with compact encodings
pub mod compact {
    use super::*;
    
    /// Compact encoding for amounts (similar to Bitcoin's compact size)
    pub fn encode_amount(amount: u64) -> Vec<u8> {
        if amount < 0xfd {
            vec![amount as u8]
        } else if amount <= 0xffff {
            let mut result = vec![0xfd];
            result.extend_from_slice(&(amount as u16).to_le_bytes());
            result
        } else if amount <= 0xffffffff {
            let mut result = vec![0xfe];
            result.extend_from_slice(&(amount as u32).to_le_bytes());
            result
        } else {
            let mut result = vec![0xff];
            result.extend_from_slice(&amount.to_le_bytes());
            result
        }
    }
    
    /// Decode compact amount
    pub fn decode_amount(bytes: &[u8]) -> Result<(u64, usize), HorizError> {
        if bytes.is_empty() {
            return Err(HorizError::Serialization("Empty compact amount".to_string()));
        }
        
        match bytes[0] {
            0xfd => {
                if bytes.len() < 3 {
                    return Err(HorizError::Serialization("Insufficient data for u16 amount".to_string()));
                }
                let amount = u16::from_le_bytes([bytes[1], bytes[2]]) as u64;
                Ok((amount, 3))
            }
            0xfe => {
                if bytes.len() < 5 {
                    return Err(HorizError::Serialization("Insufficient data for u32 amount".to_string()));
                }
                let amount = u32::from_le_bytes([bytes[1], bytes[2], bytes[3], bytes[4]]) as u64;
                Ok((amount, 5))
            }
            0xff => {
                if bytes.len() < 9 {
                    return Err(HorizError::Serialization("Insufficient data for u64 amount".to_string()));
                }
                let amount = u64::from_le_bytes([
                    bytes[1], bytes[2], bytes[3], bytes[4],
                    bytes[5], bytes[6], bytes[7], bytes[8],
                ]);
                Ok((amount, 9))
            }
            val => Ok((val as u64, 1)),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde::{Deserialize, Serialize};
    
    #[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
    struct TestStruct {
        value: u64,
        name: String,
    }

    #[test]
    fn test_basic_encoding() {
        let test = TestStruct {
            value: 12345,
            name: "test".to_string(),
        };
        
        let encoded = encode(&test).unwrap();
        let decoded: TestStruct = decode(&encoded).unwrap();
        
        assert_eq!(test, decoded);
    }

    #[test]
    fn test_length_prefixed_encoding() {
        let test = TestStruct {
            value: 67890,
            name: "length_test".to_string(),
        };
        
        let encoded = encode_with_length(&test).unwrap();
        let (decoded, consumed): (TestStruct, usize) = decode_with_length(&encoded).unwrap();
        
        assert_eq!(test, decoded);
        assert_eq!(consumed, encoded.len());
    }

    #[test]
    fn test_canonical_hash() {
        let test1 = TestStruct {
            value: 100,
            name: "hash_test".to_string(),
        };
        
        let test2 = TestStruct {
            value: 100,
            name: "hash_test".to_string(),
        };
        
        let hash1 = canonical_hash(&test1).unwrap();
        let hash2 = canonical_hash(&test2).unwrap();
        
        assert_eq!(hash1, hash2);
    }

    #[test]
    fn test_encodable_trait() {
        let test = TestStruct {
            value: 999,
            name: "trait_test".to_string(),
        };
        
        let encoded = test.encode().unwrap();
        let decoded = TestStruct::decode(&encoded).unwrap();
        let hash = test.hash().unwrap();
        
        assert_eq!(test, decoded);
        assert_eq!(hash.as_bytes().len(), 32);
    }

    #[test]
    fn test_varint_encoding() {
        let test_values = [0, 127, 128, 16383, 16384, u64::MAX];
        
        for &value in &test_values {
            let encoded = varint::encode_u64(value);
            let (decoded, consumed) = varint::decode_u64(&encoded).unwrap();
            
            assert_eq!(value, decoded);
            assert_eq!(consumed, encoded.len());
        }
    }

    #[test]
    fn test_compact_amount_encoding() {
        let test_values = [0, 252, 253, 65535, 65536, 4294967295, 4294967296, u64::MAX];
        
        for &amount in &test_values {
            let encoded = compact::encode_amount(amount);
            let (decoded, consumed) = compact::decode_amount(&encoded).unwrap();
            
            assert_eq!(amount, decoded);
            assert_eq!(consumed, encoded.len());
        }
    }

    #[test]
    fn test_insufficient_data_errors() {
        // Test length-prefixed decoding with insufficient data
        let short_data = vec![5, 0, 0, 0]; // Claims 5 bytes but provides none
        assert!(decode_with_length::<u32>(&short_data).is_err());
        
        // Test varint decoding with incomplete data
        let incomplete_varint = vec![0x80]; // Continuation bit set but no more data
        assert!(varint::decode_u64(&incomplete_varint).is_err());
        
        // Test compact amount with insufficient data
        let incomplete_compact = vec![0xfd]; // Claims u16 but no data
        assert!(compact::decode_amount(&incomplete_compact).is_err());
    }
}
