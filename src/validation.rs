//! Validation logic for blocks and transactions

use crate::block::Block;
use crate::constants::{TIMESTAMP_FUTURE_SKEW_SECS, TIMESTAMP_PAST_SKEW_SECS};
use crate::transaction::{Transaction, TransactionError};
use std::time::{SystemTime, UNIX_EPOCH};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ValidationError {
    #[error("Transaction validation failed: {0}")]
    Transaction(#[from] TransactionError),
    #[error("Block timestamp too far in future: {block_time} > {max_time}")]
    TimestampTooFarInFuture { block_time: u64, max_time: u64 },
    #[error("Block timestamp too far in past: {block_time} < {min_time}")]
    TimestampTooFarInPast { block_time: u64, min_time: u64 },
    #[error("Invalid Merkle root")]
    InvalidMerkleRoot,
    #[error("Block contains no transactions")]
    EmptyBlock,
    #[error("Duplicate transaction found")]
    DuplicateTransaction,
}

/// Get current Unix timestamp
pub fn current_timestamp() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .expect("Time went backwards")
        .as_secs()
}

/// Validate basic block properties
pub fn validate_block_basic(block: &Block) -> Result<(), ValidationError> {
    validate_block_basic_with_time(block, current_timestamp())
}

/// Validate basic block properties with a specific current time (for testing)
pub fn validate_block_basic_with_time(
    block: &Block,
    current_time: u64,
) -> Result<(), ValidationError> {
    // Check timestamp skew
    let max_future_time = current_time + TIMESTAMP_FUTURE_SKEW_SECS;
    let min_past_time = current_time.saturating_sub(TIMESTAMP_PAST_SKEW_SECS);

    if block.header.timestamp > max_future_time {
        return Err(ValidationError::TimestampTooFarInFuture {
            block_time: block.header.timestamp,
            max_time: max_future_time,
        });
    }

    if block.header.timestamp < min_past_time {
        return Err(ValidationError::TimestampTooFarInPast {
            block_time: block.header.timestamp,
            min_time: min_past_time,
        });
    }

    // Verify Merkle root
    if !block.verify_merkle_root() {
        return Err(ValidationError::InvalidMerkleRoot);
    }

    // Validate all transactions
    for transaction in &block.transactions {
        transaction.validate_basic()?;
    }

    // Check for duplicate transactions
    let mut seen_txids = std::collections::HashSet::new();
    for transaction in &block.transactions {
        let txid = transaction.txid();
        if !seen_txids.insert(txid) {
            return Err(ValidationError::DuplicateTransaction);
        }
    }

    Ok(())
}

