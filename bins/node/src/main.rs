//! `HorizCoin` node binary.

fn main() {
    let version = env!("CARGO_PKG_VERSION");
    println!("HorizCoin Node v{version}");
    println!("Starting HorizCoin blockchain node...");
    println!("Node initialized successfully. Exiting for development mode.");
    std::process::exit(0);
}
