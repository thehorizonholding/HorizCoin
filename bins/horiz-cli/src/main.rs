//! `HorizCoin` CLI
//!
//! Command-line interface for interacting with `HorizCoin`.

fn main() {
    println!("HorizCoin CLI v{}", env!("CARGO_PKG_VERSION"));
    println!();
    println!("USAGE:");
    println!("    horiz-cli [OPTIONS] <COMMAND>");
    println!();
    println!("COMMANDS:");
    println!("    wallet      Wallet management commands");
    println!("    tx          Transaction operations");
    println!("    node        Node management commands");
    println!("    help        Print this help message");
    println!();
    println!("OPTIONS:");
    println!("    -h, --help     Print help information");
    println!("    -V, --version  Print version information");
    println!();
    println!("For more information about a specific command, use:");
    println!("    horiz-cli <COMMAND> --help");

    // Exit successfully for now
    std::process::exit(0);
}
