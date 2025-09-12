//! HorizCoin Web Demo Binary
//!
//! A minimal HTTP server that serves a basic HTML page, health check endpoint,
//! and Phase 0 card demo functionality with mocked API endpoints.
//! Designed for deployment on GitHub Copilot Spaces to provide a public demo URL.

use axum::{
    extract::State,
    http::StatusCode,
    response::{Html, IntoResponse, Json},
    routing::{get, post},
    Router,
};
use serde::{Deserialize, Serialize};
use std::{
    net::SocketAddr,
    sync::{Arc, Mutex},
};
use tracing::{info, warn};

/// Card state for managing freeze/unfreeze functionality
#[derive(Debug, Clone, Serialize)]
struct CardState {
    frozen: bool,
    balance: f64,
    currency: String,
    last4: String,
    network: String,
    version: String,
}

/// Virtual card token information
#[derive(Debug, Serialize)]
struct VirtualCard {
    token_id: String,
    last4: String,
    expiry: CardExpiry,
    network: String,
    brand: String,
    pan_mask: String,
}

/// Card expiry information
#[derive(Debug, Serialize)]
struct CardExpiry {
    month: u8,
    year: u16,
}

/// Wallet tokenization response
#[derive(Debug, Serialize)]
struct TokenizeResponse {
    tokenized: bool,
    wallet: String,
    token_id: String,
}

/// Transaction record
#[derive(Debug, Serialize)]
struct Transaction {
    id: String,
    amount: f64,
    currency: String,
    merchant: String,
    mcc: String,
    status: String,
    timestamp: String,
    description: String,
}

/// Wallet tokenization request
#[derive(Debug, Deserialize)]
struct TokenizeRequest {
    wallet: String, // "apple" or "google"
}

/// Application state
type AppState = Arc<Mutex<CardState>>;

/// Main entry point for the HorizCoin web demo server
#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Initialize tracing
    tracing_subscriber::fmt::init();

    let port = std::env::var("PORT")
        .unwrap_or_else(|_| "3000".to_string())
        .parse::<u16>()
        .unwrap_or_else(|_| {
            warn!("Invalid PORT value, defaulting to 3000");
            3000
        });

    let bind_addr = SocketAddr::from(([0, 0, 0, 0], port));

    // Initialize card state
    let card_state = Arc::new(Mutex::new(CardState {
        frozen: false,
        balance: 1000.00,
        currency: "USD".to_string(),
        last4: "4242".to_string(),
        network: "visa".to_string(),
        version: env!("CARGO_PKG_VERSION").to_string(),
    }));

    // Build our application with the routes
    let app = Router::new()
        .route("/", get(root_handler))
        .route("/card", get(card_page_handler))
        .route("/healthz", get(health_handler))
        .route("/api/card/status", get(card_status_handler))
        .route("/api/card/freeze", post(card_freeze_handler))
        .route("/api/card/unfreeze", post(card_unfreeze_handler))
        .route("/api/card/virtual", get(card_virtual_handler))
        .route("/api/card/tokenize/wallet", post(card_tokenize_handler))
        .route("/api/card/transactions", get(card_transactions_handler))
        .with_state(card_state);

    info!(
        "HorizCoin Web Demo v{} starting on {}",
        env!("CARGO_PKG_VERSION"),
        bind_addr
    );

    // Start the server
    axum::Server::bind(&bind_addr)
        .serve(app.into_make_service())
        .await?;

    Ok(())
}

/// Handle requests to the root path
async fn root_handler() -> impl IntoResponse {
    let html = format!(
        r#"<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>HorizCoin</title>
    <style>
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 2rem;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            justify-content: center;
        }}
        .container {{
            background: rgba(255, 255, 255, 0.1);
            padding: 2rem;
            border-radius: 10px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
        }}
        h1 {{
            font-size: 3rem;
            margin-bottom: 1rem;
            text-align: center;
        }}
        .version {{
            text-align: center;
            font-size: 1.2rem;
            opacity: 0.8;
            margin-bottom: 2rem;
        }}
        .description {{
            font-size: 1.1rem;
            line-height: 1.6;
            text-align: center;
        }}
        .links {{
            margin-top: 2rem;
            text-align: center;
        }}
        .links a {{
            color: #fff;
            text-decoration: none;
            padding: 0.5rem 1rem;
            border: 1px solid rgba(255, 255, 255, 0.3);
            border-radius: 5px;
            margin: 0 0.5rem;
            transition: all 0.3s ease;
            display: inline-block;
        }}
        .links a:hover {{
            background: rgba(255, 255, 255, 0.2);
            transform: translateY(-2px);
        }}
        .demo-badge {{
            background: #ff6b6b;
            color: white;
            padding: 0.5rem 1rem;
            border-radius: 20px;
            font-size: 0.9rem;
            margin-bottom: 1rem;
            display: inline-block;
        }}
    </style>
