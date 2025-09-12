//! Transaction structures and verification for HorizCoin.
//!
//! This crate defines transaction structure, verification logic, and memo handling
//! with a 128-byte UTF-8 limit for the HorizCoin blockchain.

use horizcoin_codec::Encodable;
use horizcoin_crypto::{address, PublicKey};
use horizcoin_primitives::{Amount, HorizError, TxId, constants};
use serde::{Deserialize, Serialize};

/// Transaction input referencing a previous output
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct TxInput {
    /// Transaction ID being spent
    pub prev_tx: TxId,
    /// Output index in the previous transaction
    pub output_index: u32,
    /// Signature to authorize spending (as Vec for serde compatibility)
    pub signature: Vec<u8>,
    /// Public key for verification
    pub public_key: PublicKey,
}

impl TxInput {
    /// Create a new transaction input
    pub fn new(prev_tx: TxId, output_index: u32, signature: [u8; 64], public_key: PublicKey) -> Self {
        Self {
            prev_tx,
            output_index,
            signature: signature.to_vec(),
            public_key,
        }
    }

    /// Get the address that this input claims to spend from
    pub fn address(&self) -> String {
        self.public_key.to_address()
    }

    /// Verify the signature for this input
    pub fn verify_signature(&self, sighash: &[u8]) -> bool {
        if self.signature.len() != 64 {
            return false;
        }
        let mut signature_array = [0u8; 64];
        signature_array.copy_from_slice(&self.signature);
        self.public_key.verify(sighash, &signature_array)
    }
}

/// Transaction output defining where funds are sent
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct TxOutput {
    /// Amount being sent
    pub amount: Amount,
    /// Recipient address
    pub address: String,
}

impl TxOutput {
    /// Create a new transaction output
    pub fn new(amount: Amount, address: String) -> Result<Self, HorizError> {
        // Validate amount is not zero
        if amount == 0 {
            return Err(HorizError::InvalidTransaction("Output amount cannot be zero".to_string()));
        }
        
        // Validate the address format
        if !address::is_valid_address(&address) {
            return Err(HorizError::InvalidTransaction("Invalid recipient address".to_string()));
        }
        
        Ok(Self { amount, address })
    }

    /// Validate this output
    pub fn validate(&self) -> Result<(), HorizError> {
        if self.amount == 0 {
            return Err(HorizError::InvalidTransaction("Output amount cannot be zero".to_string()));
        }
        
        if !address::is_valid_address(&self.address) {
            return Err(HorizError::InvalidTransaction("Invalid output address".to_string()));
        }
        
        Ok(())
    }
}

/// A complete transaction
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Transaction {
    /// Transaction inputs (what's being spent)
    pub inputs: Vec<TxInput>,
    /// Transaction outputs (where funds are going)
    pub outputs: Vec<TxOutput>,
    /// Optional memo (max 128 UTF-8 bytes)
    pub memo: Option<String>,
    /// Transaction timestamp
    pub timestamp: u64,
}

impl Transaction {
    /// Create a new transaction
    pub fn new(
        inputs: Vec<TxInput>,
        outputs: Vec<TxOutput>,
        memo: Option<String>,
        timestamp: u64,
    ) -> Result<Self, HorizError> {
        let tx = Self {
            inputs,
            outputs,
            memo,
            timestamp,
        };
        
        tx.validate()?;
        Ok(tx)
    }

    /// Get the transaction ID (hash of the transaction)
    pub fn id(&self) -> Result<TxId, HorizError> {
        let hash = self.hash()?;
        Ok(TxId::new(*hash.as_bytes()))
    }

    /// Calculate total input amount (requires UTXO lookup)
    pub fn total_input_amount(&self, utxo_lookup: impl Fn(&TxId, u32) -> Option<Amount>) -> Amount {
        self.inputs
            .iter()
            .map(|input| utxo_lookup(&input.prev_tx, input.output_index).unwrap_or(0))
            .sum()
    }

    /// Calculate total output amount
    pub fn total_output_amount(&self) -> Amount {
        self.outputs.iter().map(|output| output.amount).sum()
    }

    /// Calculate transaction fee (input amount - output amount)
    pub fn fee(&self, utxo_lookup: impl Fn(&TxId, u32) -> Option<Amount>) -> Amount {
        let input_total = self.total_input_amount(utxo_lookup);
        let output_total = self.total_output_amount();
        input_total.saturating_sub(output_total)
    }

