//! Transaction types and validation

use crate::constants::MEMO_MAX_LENGTH;
use crate::hash::sha256;
use serde::{Deserialize, Serialize};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum TransactionError {
    #[error("Memo too long: {0} bytes, maximum allowed: {}", MEMO_MAX_LENGTH)]
    MemoTooLong(usize),
    #[error("Invalid UTF-8 in memo")]
    InvalidUtf8,
    #[error("Invalid amount: {0}")]
    InvalidAmount(u64),
}

/// A transaction in the HorizCoin network
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Transaction {
    /// Transaction version
    pub version: u32,
    /// Sender address
    pub from: String,
    /// Recipient address  
    pub to: String,
    /// Amount to transfer
    pub amount: u64,
    /// Transaction fee
    pub fee: u64,
    /// Optional memo (max 128 bytes UTF-8)
    pub memo: Option<String>,
    /// Transaction nonce
    pub nonce: u64,
    /// Unix timestamp
    pub timestamp: u64,
}

impl Transaction {
    /// Create a new transaction
    pub fn new(
        from: String,
        to: String,
        amount: u64,
        fee: u64,
        memo: Option<String>,
        nonce: u64,
        timestamp: u64,
    ) -> Result<Self, TransactionError> {
        // Validate memo length if present
        if let Some(ref memo_str) = memo {
            if memo_str.len() > MEMO_MAX_LENGTH {
                return Err(TransactionError::MemoTooLong(memo_str.len()));
            }

            // Ensure it's valid UTF-8 (String already guarantees this, but explicit check)
            if !memo_str.is_ascii() && std::str::from_utf8(memo_str.as_bytes()).is_err() {
                return Err(TransactionError::InvalidUtf8);
            }
        }

        Ok(Transaction {
            version: 1,
            from,
            to,
            amount,
            fee,
            memo,
            nonce,
            timestamp,
        })
    }

    /// Get the canonical bytes representation for hashing
    pub fn canonical_bytes(&self) -> Vec<u8> {
        // Simple canonical representation - in practice this would be more sophisticated
        serde_json::to_vec(self).expect("Transaction serialization should not fail")
    }

    /// Compute the transaction ID (SHA-256 of canonical bytes)
    pub fn txid(&self) -> [u8; 32] {
        sha256(&self.canonical_bytes())
    }

    /// Validate transaction basic properties
    pub fn validate_basic(&self) -> Result<(), TransactionError> {
        // Validate memo length
        if let Some(ref memo_str) = self.memo {
            if memo_str.len() > MEMO_MAX_LENGTH {
                return Err(TransactionError::MemoTooLong(memo_str.len()));
            }
        }

        // Validate amounts are reasonable
        if self.amount == 0 && self.fee == 0 {
            return Err(TransactionError::InvalidAmount(0));
        }

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_transaction_creation_valid() {
        let tx = Transaction::new(
            "sender123".to_string(),
            "recipient456".to_string(),
            1000,
            10,
            Some("Hello world".to_string()),
            1,
            1234567890,
        )
        .unwrap();

        assert_eq!(tx.from, "sender123");
        assert_eq!(tx.to, "recipient456");
        assert_eq!(tx.amount, 1000);
        assert_eq!(tx.fee, 10);
        assert_eq!(tx.memo, Some("Hello world".to_string()));
    }

    #[test]
    fn test_memo_length_exactly_128_bytes() {
        let memo = "a".repeat(128);
        let tx = Transaction::new(
            "sender".to_string(),
            "recipient".to_string(),
            100,
            1,
            Some(memo.clone()),
            1,
            1234567890,
        )
        .unwrap();

        assert_eq!(tx.memo.unwrap().len(), 128);
    }

    #[test]
    fn test_memo_length_129_bytes_rejected() {
        let memo = "a".repeat(129);
        let result = Transaction::new(
            "sender".to_string(),
            "recipient".to_string(),
            100,
            1,
            Some(memo),
            1,
            1234567890,
        );

        assert!(matches!(result, Err(TransactionError::MemoTooLong(129))));
    }

    #[test]
    fn test_memo_multibyte_utf8() {
        // Use emoji which are 4 bytes each in UTF-8
        let memo = "🚀".repeat(32); // 32 * 4 = 128 bytes
        let tx = Transaction::new(
            "sender".to_string(),
            "recipient".to_string(),
            100,
            1,
            Some(memo.clone()),
            1,
            1234567890,
        )
        .unwrap();

        assert_eq!(tx.memo.unwrap().len(), 128);

        // 33 emoji would be 132 bytes, should be rejected
        let memo_too_long = "🚀".repeat(33);
        let result = Transaction::new(
            "sender".to_string(),
            "recipient".to_string(),
            100,
            1,
            Some(memo_too_long),
            1,
            1234567890,
        );

        assert!(matches!(result, Err(TransactionError::MemoTooLong(132))));
    }

    #[test]
    fn test_txid_computation() {
        let tx = Transaction::new(
            "sender".to_string(),
            "recipient".to_string(),
            100,
            1,
            None,
            1,
            1234567890,
        )
        .unwrap();

        let txid1 = tx.txid();
        let txid2 = tx.txid();

        // Should be deterministic
        assert_eq!(txid1, txid2);
        assert_eq!(txid1.len(), 32);
    }

    #[test]
    fn test_transaction_validation() {
        let tx = Transaction::new(
            "sender".to_string(),
            "recipient".to_string(),
            100,
            1,
            Some("valid memo".to_string()),
            1,
            1234567890,
        )
        .unwrap();

        assert!(tx.validate_basic().is_ok());
    }
}