</head>
<body>
    <div class="container">
        <h1>🌅 HorizCoin</h1>
        <div class="version">Version {}</div>
        <div class="description">
            <div class="demo-badge">Phase 0 Demo Available</div>
            <p>A blockchain protocol implementing a Proof-of-Bandwidth consensus mechanism.</p>
            <p>This is a live demo instance of the HorizCoin web interface.</p>
        </div>
        <div class="links">
            <a href="https://github.com/thehorizonholding/HorizCoin" target="_blank">GitHub Repository</a>
            <a href="/card">Card Demo</a>
            <a href="/healthz">Health Check</a>
        </div>
    </div>
</body>
</html>"#,
        env!("CARGO_PKG_VERSION")
    );

    Html(html)
}

/// Handle health check requests
async fn health_handler() -> impl IntoResponse {
    (StatusCode::OK, "ok")
}

/// Handle card page requests
async fn card_page_handler() -> impl IntoResponse {
    let html = r##"<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>HorizCoin Card Demo</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://unpkg.com/htmx.org@1.9.6"></script>
</head>
<body class="bg-gradient-to-br from-purple-600 via-blue-600 to-indigo-700 min-h-screen">
    <div class="container mx-auto px-4 py-8">
        <!-- Navigation -->
        <nav class="mb-8">
            <div class="flex items-center justify-between">
                <div class="flex items-center space-x-4">
                    <h1 class="text-3xl font-bold text-white">🌅 HorizCoin</h1>
                    <span class="bg-red-500 text-white px-3 py-1 rounded-full text-sm font-medium">DEMO</span>
                </div>
                <a href="/" class="text-white hover:text-blue-200 transition-colors">← Back to Home</a>
            </div>
        </nav>

        <!-- Demo Disclaimer -->
        <div class="bg-yellow-100 border-l-4 border-yellow-500 text-yellow-700 p-4 mb-6 rounded">
            <div class="flex">
                <div class="flex-shrink-0">
                    <svg class="h-5 w-5 text-yellow-400" viewBox="0 0 20 20" fill="currentColor">
                        <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
                    </svg>
                </div>
                <div class="ml-3">
                    <p class="text-sm">
                        <strong>Demo only</strong> – No real card or banking data; all responses are mocked.
                    </p>
                </div>
            </div>
        </div>

        <div class="grid lg:grid-cols-2 gap-8">
            <!-- Virtual Card -->
            <div class="bg-white/10 backdrop-blur-lg rounded-xl p-6 text-white">
                <h2 class="text-xl font-semibold mb-4">Virtual Card</h2>
                <div class="bg-gradient-to-r from-gray-800 to-gray-900 rounded-lg p-6 text-white relative overflow-hidden">
                    <div class="absolute top-0 right-0 w-32 h-32 bg-white/5 rounded-full -mr-16 -mt-16"></div>
                    <div class="relative z-10">
                        <div class="flex justify-between items-start mb-8">
                            <div>
                                <div class="text-xs opacity-70 mb-1">CARDHOLDER NAME</div>
                                <div class="font-medium">HorizCoin Demo</div>
                            </div>
                            <div class="text-right">
                                <div class="text-xs opacity-70 mb-1">NETWORK</div>
                                <div class="font-bold text-blue-400">VISA</div>
                            </div>
                        </div>
                        <div class="text-xl font-mono tracking-wider mb-6">•••• •••• •••• 4242</div>
                        <div class="flex justify-between items-end">
                            <div>
                                <div class="text-xs opacity-70 mb-1">EXPIRES</div>
                                <div class="font-medium">12/30</div>
                            </div>
                            <div class="text-xs opacity-70">HorizCoin Demo Card</div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Card Status -->
            <div class="bg-white/10 backdrop-blur-lg rounded-xl p-6 text-white">
                <h2 class="text-xl font-semibold mb-4">Card Status</h2>
                <div id="card-status" hx-get="/api/card/status" hx-trigger="load" hx-swap="innerHTML">
                    Loading status...
                </div>
            </div>

            <!-- Card Controls -->
            <div class="bg-white/10 backdrop-blur-lg rounded-xl p-6 text-white">
                <h2 class="text-xl font-semibold mb-4">Controls</h2>
                <div class="space-y-4">
                    <button
                        hx-post="/api/card/freeze"
                        hx-target="#card-status"
                        hx-swap="innerHTML"
                        class="w-full bg-red-600 hover:bg-red-700 text-white font-bold py-2 px-4 rounded transition-colors">
                        Freeze Card
                    </button>
                    <button
                        hx-post="/api/card/unfreeze"
                        hx-target="#card-status"
                        hx-swap="innerHTML"
                        class="w-full bg-green-600 hover:bg-green-700 text-white font-bold py-2 px-4 rounded transition-colors">
                        Unfreeze Card
                    </button>
                    <button
                        hx-get="/api/card/virtual"
                        hx-target="#virtual-card-info"
                        hx-swap="innerHTML"
                        class="w-full bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded transition-colors">
                        Regenerate Virtual Card Token
                    </button>
                </div>
                <div id="virtual-card-info" class="mt-4"></div>
            </div>

            <!-- Transactions -->
            <div class="bg-white/10 backdrop-blur-lg rounded-xl p-6 text-white">
                <h2 class="text-xl font-semibold mb-4">Recent Transactions</h2>
                <div id="transactions" hx-get="/api/card/transactions" hx-trigger="load" hx-swap="innerHTML">
                    Loading transactions...
                </div>
            </div>
        </div>

        <!-- Wallet Tokenization -->
        <div class="mt-8 bg-white/10 backdrop-blur-lg rounded-xl p-6 text-white">
            <h2 class="text-xl font-semibold mb-4">Wallet Tokenization (Demo)</h2>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <button
                    hx-post="/api/card/tokenize/wallet"
                    hx-vals='{"wallet": "apple"}'
                    hx-target="#tokenize-result"
                    hx-swap="innerHTML"
                    class="bg-black hover:bg-gray-800 text-white font-bold py-3 px-6 rounded-lg transition-colors flex items-center justify-center space-x-2">
                    <span>🍎</span>
                    <span>Add to Apple Pay</span>
                </button>
                <button
                    hx-post="/api/card/tokenize/wallet"
                    hx-vals='{"wallet": "google"}'
                    hx-target="#tokenize-result"
                    hx-swap="innerHTML"
                    class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-3 px-6 rounded-lg transition-colors flex items-center justify-center space-x-2">
                    <span>📱</span>
                    <span>Add to Google Pay</span>
                </button>
            </div>
            <div id="tokenize-result" class="mt-4"></div>
        </div>
    </div>
</body>
</html>"##;

    Html(html)
}

