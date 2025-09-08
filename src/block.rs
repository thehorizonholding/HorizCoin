//! Block types and structures

use crate::hash::sha256;
use crate::merkle::MerkleTree;
use crate::transaction::Transaction;
use serde::{Deserialize, Serialize};

/// A block in the HorizCoin blockchain
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Block {
    /// Block header
    pub header: BlockHeader,
    /// Transactions in this block
    pub transactions: Vec<Transaction>,
}

/// Block header containing metadata
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BlockHeader {
    /// Block version
    pub version: u32,
    /// Hash of the previous block
    pub prev_block_hash: [u8; 32],
    /// Merkle root of transactions
    pub merkle_root: [u8; 32],
    /// Block timestamp (Unix timestamp)
    pub timestamp: u64,
    /// Block height
    pub height: u32,
    /// Block nonce for proof-of-work (placeholder)
    pub nonce: u64,
}

impl Block {
    /// Create a new block
    pub fn new(
        prev_block_hash: [u8; 32],
        transactions: Vec<Transaction>,
        timestamp: u64,
        height: u32,
    ) -> Self {
        // Compute Merkle root from transaction IDs
        let txids: Vec<[u8; 32]> = transactions.iter().map(|tx| tx.txid()).collect();

        let merkle_tree = MerkleTree::new(txids);
        let merkle_root = merkle_tree.root();

        let header = BlockHeader {
            version: 1,
            prev_block_hash,
            merkle_root,
            timestamp,
            height,
            nonce: 0,
        };

        Block {
            header,
            transactions,
        }
    }

    /// Get the block hash (hash of the header)
    pub fn hash(&self) -> [u8; 32] {
        let header_bytes =
            serde_json::to_vec(&self.header).expect("Block header serialization should not fail");
        sha256(&header_bytes)
    }

    /// Get the number of transactions in the block
    pub fn transaction_count(&self) -> usize {
        self.transactions.len()
    }

    /// Verify the Merkle root matches the transactions
    pub fn verify_merkle_root(&self) -> bool {
        let txids: Vec<[u8; 32]> = self.transactions.iter().map(|tx| tx.txid()).collect();

        let merkle_tree = MerkleTree::new(txids);
        merkle_tree.root() == self.header.merkle_root
    }
}

impl BlockHeader {
    /// Get the canonical bytes for hashing
    pub fn canonical_bytes(&self) -> Vec<u8> {
        serde_json::to_vec(self).expect("Block header serialization should not fail")
    }

    /// Get the header hash
    pub fn hash(&self) -> [u8; 32] {
        sha256(&self.canonical_bytes())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
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
    fn test_block_creation() {
        let prev_hash = [1u8; 32];
        let transactions = vec![create_test_transaction(1), create_test_transaction(2)];
        let timestamp = 1234567890;
        let height = 100;

        let block = Block::new(prev_hash, transactions.clone(), timestamp, height);

        assert_eq!(block.header.prev_block_hash, prev_hash);
        assert_eq!(block.header.timestamp, timestamp);
        assert_eq!(block.header.height, height);
        assert_eq!(block.transaction_count(), 2);
        assert_eq!(block.transactions, transactions);
    }

    #[test]
    fn test_block_merkle_root_verification() {
        let prev_hash = [1u8; 32];
        let transactions = vec![
            create_test_transaction(1),
            create_test_transaction(2),
            create_test_transaction(3),
        ];

        let block = Block::new(prev_hash, transactions, 1234567890, 100);

        // Merkle root should be correctly computed
        assert!(block.verify_merkle_root());
    }

    #[test]
    fn test_block_hash_deterministic() {
        let prev_hash = [1u8; 32];
        let transactions = vec![create_test_transaction(1)];

        let block1 = Block::new(prev_hash, transactions.clone(), 1234567890, 100);
        let block2 = Block::new(prev_hash, transactions, 1234567890, 100);

        assert_eq!(block1.hash(), block2.hash());
    }

    #[test]
    fn test_empty_block() {
        let prev_hash = [0u8; 32];
        let transactions = vec![];

        let block = Block::new(prev_hash, transactions, 1234567890, 1);

        assert_eq!(block.transaction_count(), 0);
        assert!(block.verify_merkle_root());

        // Empty block should have empty tree merkle root
        let empty_merkle = MerkleTree::new(vec![]);
        assert_eq!(block.header.merkle_root, empty_merkle.root());
    }

    #[test]
    fn test_single_transaction_block() {
        let prev_hash = [2u8; 32];
        let tx = create_test_transaction(42);
        let transactions = vec![tx.clone()];

        let block = Block::new(prev_hash, transactions, 1234567890, 5);

        assert_eq!(block.transaction_count(), 1);
        assert!(block.verify_merkle_root());

        // Single transaction block should have txid as merkle root
        assert_eq!(block.header.merkle_root, tx.txid());
    }

    #[test]
    fn test_block_header_hash() {
        let header = BlockHeader {
            version: 1,
            prev_block_hash: [3u8; 32],
            merkle_root: [4u8; 32],
            timestamp: 1234567890,
            height: 10,
            nonce: 42,
        };

        let hash1 = header.hash();
        let hash2 = header.hash();

        assert_eq!(hash1, hash2);
        assert_eq!(hash1.len(), 32);
    }
}