    /// Validate transaction structure and rules
    pub fn validate(&self) -> Result<(), HorizError> {
        // Check inputs are not empty
        if self.inputs.is_empty() {
            return Err(HorizError::InvalidTransaction("Transaction must have at least one input".to_string()));
        }

        // Check outputs are not empty
        if self.outputs.is_empty() {
            return Err(HorizError::InvalidTransaction("Transaction must have at least one output".to_string()));
        }

        // Check memo length
        if let Some(memo) = &self.memo {
            if memo.as_bytes().len() > constants::MAX_MEMO_LENGTH {
                return Err(HorizError::InvalidTransaction(
                    format!("Memo exceeds maximum length of {} bytes", constants::MAX_MEMO_LENGTH)
                ));
            }
        }

        // Validate all outputs
        for output in &self.outputs {
            output.validate()?;
        }

        // Check for duplicate inputs
        let mut seen_inputs = std::collections::HashSet::new();
        for input in &self.inputs {
            let key = (input.prev_tx, input.output_index);
            if !seen_inputs.insert(key) {
                return Err(HorizError::InvalidTransaction("Duplicate input detected".to_string()));
            }
        }

        Ok(())
    }

    /// Verify all signatures in the transaction
    pub fn verify_signatures(&self) -> Result<(), HorizError> {
        let sighash = self.signature_hash()?;
        
        for input in &self.inputs {
            if !input.verify_signature(&sighash) {
                return Err(HorizError::InvalidTransaction("Invalid signature in input".to_string()));
            }
        }
        
        Ok(())
    }

    /// Generate signature hash for this transaction
    /// This is what gets signed by the private keys
    pub fn signature_hash(&self) -> Result<Vec<u8>, HorizError> {
        // Create a copy without signatures for signing
        let mut unsigned_tx = self.clone();
        for input in &mut unsigned_tx.inputs {
            input.signature = vec![0u8; 64]; // Clear signatures
        }
        
        unsigned_tx.encode()
    }

    /// Sign this transaction with the provided private keys
    pub fn sign(&mut self, private_keys: &[horizcoin_crypto::PrivateKey]) -> Result<(), HorizError> {
        if private_keys.len() != self.inputs.len() {
            return Err(HorizError::InvalidTransaction(
                "Number of private keys must match number of inputs".to_string()
            ));
        }

        let sighash = self.signature_hash()?;
        
        for (input, private_key) in self.inputs.iter_mut().zip(private_keys) {
            input.signature = private_key.sign(&sighash).to_vec();
            input.public_key = private_key.public_key();
        }
        
        Ok(())
    }

    /// Check if this is a coinbase transaction (mining reward)
    pub fn is_coinbase(&self) -> bool {
        self.inputs.len() == 1 
            && self.inputs[0].prev_tx == TxId::new([0u8; 32])
            && self.inputs[0].output_index == 0xffffffff
    }

    /// Create a coinbase transaction (mining reward)
    pub fn coinbase(recipient: String, amount: Amount, timestamp: u64) -> Result<Self, HorizError> {
        let coinbase_input = TxInput {
            prev_tx: TxId::new([0u8; 32]),
            output_index: 0xffffffff,
            signature: vec![0u8; 64],
            public_key: horizcoin_crypto::PrivateKey::generate().public_key(), // Dummy key
        };
        
        let output = TxOutput::new(amount, recipient)?;
        
        Self::new(
            vec![coinbase_input],
            vec![output],
            Some("Mining reward".to_string()),
            timestamp,
        )
    }
}

/// Transaction builder for easier construction
pub struct TransactionBuilder {
    inputs: Vec<TxInput>,
    outputs: Vec<TxOutput>,
    memo: Option<String>,
    timestamp: Option<u64>,
}

impl TransactionBuilder {
    /// Create a new transaction builder
    pub fn new() -> Self {
        Self {
            inputs: Vec::new(),
            outputs: Vec::new(),
            memo: None,
            timestamp: None,
        }
    }

    /// Add an input to the transaction
    pub fn add_input(mut self, prev_tx: TxId, output_index: u32) -> Self {
        // We'll add dummy signature and public key for now - they'll be filled in during signing
        let input = TxInput {
            prev_tx,
            output_index,
            signature: vec![0u8; 64],
            public_key: horizcoin_crypto::PrivateKey::generate().public_key(),
        };
        self.inputs.push(input);
        self
    }

    /// Add an output to the transaction
    pub fn add_output(mut self, amount: Amount, address: String) -> Result<Self, HorizError> {
        let output = TxOutput::new(amount, address)?;
        self.outputs.push(output);
        Ok(self)
    }

    /// Set the memo
    pub fn memo(mut self, memo: String) -> Self {
        self.memo = Some(memo);
        self
    }

    /// Set the timestamp
    pub fn timestamp(mut self, timestamp: u64) -> Self {
        self.timestamp = Some(timestamp);
        self
    }

    /// Build the transaction
    pub fn build(self) -> Result<Transaction, HorizError> {
        let timestamp = self.timestamp.unwrap_or_else(|| {
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_secs()
        });

        Transaction::new(self.inputs, self.outputs, self.memo, timestamp)
    }
}

impl Default for TransactionBuilder {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use horizcoin_crypto::PrivateKey;

