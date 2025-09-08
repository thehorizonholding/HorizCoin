//! Constants used throughout the HorizCoin implementation

/// Maximum allowed length for transaction memo in bytes (UTF-8)
pub const MEMO_MAX_LENGTH: usize = 128;

/// Allowable future timestamp skew in seconds
pub const TIMESTAMP_FUTURE_SKEW_SECS: u64 = 120;

/// Maximum allowed past timestamp skew in seconds (24 hours)
pub const TIMESTAMP_PAST_SKEW_SECS: u64 = 24 * 60 * 60;
