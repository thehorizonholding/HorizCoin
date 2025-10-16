//! Hybrid envelope encryption helper using Kyber (KEM) + AES-256-GCM.
//!
//! High-level flow:
//! - Sender: encapsulate to recipient Kyber public key -> (kem_ciphertext, shared_secret)
//! - Derive an AEAD key via HKDF from the shared_secret (and optional salt/info)
//! - Encrypt payload with AES-256-GCM using derived key and a random nonce
//! - Store/send: kem_ciphertext || nonce || ciphertext
//!
//! - Recipient: decapsulate using Kyber secret key -> shared_secret
//! - Derive AEAD key via same HKDF parameters -> decrypt ciphertext
//!
//! Notes:
//! - This example uses the pqcrypto-kyber crate API. If your pqcrypto version has different
//!   names/representations for keys or secrets, adapt the conversions accordingly.
//! - In production: ensure recipient public keys are validated and authenticated, protect secret keys in an HSM,
//!   and store ciphertext metadata in your metadata store (encrypted_keys table).

use anyhow::Context;
use aes_gcm::{Aes256Gcm, Key, Nonce}; // 96-bit nonce (12 bytes)
use aes_gcm::aead::{Aead, NewAead};
use hkdf::Hkdf;
use sha2::Sha256;
use zeroize::Zeroize;

use pqcrypto_kyber::kyber512; // adjust to kyber level you choose (e.g., kyber768/kyber1024)
use pqcrypto_kyber::kyber512::{PublicKey, SecretKey};

use getrandom::getrandom;

/// Lengths
const AES_KEY_LEN: usize = 32; // AES-256
const AES_NONCE_LEN: usize = 12;

#[derive(Debug, Clone)]
pub struct HybridCipher {
    /// KEM encapsulated ciphertext (Kyber ciphertext)
    pub kem_ciphertext: Vec<u8>,
    /// AES-GCM nonce (12 bytes)
    pub nonce: [u8; AES_NONCE_LEN],
    /// Encrypted payload (ciphertext)
    pub ciphertext: Vec<u8>,
}

impl HybridCipher {
    pub fn to_bytes(&self) -> Vec<u8> {
        let mut out = Vec::new();
        // lengths are implicit here; for transport formats you may prefix lengths or use a structured format
        out.extend_from_slice(&self.kem_ciphertext);
        out.extend_from_slice(&self.nonce);
        out.extend_from_slice(&self.ciphertext);
        out
    }
}

/// Perform hybrid encryption to a recipient's Kyber public key.
/// Returns kem ciphertext + AES-GCM nonce + ciphertext.
pub fn hybrid_encrypt(recipient_pk: &PublicKey, plaintext: &[u8]) -> anyhow::Result<HybridCipher> {
    // 1) KEM encapsulate: produces ciphertext and shared secret
    // API: kyber512::encapsulate(&recipient_pk) -> (ciphertext, shared_secret)
    let (kem_ciphertext, shared_secret) = kyber512::encapsulate(recipient_pk);

    // shared_secret is a byte container — convert to slice
    let ss_bytes = shared_secret.as_bytes();

    // 2) Derive an AES-256 key via HKDF-SHA256 using the shared secret.
    let hk = Hkdf::<Sha256>::new(None, ss_bytes);
    let mut okm = [0u8; AES_KEY_LEN];
    hk.expand(b"pq-envelope-aes-key", &mut okm)
        .context("HKDF expand failure")?;

    // 3) Encrypt payload with AES-256-GCM
    // generate nonce
    let mut nonce = [0u8; AES_NONCE_LEN];
    getrandom(&mut nonce).context("getrandom nonce failed")?;
    let aead = Aes256Gcm::new(Key::from_slice(&okm));
    let ct = aead.encrypt(Nonce::from_slice(&nonce), plaintext)
        .context("AEAD encryption failed")?;

    // zeroize derived key material
    okm.zeroize();

    Ok(HybridCipher {
        kem_ciphertext: kem_ciphertext.as_bytes().to_vec(),
        nonce,
        ciphertext: ct,
    })
}

/// Perform hybrid decryption with recipient Kyber secret key.
pub fn hybrid_decrypt(recipient_sk: &SecretKey, hc: &HybridCipher) -> anyhow::Result<Vec<u8>> {
    // Reconstruct Kem ciphertext type accepted by pqcrypto:
    // The pqcrypto API expects its own ciphertext type. We attempt to create using from_bytes if available.
    // Many pqcrypto types provide `from_bytes` or `from` conversions. If your version differs you'll need to adapt this conversion.
    let kem_ct = pqcrypto_kyber::kyber512::Ciphertext::from_bytes(&hc.kem_ciphertext)
        .context("Failed to reconstruct KEM ciphertext from bytes; adapt to your pqcrypto API")?;

    // 1) Decapsulate -> shared secret
    let shared_secret = kyber512::decapsulate(&kem_ct, recipient_sk);
    let ss_bytes = shared_secret.as_bytes();

    // 2) Derive AES-256 key via HKDF-SHA256
    let hk = Hkdf::<Sha256>::new(None, ss_bytes);
    let mut okm = [0u8; AES_KEY_LEN];
    hk.expand(b"pq-envelope-aes-key", &mut okm)
        .context("HKDF expand failure")?;

    // 3) Decrypt AES-GCM
    let aead = Aes256Gcm::new(Key::from_slice(&okm));
    let pt = aead.decrypt(Nonce::from_slice(&hc.nonce), hc.ciphertext.as_ref())
        .context("AEAD decryption failed")?;

    okm.zeroize();
    Ok(pt)
}

#[cfg(test)]
mod tests {
    use super::*;
    use pqcrypto_kyber::kyber512;

    #[test]
    fn encrypt_decrypt_roundtrip() {
        // generate recipient keypair
        let (pk, sk) = kyber512::keypair();

        let plaintext = b"Hello post-quantum world!";
        let hc = hybrid_encrypt(&pk, plaintext).expect("encrypt failed");
        let decrypted = hybrid_decrypt(&sk, &hc).expect("decrypt failed");

        assert_eq!(plaintext.as_ref(), decrypted.as_slice());
    }
}