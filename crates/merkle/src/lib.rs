//! Merkle tree implementation for HorizCoin.
//!
//! This crate provides Merkle tree functionality with SHA-256 hashing and proof generation
//! for efficient verification of data integrity in the HorizCoin blockchain.

use horizcoin_crypto::sha256;
use horizcoin_primitives::{Hash, HorizError};
use serde::{Deserialize, Serialize};

/// A Merkle tree for efficient hash verification
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct MerkleTree {
    /// The root hash of the tree
    pub root: Hash,
    /// All leaves in the tree (bottom level)
    pub leaves: Vec<Hash>,
    /// Internal tree structure (all levels)
    levels: Vec<Vec<Hash>>,
}

impl MerkleTree {
    /// Create a new Merkle tree from a list of data items
    pub fn new<T: AsRef<[u8]>>(data: Vec<T>) -> Result<Self, HorizError> {
        if data.is_empty() {
            return Err(HorizError::Generic("Cannot create Merkle tree from empty data".to_string()));
        }

        // Hash all the data to create leaves
        let leaves: Vec<Hash> = data.iter().map(|item| sha256(item.as_ref())).collect();
        
        Self::from_leaves(leaves)
    }

    /// Create a Merkle tree from pre-computed leaf hashes
    pub fn from_leaves(mut leaves: Vec<Hash>) -> Result<Self, HorizError> {
        if leaves.is_empty() {
            return Err(HorizError::Generic("Cannot create Merkle tree from empty leaves".to_string()));
        }

        let original_leaves = leaves.clone();
        let mut levels = vec![leaves.clone()];

        // Build the tree bottom-up
        while leaves.len() > 1 {
            // If odd number of nodes, duplicate the last one
            if leaves.len() % 2 == 1 {
                leaves.push(leaves[leaves.len() - 1]);
            }

            // Create the next level by pairing and hashing
            let mut next_level = Vec::new();
            for i in (0..leaves.len()).step_by(2) {
                let mut combined = Vec::new();
                combined.extend_from_slice(leaves[i].as_bytes());
                combined.extend_from_slice(leaves[i + 1].as_bytes());
                next_level.push(sha256(&combined));
            }

            levels.push(next_level.clone());
            leaves = next_level;
        }

        let root = leaves[0];

        Ok(MerkleTree {
            root,
            leaves: original_leaves,
            levels,
        })
    }

    /// Get the root hash of the tree
    pub fn root(&self) -> Hash {
        self.root
    }

    /// Get the number of leaves in the tree
    pub fn leaf_count(&self) -> usize {
        self.leaves.len()
    }

    /// Generate a Merkle proof for a specific leaf index
    pub fn proof(&self, leaf_index: usize) -> Result<MerkleProof, HorizError> {
        if leaf_index >= self.leaves.len() {
            return Err(HorizError::Generic("Leaf index out of bounds".to_string()));
        }

        let mut proof_hashes = Vec::new();
        let mut current_index = leaf_index;

        // Walk up the tree collecting sibling hashes
        for level in &self.levels[..self.levels.len() - 1] {
            let sibling_index = if current_index % 2 == 0 {
                current_index + 1
            } else {
                current_index - 1
            };

            // Get sibling hash (if it exists)
            if sibling_index < level.len() {
                proof_hashes.push(level[sibling_index]);
            } else {
                // No sibling (odd number of nodes), use the node itself
                proof_hashes.push(level[current_index]);
            }

            current_index /= 2;
        }

        Ok(MerkleProof {
            leaf_hash: self.leaves[leaf_index],
            leaf_index,
            proof_hashes,
            tree_size: self.leaves.len(),
        })
    }

    /// Verify that a hash is included in the tree at a specific position
    pub fn verify(&self, leaf_hash: Hash, leaf_index: usize) -> bool {
        if leaf_index >= self.leaves.len() {
            return false;
        }

        self.leaves[leaf_index] == leaf_hash
    }

    /// Get all leaf hashes
    pub fn leaves(&self) -> &[Hash] {
        &self.leaves
    }
}

/// A Merkle proof that can verify a leaf's inclusion in a tree
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct MerkleProof {
    /// The hash of the leaf being proven
    pub leaf_hash: Hash,
    /// The index of the leaf in the original tree
    pub leaf_index: usize,
    /// The hashes needed to reconstruct the path to the root
    pub proof_hashes: Vec<Hash>,
    /// The total number of leaves in the original tree
    pub tree_size: usize,
}

impl MerkleProof {
    /// Verify this proof against a known root hash
    pub fn verify(&self, root_hash: Hash) -> bool {
        let computed_root = self.compute_root();
        computed_root == root_hash
    }

    /// Compute the root hash from this proof
    pub fn compute_root(&self) -> Hash {
        let mut current_hash = self.leaf_hash;
        let mut current_index = self.leaf_index;

        for &sibling_hash in &self.proof_hashes {
            if current_index % 2 == 0 {
                // Current node is left child
                let mut combined = Vec::new();
                combined.extend_from_slice(current_hash.as_bytes());
                combined.extend_from_slice(sibling_hash.as_bytes());
                current_hash = sha256(&combined);
            } else {
                // Current node is right child
                let mut combined = Vec::new();
                combined.extend_from_slice(sibling_hash.as_bytes());
                combined.extend_from_slice(current_hash.as_bytes());
                current_hash = sha256(&combined);
            }
            current_index /= 2;
        }

        current_hash
    }

    /// Get the leaf hash being proven
    pub fn leaf_hash(&self) -> Hash {
        self.leaf_hash
    }

    /// Get the leaf index
    pub fn leaf_index(&self) -> usize {
        self.leaf_index
    }

    /// Get the tree size
    pub fn tree_size(&self) -> usize {
        self.tree_size
    }
}

