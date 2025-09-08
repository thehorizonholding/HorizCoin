//! Transaction types and validation for HorizCoin
//!
//! This module defines the core transaction structure for simple transfers
//! and provides basic validation logic.

use crate::hash::{Hash, Hashable, hash_data};
use serde::{Deserialize, Serialize};
use thiserror::Error;

/// Errors that can occur during transaction operations
#[derive(Debug, Error)]
pub enum TransactionError {
    /// Generic transaction validation error
    #[error("Invalid transaction: {0}")]
    InvalidTransaction(String),
    /// Error during serialization/deserialization
    #[error("Serialization error: {0}")]
    SerializationError(#[from] anyhow::Error),
    /// Arithmetic overflow when calculating total value
    #[error("Amount overflow")]
    AmountOverflow,
    /// Transaction amount cannot be zero
    #[error("Zero amount not allowed")]
    ZeroAmount,
    /// Sender and recipient cannot be the same
    #[error("Self-transfer not allowed")]
    SelfTransfer,
}

/// A simple transfer transaction in HorizCoin
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Transaction {
    /// The sender's address (32-byte public key or address)
    pub from: [u8; 32],
    /// The recipient's address (32-byte public key or address)
    pub to: [u8; 32],
    /// The amount to transfer
    pub amount: u64,
    /// The transaction fee
    pub fee: u64,
    /// A nonce to prevent replay attacks
    pub nonce: u64,
    /// Digital signature of the transaction
    pub signature: Vec<u8>,
}

impl Transaction {
    /// Create a new transaction
    pub fn new(
        from: [u8; 32],
        to: [u8; 32],
        amount: u64,
        fee: u64,
        nonce: u64,
        signature: Vec<u8>,
    ) -> Self {
        Transaction {
            from,
            to,
            amount,
            fee,
            nonce,
            signature,
        }
    }

    /// Create an unsigned transaction (for signing purposes)
    pub fn new_unsigned(
        from: [u8; 32],
        to: [u8; 32],
        amount: u64,
        fee: u64,
        nonce: u64,
    ) -> Self {
        Transaction {
            from,
            to,
            amount,
            fee,
            nonce,
            signature: Vec::new(),
        }
    }

    /// Get the total value (amount + fee) being transferred
    pub fn total_value(&self) -> Result<u64, TransactionError> {
        self.amount.checked_add(self.fee)
            .ok_or(TransactionError::AmountOverflow)
    }

    /// Basic validation of the transaction
    pub fn validate(&self) -> Result<(), TransactionError> {
        // Check for zero amount
        if self.amount == 0 {
            return Err(TransactionError::ZeroAmount);
        }

        // Check for self-transfer
        if self.from == self.to {
            return Err(TransactionError::SelfTransfer);
        }

        // Check for overflow
        self.total_value()?;

        // Additional validations can be added here
        // For example: signature validation, balance checks, etc.

        Ok(())
    }

    /// Get the transaction without signature (for signing/verification)
    pub fn unsigned_data(&self) -> UnsignedTransaction {
        UnsignedTransaction {
            from: self.from,
            to: self.to,
            amount: self.amount,
            fee: self.fee,
            nonce: self.nonce,
        }
    }

    /// Sign the transaction with a signature
    pub fn with_signature(mut self, signature: Vec<u8>) -> Self {
        self.signature = signature;
        self
    }

    /// Check if the transaction is signed
    pub fn is_signed(&self) -> bool {
        !self.signature.is_empty()
    }
}

/// Unsigned transaction data (used for signing)
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct UnsignedTransaction {
    /// The sender's address
    pub from: [u8; 32],
    /// The recipient's address  
    pub to: [u8; 32],
    /// The amount to transfer
    pub amount: u64,
    /// The transaction fee
    pub fee: u64,
    /// A nonce to prevent replay attacks
    pub nonce: u64,
}

impl Hashable for Transaction {
    fn hash(&self) -> Hash {
        hash_data(self).expect("Transaction should always be serializable")
    }
}

impl Hashable for UnsignedTransaction {
    fn hash(&self) -> Hash {
        hash_data(self).expect("UnsignedTransaction should always be serializable")
    }
}

/// Transaction builder for easier construction
pub struct TransactionBuilder {
    from: Option<[u8; 32]>,
    to: Option<[u8; 32]>,
    amount: Option<u64>,
    fee: Option<u64>,
    nonce: Option<u64>,
}

impl TransactionBuilder {
    /// Create a new transaction builder
    pub fn new() -> Self {
        TransactionBuilder {
            from: None,
            to: None,
            amount: None,
            fee: None,
            nonce: None,
        }
    }

    /// Set the sender address
    pub fn from(mut self, from: [u8; 32]) -> Self {
        self.from = Some(from);
        self
    }

    /// Set the recipient address
    pub fn to(mut self, to: [u8; 32]) -> Self {
        self.to = Some(to);
        self
    }

    /// Set the amount
    pub fn amount(mut self, amount: u64) -> Self {
        self.amount = Some(amount);
        self
    }

    /// Set the fee
    pub fn fee(mut self, fee: u64) -> Self {
        self.fee = Some(fee);
        self
    }

    /// Set the nonce
    pub fn nonce(mut self, nonce: u64) -> Self {
        self.nonce = Some(nonce);
        self
    }