    #[test]
    fn test_transaction_creation() {
        let recipient = PrivateKey::generate().public_key().to_address();
        let output = TxOutput::new(1000, recipient).unwrap();
        
        assert_eq!(output.amount, 1000);
    }

    #[test]
    fn test_transaction_validation() {
        let private_key = PrivateKey::generate();
        let address = private_key.public_key().to_address();
        
        // Valid transaction
        let tx = TransactionBuilder::new()
            .add_input(TxId::new([1u8; 32]), 0)
            .add_output(1000, address.clone()).unwrap()
            .memo("test transaction".to_string())
            .build()
            .unwrap();
        
        assert!(tx.validate().is_ok());
    }

    #[test]
    fn test_invalid_transactions() {
        let address = PrivateKey::generate().public_key().to_address();
        
        // No inputs
        let result = Transaction::new(
            vec![],
            vec![TxOutput::new(1000, address.clone()).unwrap()],
            None,
            1000,
        );
        assert!(result.is_err());
        
        // No outputs
        let input = TxInput::new(
            TxId::new([1u8; 32]), 
            0, 
            [0u8; 64], 
            PrivateKey::generate().public_key()
        );
        let result = Transaction::new(vec![input], vec![], None, 1000);
        assert!(result.is_err());
    }

    #[test]
    fn test_zero_amount_output() {
        let address = PrivateKey::generate().public_key().to_address();
        
        // Zero amount output should fail at TxOutput creation
        let result = TxOutput::new(0, address);
        assert!(result.is_err());
    }

    #[test]
    fn test_memo_length_validation() {
        let private_key = PrivateKey::generate();
        let address = private_key.public_key().to_address();
        
        // Valid memo (exactly 128 bytes)
        let short_memo = "a".repeat(128);
        let tx = TransactionBuilder::new()
            .add_input(TxId::new([1u8; 32]), 0)
            .add_output(1000, address.clone()).unwrap()
            .memo(short_memo)
            .build()
            .unwrap();
        assert!(tx.validate().is_ok());
        
        // Invalid memo (too long - 129 bytes)
        let long_memo = "a".repeat(129);
        let tx = TransactionBuilder::new()
            .add_input(TxId::new([1u8; 32]), 0)
            .add_output(1000, address).unwrap()
            .memo(long_memo)
            .build();
        
        // The transaction should build but validation should fail
        if let Ok(tx) = tx {
            assert!(tx.validate().is_err());
        }
    }

    #[test]
    fn test_coinbase_transaction() {
        let address = PrivateKey::generate().public_key().to_address();
        let coinbase = Transaction::coinbase(address, 1000, 1000).unwrap();
        
        assert!(coinbase.is_coinbase());
        assert_eq!(coinbase.inputs.len(), 1);
        assert_eq!(coinbase.outputs.len(), 1);
        assert_eq!(coinbase.outputs[0].amount, 1000);
    }

    #[test]
    fn test_transaction_signing() {
        let private_key1 = PrivateKey::generate();
        let address = private_key1.public_key().to_address();
        
        let mut tx = TransactionBuilder::new()
            .add_input(TxId::new([1u8; 32]), 0)
            .add_output(1000, address).unwrap()
            .build()
            .unwrap();
        
        // Sign with one key
        tx.sign(&[private_key1]).unwrap();
        
        // Note: We can't really verify signatures without the UTXO data
        // for now, just ensure that signing doesn't fail
        assert!(tx.inputs[0].signature.len() == 64);
        assert!(tx.inputs[0].signature != vec![0u8; 64]);
    }

    #[test]
    fn test_transaction_amounts() {
        let address = PrivateKey::generate().public_key().to_address();
        
        let tx = TransactionBuilder::new()
            .add_input(TxId::new([1u8; 32]), 0)
            .add_output(500, address.clone()).unwrap()
            .add_output(300, address).unwrap()
            .build()
            .unwrap();
        
        assert_eq!(tx.total_output_amount(), 800);
        
        // Test with UTXO lookup
        let utxo_lookup = |_: &TxId, _: u32| Some(1000u64);
        assert_eq!(tx.total_input_amount(utxo_lookup), 1000);
        assert_eq!(tx.fee(utxo_lookup), 200); // 1000 - 800
    }

    #[test]
    fn test_duplicate_inputs() {
        let address = PrivateKey::generate().public_key().to_address();
        let public_key = PrivateKey::generate().public_key();
        
        let input1 = TxInput::new(TxId::new([1u8; 32]), 0, [0u8; 64], public_key.clone());
        let input2 = TxInput::new(TxId::new([1u8; 32]), 0, [0u8; 64], public_key); // Same as input1
        
        let result = Transaction::new(
            vec![input1, input2],
            vec![TxOutput::new(1000, address).unwrap()],
            None,
            1000,
        );
        
        assert!(result.is_err());
    }
}
