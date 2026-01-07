// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./PQCWrapper.sol";

contract SigChainVerifier is PQCWrapper {
    struct SigChainElement {
        bytes node_id;
        bytes next_node_id;
        bytes signature;
        uint64 timestamp;
    }

    struct SigChain {
        bytes src_id;
        bytes dest_id;
        bytes payload_hash;
        SigChainElement[] elements;
    }

    function verifySigChain(SigChain calldata chain) external view returns (bool) {
        bytes memory last_sig = chain.payload_hash;

        for (uint i = 0; i < chain.elements.length; i++) {
            SigChainElement memory elem = chain.elements[i];
            
            bytes32 message = keccak256(abi.encode(last_sig, elem.node_id, elem.next_node_id));
            
            if (!pqcVerify(address(uint160(uint256(bytes20(elem.node_id)))), message, elem.signature)) {
                return false;
            }
            
            last_sig = elem.signature;
        }
        
        return true;
    }
}
