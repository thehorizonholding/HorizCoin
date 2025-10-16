# Quantum-Resistant Envelope Encryption (pq_envelope)

This folder contains a Rust implementation of a hybrid envelope encryption helper that combines:
- PQ KEM: CRYSTALS-Kyber (via pqcrypto-kyber)
- Symmetric AEAD: AES-256-GCM (aes-gcm)
- Key derivation: HKDF-SHA256 (hkdf + sha2)
- Secure zeroization: zeroize

Purpose
- Provide a straightforward, auditable, and testable envelope encryption primitive suitable for:
  - Wrapping per-record/per-file symmetric keys with Kyber (recipient public key).
  - Deriving AEAD keys using HKDF from Kyber shared secret.
  - Integration into your node or service to achieve quantum-aware confidentiality.

Usage
1. Add the dependencies shown in the Cargo.toml snippet below.
2. Call `hybrid_encrypt(&recipient_pk, plaintext)` to encrypt.
3. Call `hybrid_decrypt(&recipient_sk, &HybridCipher)` to decrypt.

Security notes
- In production, authenticate and protect public keys; store secret keys only in HSM/KMS.
- Rotate and re-wrap keys regularly (see project quantum guide).
- Use KATs and CI checks (include KATs in CI) to detect regressions.
- Consider using mTLS or short-lived tokens for service-to-service calls when transmitting ciphertexts/metadata.