/// Handle card status requests
async fn card_status_handler(State(state): State<AppState>) -> impl IntoResponse {
    let card_state = state.lock().unwrap();
    let status_html = format!(
        r#"
        <div class="space-y-3">
            <div class="flex justify-between">
                <span class="text-sm opacity-70">Program Status:</span>
                <span class="text-green-400 font-medium">OK</span>
            </div>
            <div class="flex justify-between">
                <span class="text-sm opacity-70">Card Status:</span>
                <span class="font-medium {}">{}</span>
            </div>
            <div class="flex justify-between">
                <span class="text-sm opacity-70">Balance:</span>
                <span class="font-medium">{:.2} {}</span>
            </div>
            <div class="flex justify-between">
                <span class="text-sm opacity-70">Network:</span>
                <span class="font-medium text-blue-400">{}</span>
            </div>
            <div class="flex justify-between">
                <span class="text-sm opacity-70">Last Four:</span>
                <span class="font-medium">{}</span>
            </div>
            <div class="flex justify-between">
                <span class="text-sm opacity-70">Version:</span>
                <span class="font-medium">{}</span>
            </div>
        </div>
        "#,
        if card_state.frozen { "text-red-400" } else { "text-green-400" },
        if card_state.frozen { "Frozen" } else { "Active" },
        card_state.balance,
        card_state.currency,
        card_state.network.to_uppercase(),
        card_state.last4,
        card_state.version
    );

    Html(status_html)
}

