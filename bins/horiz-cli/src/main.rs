//! `HorizCoin` command-line interface.

fn main() {
    println!("HorizCoin CLI v{}", env!("CARGO_PKG_VERSION"));
    println!();
    println!("Usage:");
    println!("  horiz-cli [COMMAND] [OPTIONS]");
    println!();
    println!("Commands:");
    println!("  wallet      Wallet management commands");
    println!("  send        Send transactions");
    println!("  balance     Check account balance");
    println!("  help        Show this help message");
    println!();
    println!("Options:");
    println!("  --help      Show help information");
    println!("  --version   Show version information");
    println!();
    println!("For more information on a specific command, use:");
    println!("  horiz-cli <command> --help");

    std::process::exit(0);
}