/// Utility functions for Merkle trees
pub mod utils {
    use super::*;

    /// Compute Merkle root from a list of transaction hashes
    pub fn compute_merkle_root(hashes: &[Hash]) -> Result<Hash, HorizError> {
        if hashes.is_empty() {
            return Err(HorizError::Generic("Cannot compute root of empty hash list".to_string()));
        }

        let tree = MerkleTree::from_leaves(hashes.to_vec())?;
        Ok(tree.root())
    }

    /// Verify multiple proofs against the same root
    pub fn verify_proofs(proofs: &[MerkleProof], root_hash: Hash) -> bool {
        proofs.iter().all(|proof| proof.verify(root_hash))
    }

    /// Create a Merkle tree from transaction IDs
    pub fn tree_from_transaction_ids(tx_ids: &[horizcoin_primitives::TxId]) -> Result<MerkleTree, HorizError> {
        let hashes: Vec<Hash> = tx_ids
            .iter()
            .map(|tx_id| Hash::new(*tx_id.as_bytes()))
            .collect();
        
        MerkleTree::from_leaves(hashes)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_single_leaf_tree() {
        let data = vec!["single leaf"];
        let tree = MerkleTree::new(data).unwrap();
        
        assert_eq!(tree.leaf_count(), 1);
        assert_eq!(tree.root(), tree.leaves[0]);
    }

    #[test]
    fn test_two_leaf_tree() {
        let data = vec!["leaf1", "leaf2"];
        let tree = MerkleTree::new(data).unwrap();
        
        assert_eq!(tree.leaf_count(), 2);
        
        // Root should be hash of the two leaves combined
        let leaf1 = sha256(b"leaf1");
        let leaf2 = sha256(b"leaf2");
        let mut combined = Vec::new();
        combined.extend_from_slice(leaf1.as_bytes());
        combined.extend_from_slice(leaf2.as_bytes());
        let expected_root = sha256(&combined);
        
        assert_eq!(tree.root(), expected_root);
    }

    #[test]
    fn test_odd_number_leaves() {
        let data = vec!["leaf1", "leaf2", "leaf3"];
        let tree = MerkleTree::new(data).unwrap();
        
        assert_eq!(tree.leaf_count(), 3);
        // Should handle odd number by duplicating last leaf
        assert!(tree.root() != Hash::zero());
    }

    #[test]
    fn test_merkle_proof_generation() {
        let data = vec!["tx1", "tx2", "tx3", "tx4"];
        let tree = MerkleTree::new(data).unwrap();
        
        // Generate proof for first leaf
        let proof = tree.proof(0).unwrap();
        assert_eq!(proof.leaf_index, 0);
        assert_eq!(proof.leaf_hash, sha256(b"tx1"));
        assert_eq!(proof.tree_size, 4);
        
        // Verify the proof
        assert!(proof.verify(tree.root()));
    }

    #[test]
    fn test_merkle_proof_verification() {
        let data = vec!["data1", "data2", "data3", "data4", "data5"];
        let tree = MerkleTree::new(data).unwrap();
        
        // Test proofs for all leaves
        for i in 0..tree.leaf_count() {
            let proof = tree.proof(i).unwrap();
            assert!(proof.verify(tree.root()));
            assert_eq!(proof.leaf_index, i);
        }
    }

    #[test]
    fn test_invalid_proof() {
        let data1 = vec!["data1", "data2"];
        let data2 = vec!["different1", "different2"];
        
        let tree1 = MerkleTree::new(data1).unwrap();
        let tree2 = MerkleTree::new(data2).unwrap();
        
        let proof = tree1.proof(0).unwrap();
        
        // Proof from tree1 should not verify against tree2's root
        assert!(!proof.verify(tree2.root()));
    }

    #[test]
    fn test_empty_data() {
        let data: Vec<&str> = vec![];
        let result = MerkleTree::new(data);
        assert!(result.is_err());
    }

    #[test]
    fn test_large_tree() {
        // Test with a larger number of leaves
        let data: Vec<String> = (0..100).map(|i| format!("item{}", i)).collect();
        let tree = MerkleTree::new(data).unwrap();
        
        assert_eq!(tree.leaf_count(), 100);
        
        // Test random proofs
        for &index in &[0, 25, 50, 75, 99] {
            let proof = tree.proof(index).unwrap();
            assert!(proof.verify(tree.root()));
        }
    }

    #[test]
    fn test_merkle_root_computation() {
        let hashes = vec![
            sha256(b"hash1"),
            sha256(b"hash2"),
            sha256(b"hash3"),
        ];
        
        let root = utils::compute_merkle_root(&hashes).unwrap();
        let tree = MerkleTree::from_leaves(hashes).unwrap();
        
        assert_eq!(root, tree.root());
    }

    #[test]
    fn test_proof_serialization() {
        let data = vec!["test1", "test2", "test3"];
        let tree = MerkleTree::new(data).unwrap();
        let proof = tree.proof(1).unwrap();
        
        // Test JSON serialization
        let json = serde_json::to_string(&proof).unwrap();
        let deserialized: MerkleProof = serde_json::from_str(&json).unwrap();
        
        assert_eq!(proof, deserialized);
        assert!(deserialized.verify(tree.root()));
    }

    #[test]
    fn test_tree_serialization() {
        let data = vec!["item1", "item2", "item3", "item4"];
        let tree = MerkleTree::new(data).unwrap();
        
        // Test JSON serialization
        let json = serde_json::to_string(&tree).unwrap();
        let deserialized: MerkleTree = serde_json::from_str(&json).unwrap();
        
        assert_eq!(tree, deserialized);
        assert_eq!(tree.root(), deserialized.root());
    }
}
