// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ICustodyVerifier.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract CrossChainCustodyVerifier is ICustodyVerifier {
    bytes32 public custodyRoot;

    function updateRoot(bytes32 newRoot) external {
        // DAO-gated in production
        custodyRoot = newRoot;
    }

    function verify(
        address user,
        uint256 amount,
        bytes calldata proof
    ) external view override returns (bool) {
        bytes32 leaf = keccak256(abi.encode(user, amount));
        return MerkleProof.verify(abi.decode(proof, (bytes32[])), custodyRoot, leaf);
    }
}
