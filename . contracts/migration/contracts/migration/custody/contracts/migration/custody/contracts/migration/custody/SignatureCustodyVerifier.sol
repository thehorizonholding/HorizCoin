// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ICustodyVerifier.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SignatureCustodyVerifier is ICustodyVerifier {
    using ECDSA for bytes32;

    address public immutable signer;
    mapping(bytes32 => bool) public usedProofs;

    constructor(address _signer) {
        signer = _signer;
    }

    function verify(
        address user,
        uint256 amount,
        bytes calldata proof
    ) external override returns (bool) {
        bytes32 hash = keccak256(abi.encode(user, amount)).toEthSignedMessageHash();

        require(!usedProofs[hash], "Proof replayed");
        address recovered = hash.recover(proof);
        require(recovered == signer, "Bad signature");

        usedProofs[hash] = true;
        return true;
    }
}