/// Handle card freeze requests
async fn card_freeze_handler(State(state): State<AppState>) -> impl IntoResponse {
    let mut card_state = state.lock().unwrap();
    card_state.frozen = true;
    
    let status_html = format!(
        r#"
        <div class="space-y-3">
            <div class="flex justify-between">
                <span class="text-sm opacity-70">Program Status:</span>
                <span class="text-green-400 font-medium">OK</span>
            </div>
            <div class="flex justify-between">
                <span class="text-sm opacity-70">Card Status:</span>
                <span class="font-medium text-red-400">Frozen</span>
            </div>
            <div class="flex justify-between">
                <span class="text-sm opacity-70">Balance:</span>
                <span class="font-medium">{:.2} {}</span>
            </div>
            <div class="flex justify-between">
                <span class="text-sm opacity-70">Network:</span>
                <span class="font-medium text-blue-400">{}</span>
            </div>
            <div class="flex justify-between">
                <span class="text-sm opacity-70">Last Four:</span>
                <span class="font-medium">{}</span>
            </div>
            <div class="flex justify-between">
                <span class="text-sm opacity-70">Version:</span>
                <span class="font-medium">{}</span>
            </div>
        </div>
        "#,
        card_state.balance,
        card_state.currency,
        card_state.network.to_uppercase(),
        card_state.last4,
        card_state.version
    );

    Html(status_html)
}

/// Handle card unfreeze requests
async fn card_unfreeze_handler(State(state): State<AppState>) -> impl IntoResponse {
    let mut card_state = state.lock().unwrap();
    card_state.frozen = false;
    
    let status_html = format!(
        r#"
        <div class="space-y-3">
            <div class="flex justify-between">
                <span class="text-sm opacity-70">Program Status:</span>
                <span class="text-green-400 font-medium">OK</span>
            </div>
            <div class="flex justify-between">
                <span class="text-sm opacity-70">Card Status:</span>
                <span class="font-medium text-green-400">Active</span>
            </div>
            <div class="flex justify-between">
                <span class="text-sm opacity-70">Balance:</span>
                <span class="font-medium">{:.2} {}</span>
            </div>
            <div class="flex justify-between">
                <span class="text-sm opacity-70">Network:</span>
                <span class="font-medium text-blue-400">{}</span>
            </div>
            <div class="flex justify-between">
                <span class="text-sm opacity-70">Last Four:</span>
                <span class="font-medium">{}</span>
            </div>
            <div class="flex justify-between">
                <span class="text-sm opacity-70">Version:</span>
                <span class="font-medium">{}</span>
            </div>
        </div>
        "#,
        card_state.balance,
        card_state.currency,
        card_state.network.to_uppercase(),
        card_state.last4,
        card_state.version
    );

    Html(status_html)
}

/// Handle virtual card token requests
async fn card_virtual_handler() -> impl IntoResponse {
    let virtual_card = VirtualCard {
        token_id: "tok_hzc_demo_12345".to_string(),
        last4: "4242".to_string(),
        expiry: CardExpiry { month: 12, year: 2030 },
        network: "visa".to_string(),
        brand: "HorizCoin Demo".to_string(),
        pan_mask: "**** **** **** 4242".to_string(),
    };

    let html = format!(
        r#"
        <div class="bg-gray-800/50 rounded p-3 text-sm">
            <div class="text-green-400 font-medium mb-2">Virtual Card Token Generated</div>
            <div class="space-y-1 text-xs">
                <div>Token ID: {}</div>
                <div>PAN Mask: {}</div>
                <div>Expiry: {}/{}</div>
                <div>Network: {}</div>
            </div>
        </div>
        "#,
        virtual_card.token_id,
        virtual_card.pan_mask,
        virtual_card.expiry.month,
        virtual_card.expiry.year,
        virtual_card.network.to_uppercase()
    );

    Html(html)
}

