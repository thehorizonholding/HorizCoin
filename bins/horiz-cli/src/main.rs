//! HorizCoin command-line interface.

fn main() {
    let version = env!("CARGO_PKG_VERSION");
    println!("horiz-cli v{}", version);
    println!("Usage: horiz-cli [COMMAND]");
    println!("");
    println!("Commands:");
    println!("  wallet    Wallet management commands");
    println!("  send      Send transactions");
    println!("  balance   Check account balance");
    println!("  help      Show this help message");
    println!("");
    println!("Run 'horiz-cli <COMMAND> --help' for more information on a command.");
    std::process::exit(0);
}