    /// Build the unsigned transaction
    pub fn build_unsigned(self) -> Result<Transaction, TransactionError> {
        let from = self.from.ok_or_else(|| TransactionError::InvalidTransaction("Missing from address".to_string()))?;
        let to = self.to.ok_or_else(|| TransactionError::InvalidTransaction("Missing to address".to_string()))?;
        let amount = self.amount.ok_or_else(|| TransactionError::InvalidTransaction("Missing amount".to_string()))?;
        let fee = self.fee.ok_or_else(|| TransactionError::InvalidTransaction("Missing fee".to_string()))?;
        let nonce = self.nonce.ok_or_else(|| TransactionError::InvalidTransaction("Missing nonce".to_string()))?;

        let tx = Transaction::new_unsigned(from, to, amount, fee, nonce);
        tx.validate()?;
        Ok(tx)
    }

    /// Build the signed transaction
    pub fn build_signed(self, signature: Vec<u8>) -> Result<Transaction, TransactionError> {
        let tx = self.build_unsigned()?;
        Ok(tx.with_signature(signature))
    }
}

impl Default for TransactionBuilder {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn create_test_addresses() -> ([u8; 32], [u8; 32]) {
        let from = [1u8; 32];
        let to = [2u8; 32];
        (from, to)
    }

    #[test]
    fn test_transaction_creation() {
        let (from, to) = create_test_addresses();
        let signature = vec![0x42u8; 64];
        
        let tx = Transaction::new(from, to, 100, 10, 1, signature.clone());
        
        assert_eq!(tx.from, from);
        assert_eq!(tx.to, to);
        assert_eq!(tx.amount, 100);
        assert_eq!(tx.fee, 10);
        assert_eq!(tx.nonce, 1);
        assert_eq!(tx.signature, signature);
    }

    #[test]
    fn test_total_value() {
        let (from, to) = create_test_addresses();
        let tx = Transaction::new_unsigned(from, to, 100, 10, 1);
        
        assert_eq!(tx.total_value().unwrap(), 110);
    }

    #[test]
    fn test_total_value_overflow() {
        let (from, to) = create_test_addresses();
        let tx = Transaction::new_unsigned(from, to, u64::MAX, 1, 1);
        
        assert!(tx.total_value().is_err());
    }

    #[test]
    fn test_transaction_validation() {
        let (from, to) = create_test_addresses();
        
        // Valid transaction
        let valid_tx = Transaction::new_unsigned(from, to, 100, 10, 1);
        assert!(valid_tx.validate().is_ok());
        
        // Zero amount
        let zero_amount_tx = Transaction::new_unsigned(from, to, 0, 10, 1);
        assert!(matches!(zero_amount_tx.validate(), Err(TransactionError::ZeroAmount)));
        
        // Self transfer
        let self_tx = Transaction::new_unsigned(from, from, 100, 10, 1);
        assert!(matches!(self_tx.validate(), Err(TransactionError::SelfTransfer)));
        
        // Overflow
        let overflow_tx = Transaction::new_unsigned(from, to, u64::MAX, 1, 1);
        assert!(matches!(overflow_tx.validate(), Err(TransactionError::AmountOverflow)));
    }

    #[test]
    fn test_unsigned_data() {
        let (from, to) = create_test_addresses();
        let signature = vec![0x42u8; 64];
        let tx = Transaction::new(from, to, 100, 10, 1, signature);
        
        let unsigned = tx.unsigned_data();
        assert_eq!(unsigned.from, from);
        assert_eq!(unsigned.to, to);
        assert_eq!(unsigned.amount, 100);
        assert_eq!(unsigned.fee, 10);
        assert_eq!(unsigned.nonce, 1);
    }

    #[test]
    fn test_transaction_hashing() {
        let (from, to) = create_test_addresses();
        let tx1 = Transaction::new_unsigned(from, to, 100, 10, 1);
        let tx2 = Transaction::new_unsigned(from, to, 100, 10, 1);
        let tx3 = Transaction::new_unsigned(from, to, 101, 10, 1);
        
        assert_eq!(tx1.hash(), tx2.hash()); // Same transaction should have same hash
        assert_ne!(tx1.hash(), tx3.hash()); // Different transaction should have different hash
    }

    #[test]
    fn test_transaction_builder() {
        let (from, to) = create_test_addresses();
        
        let tx = TransactionBuilder::new()
            .from(from)
            .to(to)
            .amount(100)
            .fee(10)
            .nonce(1)
            .build_unsigned()
            .unwrap();
        
        assert_eq!(tx.from, from);
        assert_eq!(tx.to, to);
        assert_eq!(tx.amount, 100);
        assert_eq!(tx.fee, 10);
        assert_eq!(tx.nonce, 1);
        assert!(!tx.is_signed());
    }

    #[test]
    fn test_transaction_builder_with_signature() {
        let (from, to) = create_test_addresses();
        let signature = vec![0x42u8; 64];
        
        let tx = TransactionBuilder::new()
            .from(from)
            .to(to)
            .amount(100)
            .fee(10)
            .nonce(1)
            .build_signed(signature.clone())
            .unwrap();
        
        assert_eq!(tx.signature, signature);
        assert!(tx.is_signed());
    }

    #[test]
    fn test_transaction_builder_incomplete() {
        // Missing required fields should fail
        let result = TransactionBuilder::new()
            .amount(100)
            .build_unsigned();
        
        assert!(result.is_err());
    }

    #[test]
    fn test_serialization() {
        let (from, to) = create_test_addresses();
        let tx = Transaction::new_unsigned(from, to, 100, 10, 1);
        
        // Test JSON serialization
        let json = serde_json::to_string(&tx).unwrap();
        let deserialized: Transaction = serde_json::from_str(&json).unwrap();
        assert_eq!(tx, deserialized);
        
        // Test binary serialization
        let binary = bincode::serialize(&tx).unwrap();
        let deserialized: Transaction = bincode::deserialize(&binary).unwrap();
        assert_eq!(tx, deserialized);
    }
}