/// Handle wallet tokenization requests
async fn card_tokenize_handler(Json(payload): Json<TokenizeRequest>) -> impl IntoResponse {
    let response = TokenizeResponse {
        tokenized: true,
        wallet: payload.wallet.clone(),
        token_id: format!("tok_{}_{}", payload.wallet, &uuid::Uuid::new_v4().to_string()[..8]),
    };

    let html = format!(
        r#"
        <div class="bg-green-800/50 rounded p-3 text-sm">
            <div class="text-green-400 font-medium mb-2">Successfully Added to {} Pay</div>
            <div class="text-xs">Token ID: {}</div>
        </div>
        "#,
        match response.wallet.as_str() {
            "apple" => "Apple",
            "google" => "Google",
            _ => "Wallet",
        },
        response.token_id
    );

    Html(html)
}

/// Handle transaction list requests
async fn card_transactions_handler() -> impl IntoResponse {
    let transactions = vec![
        Transaction {
            id: "txn_001".to_string(),
            amount: -25.50,
            currency: "USD".to_string(),
            merchant: "Coffee Bean & Tea Leaf".to_string(),
            mcc: "5814".to_string(),
            status: "cleared".to_string(),
            timestamp: "2024-01-15T10:30:00Z".to_string(),
            description: "Coffee purchase".to_string(),
        },
        Transaction {
            id: "txn_002".to_string(),
            amount: -89.99,
            currency: "USD".to_string(),
            merchant: "Amazon.com".to_string(),
            mcc: "5942".to_string(),
            status: "cleared".to_string(),
            timestamp: "2024-01-14T16:45:00Z".to_string(),
            description: "Online purchase".to_string(),
        },
        Transaction {
            id: "txn_003".to_string(),
            amount: -12.75,
            currency: "USD".to_string(),
            merchant: "Metro Transit".to_string(),
            mcc: "4111".to_string(),
            status: "cleared".to_string(),
            timestamp: "2024-01-14T08:15:00Z".to_string(),
            description: "Public transportation".to_string(),
        },
        Transaction {
            id: "txn_004".to_string(),
            amount: -45.20,
            currency: "USD".to_string(),
            merchant: "Shell Gas Station".to_string(),
            mcc: "5541".to_string(),
            status: "auth".to_string(),
            timestamp: "2024-01-13T19:20:00Z".to_string(),
            description: "Fuel purchase".to_string(),
        },
        Transaction {
            id: "txn_005".to_string(),
            amount: 500.00,
            currency: "USD".to_string(),
            merchant: "HorizCoin Demo Load".to_string(),
            mcc: "6051".to_string(),
            status: "cleared".to_string(),
            timestamp: "2024-01-13T09:00:00Z".to_string(),
            description: "Demo account funding".to_string(),
        },
    ];

    let mut html = String::from(r#"<div class="space-y-3 max-h-64 overflow-y-auto">"#);
    
    for txn in transactions {
        let amount_color = if txn.amount >= 0.0 { "text-green-400" } else { "text-red-400" };
        let status_color = match txn.status.as_str() {
            "cleared" => "text-green-400",
            "auth" => "text-yellow-400",
            "reversed" => "text-red-400",
            _ => "text-gray-400",
        };
        
        html.push_str(&format!(
            r#"
            <div class="bg-gray-800/30 rounded p-3">
                <div class="flex justify-between items-start mb-1">
                    <div class="font-medium text-sm">{}</div>
                    <div class="font-bold {} text-sm">{:+.2} {}</div>
                </div>
                <div class="flex justify-between items-center text-xs opacity-70">
                    <div>{}</div>
                    <div class="{}">● {}</div>
                </div>
                <div class="text-xs opacity-50 mt-1">{}</div>
            </div>
            "#,
            txn.merchant,
            amount_color,
            txn.amount,
            txn.currency,
            txn.timestamp.split('T').next().unwrap_or(""),
            status_color,
            txn.status.to_uppercase(),
            txn.description
        ));
    }
    
    html.push_str("</div>");
    Html(html)
}
