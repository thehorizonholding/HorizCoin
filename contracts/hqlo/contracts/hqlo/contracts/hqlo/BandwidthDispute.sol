// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./SigChainVerifier.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract BandwidthDispute is SigChainVerifier {
    struct Commitment {
        bytes32 merkleRoot;
        address solver;
        uint256 stake;
        uint256 timestamp;
        bool finalized;
    }

    mapping(bytes32 => Commitment) public commitments;

    event WorkSubmitted(bytes32 root, address solver);
    event WorkChallenged(bytes32 root, bool invalid);

    function submitWork(bytes32 _merkleRoot) external payable {
        require(msg.value >= 10 ether, "Stake required");
        commitments[_merkleRoot] = Commitment({
            merkleRoot: _merkleRoot,
            solver: msg.sender,
            stake: msg.value,
            timestamp: block.timestamp,
            finalized: false
        });
        emit WorkSubmitted(_merkleRoot, msg.sender);
    }

    function challengeWork(
        bytes32 _root,
        bytes32[] calldata proof,
        SigChain calldata chain
    ) external {
        Commitment storage c = commitments[_root];
        require(!c.finalized, "Already finalized");

        bytes32 leaf = keccak256(abi.encode(chain));
        require(MerkleProof.verify(proof, _root, leaf), "Invalid proof");

        bool valid = verifySigChain(chain);
        emit WorkChallenged(_root, !valid);

        if (!valid) {
            payable(msg.sender).transfer(c.stake);
            c.finalized = true;
        }
    }
}
