use horizcoin::*;

fn main() {
    println!("HorizCoin - Proof-of-Bandwidth Protocol");
    println!("========================================");

    // Demonstrate key parameters
    println!("Configuration:");
    println!("  Memo max length: {} bytes", MEMO_MAX_LENGTH);
    println!(
        "  Timestamp future skew: {} seconds",
        TIMESTAMP_FUTURE_SKEW_SECS
    );
    println!(
        "  Timestamp past skew: {} seconds",
        TIMESTAMP_PAST_SKEW_SECS
    );
    println!();

    // Create a sample transaction
    let tx = Transaction::new(
        "alice".to_string(),
        "bob".to_string(),
        1000,
        10,
        Some("Payment for services".to_string()),
        1,
        current_timestamp(),
    )
    .unwrap();

    println!("Sample Transaction:");
    println!("  From: {}", tx.from);
    println!("  To: {}", tx.to);
    println!("  Amount: {}", tx.amount);
    println!("  Fee: {}", tx.fee);
    println!("  Memo: {:?}", tx.memo);
    println!("  TxID: {:?}", hex::encode(tx.txid()));
    println!();

    // Create a block
    let block = Block::new([0u8; 32], vec![tx], current_timestamp(), 1);

    println!("Sample Block:");
    println!("  Height: {}", block.header.height);
    println!("  Timestamp: {}", block.header.timestamp);
    println!("  Transactions: {}", block.transaction_count());
    println!("  Merkle Root: {:?}", hex::encode(block.header.merkle_root));
    println!("  Block Hash: {:?}", hex::encode(block.hash()));
    println!();

    // Validate the block
    match validate_block_basic(&block) {
        Ok(()) => println!("✅ Block validation passed"),
        Err(e) => println!("❌ Block validation failed: {}", e),
    }

    println!("\nHashing uses single SHA-256 (not double-hash)");
    println!("Merkle tree duplicates last leaf for odd counts");
    println!("Economic target: $80T over 10 years (issue #33)");
}
