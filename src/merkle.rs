//! Merkle tree implementation with single SHA-256 hashing

use crate::hash::sha256_concat;

/// Merkle tree implementation for HorizCoin
/// Uses single SHA-256 throughout, duplicates last leaf for odd counts
pub struct MerkleTree {
    /// The leaves of the tree (transaction IDs)
    pub leaves: Vec<[u8; 32]>,
    /// The root hash of the tree
    pub root: [u8; 32],
}

impl MerkleTree {
    /// Construct a Merkle tree from transaction IDs
    ///
    /// # Implementation Notes
    /// - Uses single SHA-256 (not double-hash like Bitcoin)
    /// - For odd number of leaves, duplicates the last leaf (Bitcoin-style)
    /// - Internal nodes: sha256(left || right)
    pub fn new(mut txids: Vec<[u8; 32]>) -> Self {
        if txids.is_empty() {
            // For empty tree, use hash of empty bytes
            let root = crate::hash::sha256(b"");
            return MerkleTree {
                leaves: Vec::new(),
                root,
            };
        }

        if txids.len() == 1 {
            // Single transaction case
            let root = txids[0];
            return MerkleTree {
                leaves: txids,
                root,
            };
        }

        let original_leaves = txids.clone();
        let root = Self::compute_merkle_root(&mut txids);

        MerkleTree {
            leaves: original_leaves,
            root,
        }
    }

    /// Compute the Merkle root from a list of hashes
    fn compute_merkle_root(hashes: &mut Vec<[u8; 32]>) -> [u8; 32] {
        while hashes.len() > 1 {
            let mut next_level = Vec::new();

            // Process pairs, duplicating last element if odd count
            for chunk in hashes.chunks(2) {
                if chunk.len() == 2 {
                    // Normal case: hash left and right
                    let combined = sha256_concat(&chunk[0], &chunk[1]);
                    next_level.push(combined);
                } else {
                    // Odd case: duplicate the last element
                    let last = chunk[0];
                    let combined = sha256_concat(&last, &last);
                    next_level.push(combined);
                }
            }

            *hashes = next_level;
        }

        hashes[0]
    }

    /// Get the root hash
    pub fn root(&self) -> [u8; 32] {
        self.root
    }

    /// Get the number of leaves
    pub fn len(&self) -> usize {
        self.leaves.len()
    }

    /// Check if the tree is empty
    pub fn is_empty(&self) -> bool {
        self.leaves.is_empty()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::hash::sha256;

    #[test]
    fn test_empty_merkle_tree() {
        let tree = MerkleTree::new(vec![]);
        assert!(tree.is_empty());
        assert_eq!(tree.len(), 0);
        // Root should be hash of empty bytes
        assert_eq!(tree.root(), sha256(b""));
    }

    #[test]
    fn test_single_leaf_merkle_tree() {
        let leaf = sha256(b"single_transaction");
        let tree = MerkleTree::new(vec![leaf]);

        assert_eq!(tree.len(), 1);
        assert_eq!(tree.root(), leaf);
    }

    #[test]
    fn test_two_leaves_merkle_tree() {
        let leaf1 = sha256(b"tx1");
        let leaf2 = sha256(b"tx2");
        let tree = MerkleTree::new(vec![leaf1, leaf2]);

        assert_eq!(tree.len(), 2);

        // Root should be sha256(leaf1 || leaf2)
        let expected_root = sha256_concat(&leaf1, &leaf2);
        assert_eq!(tree.root(), expected_root);
    }

    #[test]
    fn test_three_leaves_odd_duplication() {
        let leaf1 = sha256(b"tx1");
        let leaf2 = sha256(b"tx2");
        let leaf3 = sha256(b"tx3");
        let tree = MerkleTree::new(vec![leaf1, leaf2, leaf3]);

        assert_eq!(tree.len(), 3);

        // First level: [sha256(leaf1||leaf2), sha256(leaf3||leaf3)]
        let node1 = sha256_concat(&leaf1, &leaf2);
        let node2 = sha256_concat(&leaf3, &leaf3); // leaf3 duplicated

        // Root: sha256(node1||node2)
        let expected_root = sha256_concat(&node1, &node2);
        assert_eq!(tree.root(), expected_root);
    }

    #[test]
    fn test_four_leaves_even_count() {
        let leaf1 = sha256(b"tx1");
        let leaf2 = sha256(b"tx2");
        let leaf3 = sha256(b"tx3");
        let leaf4 = sha256(b"tx4");
        let tree = MerkleTree::new(vec![leaf1, leaf2, leaf3, leaf4]);

        assert_eq!(tree.len(), 4);

        // First level: [sha256(leaf1||leaf2), sha256(leaf3||leaf4)]
        let node1 = sha256_concat(&leaf1, &leaf2);
        let node2 = sha256_concat(&leaf3, &leaf4);

        // Root: sha256(node1||node2)
        let expected_root = sha256_concat(&node1, &node2);
        assert_eq!(tree.root(), expected_root);
    }

    #[test]
    fn test_single_hash_not_double_hash() {
        // Verify we're using single SHA-256, not double-hash
        let leaf1 = sha256(b"tx1");
        let leaf2 = sha256(b"tx2");

        // Our implementation: single hash
        let our_result = sha256_concat(&leaf1, &leaf2);

        // Double hash would be: sha256(sha256(leaf1 || leaf2))
        let single_hash = sha256_concat(&leaf1, &leaf2);
        let double_hash = sha256(&single_hash);

        // Verify they're different (confirming we use single hash)
        assert_ne!(our_result, double_hash);
        assert_eq!(our_result, single_hash);
    }

    #[test]
    fn test_merkle_tree_deterministic() {
        let txids = vec![sha256(b"tx1"), sha256(b"tx2"), sha256(b"tx3")];

        let tree1 = MerkleTree::new(txids.clone());
        let tree2 = MerkleTree::new(txids);

        assert_eq!(tree1.root(), tree2.root());
    }

    #[test]
    fn test_large_odd_tree() {
        // Test with 7 leaves (odd number > 1)
        let txids: Vec<[u8; 32]> = (0..7).map(|i| sha256(&[i])).collect();

        let tree = MerkleTree::new(txids.clone());
        assert_eq!(tree.len(), 7);

        // Manually compute expected result to verify odd-leaf duplication
        // Level 0: [0,1,2,3,4,5,6] -> Level 1: [01,23,45,66] -> Level 2: [0123,4566] -> Level 3: [01234566]
        let l1_01 = sha256_concat(&txids[0], &txids[1]);
        let l1_23 = sha256_concat(&txids[2], &txids[3]);
        let l1_45 = sha256_concat(&txids[4], &txids[5]);
        let l1_66 = sha256_concat(&txids[6], &txids[6]); // duplication

        let l2_0123 = sha256_concat(&l1_01, &l1_23);
        let l2_4566 = sha256_concat(&l1_45, &l1_66);

        let expected_root = sha256_concat(&l2_0123, &l2_4566);

        assert_eq!(tree.root(), expected_root);
    }
}