/// Validate a single transaction
pub fn validate_transaction_basic(transaction: &Transaction) -> Result<(), ValidationError> {
    transaction.validate_basic().map_err(ValidationError::from)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::block::Block;
    use crate::transaction::Transaction;

    fn create_test_transaction(nonce: u64) -> Transaction {
        Transaction::new(
            format!("sender{}", nonce),
            format!("recipient{}", nonce),
            100 + nonce,
            1,
            Some(format!("memo{}", nonce)),
            nonce,
            1234567890 + nonce,
        )
        .unwrap()
    }

    #[test]
    fn test_validate_block_basic_valid() {
        let prev_hash = [1u8; 32];
        let transactions = vec![create_test_transaction(1), create_test_transaction(2)];
        let current_time = 1234567890;
        let block = Block::new(prev_hash, transactions, current_time, 100);

        let result = validate_block_basic_with_time(&block, current_time);
        assert!(result.is_ok());
    }

    #[test]
    fn test_validate_block_timestamp_future_skew_allowed() {
        let prev_hash = [1u8; 32];
        let transactions = vec![create_test_transaction(1)];
        let current_time = 1234567890;
        let block_time = current_time + TIMESTAMP_FUTURE_SKEW_SECS; // Exactly at limit
        let block = Block::new(prev_hash, transactions, block_time, 100);

        let result = validate_block_basic_with_time(&block, current_time);
        assert!(result.is_ok());
    }

    #[test]
    fn test_validate_block_timestamp_too_far_future() {
        let prev_hash = [1u8; 32];
        let transactions = vec![create_test_transaction(1)];
        let current_time = 1234567890;
        let block_time = current_time + TIMESTAMP_FUTURE_SKEW_SECS + 1; // One second over limit
        let block = Block::new(prev_hash, transactions, block_time, 100);

        let result = validate_block_basic_with_time(&block, current_time);
        assert!(matches!(
            result,
            Err(ValidationError::TimestampTooFarInFuture { .. })
        ));
    }

    #[test]
    fn test_validate_block_timestamp_past_skew_allowed() {
        let prev_hash = [1u8; 32];
        let transactions = vec![create_test_transaction(1)];
        let current_time = 1234567890;
        let block_time = current_time - TIMESTAMP_PAST_SKEW_SECS; // Exactly at limit
        let block = Block::new(prev_hash, transactions, block_time, 100);

        let result = validate_block_basic_with_time(&block, current_time);
        assert!(result.is_ok());
    }

    #[test]
    fn test_validate_block_timestamp_too_far_past() {
        let prev_hash = [1u8; 32];
        let transactions = vec![create_test_transaction(1)];
        let current_time = 1234567890;
        let block_time = current_time - TIMESTAMP_PAST_SKEW_SECS - 1; // One second over limit
        let block = Block::new(prev_hash, transactions, block_time, 100);

        let result = validate_block_basic_with_time(&block, current_time);
        assert!(matches!(
            result,
            Err(ValidationError::TimestampTooFarInPast { .. })
        ));
    }

    #[test]
    fn test_validate_block_invalid_transaction() {
        let prev_hash = [1u8; 32];
        let mut tx = create_test_transaction(1);
        tx.memo = Some("a".repeat(129)); // Too long memo
        let transactions = vec![tx];
        let current_time = 1234567890;
        let block = Block::new(prev_hash, transactions, current_time, 100);

        let result = validate_block_basic_with_time(&block, current_time);
        assert!(matches!(result, Err(ValidationError::Transaction(_))));
    }

    #[test]
    fn test_validate_block_duplicate_transactions() {
        let prev_hash = [1u8; 32];
        let tx = create_test_transaction(1);
        let transactions = vec![tx.clone(), tx]; // Duplicate transaction
        let current_time = 1234567890;
        let block = Block::new(prev_hash, transactions, current_time, 100);

        let result = validate_block_basic_with_time(&block, current_time);
        assert!(matches!(result, Err(ValidationError::DuplicateTransaction)));
    }

    #[test]
    fn test_validate_transaction_basic_valid() {
        let tx = create_test_transaction(1);
        let result = validate_transaction_basic(&tx);
        assert!(result.is_ok());
    }

    #[test]
    fn test_validate_transaction_basic_invalid_memo() {
        let tx = Transaction::new(
            "sender".to_string(),
            "recipient".to_string(),
            100,
            1,
            Some("a".repeat(129)), // Too long memo
            1,
            1234567890,
        );

        assert!(tx.is_err());
    }

    #[test]
    fn test_timestamp_constants_values() {
        // Verify the constants are set to expected values
        assert_eq!(TIMESTAMP_FUTURE_SKEW_SECS, 120);
        assert_eq!(TIMESTAMP_PAST_SKEW_SECS, 24 * 60 * 60);
    }

    #[test]
    fn test_current_timestamp_reasonable() {
        let timestamp = current_timestamp();
        // Should be a reasonable Unix timestamp (after 2020)
        assert!(timestamp > 1577836800); // 2020-01-01
                                         // Should be before year 2100
        assert!(timestamp < 4102444800); // 2100-01-01
    }

    #[test]
    fn test_empty_block_validation() {
        let prev_hash = [1u8; 32];
        let transactions = vec![];
        let current_time = 1234567890;
        let block = Block::new(prev_hash, transactions, current_time, 100);

        // Empty blocks should be valid (this is different from Bitcoin)
        let result = validate_block_basic_with_time(&block, current_time);
        assert!(result.is_ok());
    }
}
