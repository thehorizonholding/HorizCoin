//! HorizCoin Web Demo Binary
//!
//! A minimal HTTP server that serves a basic HTML page and health check endpoint.
//! Designed for deployment on GitHub Copilot Spaces to provide a public demo URL.

use axum::{
    http::StatusCode,
    response::{Html, IntoResponse},
    routing::get,
    Router,
};
use std::net::SocketAddr;
use tracing::{info, warn};

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

    // Build our application with the routes
    let app = Router::new()
        .route("/", get(root_handler))
        .route("/healthz", get(health_handler));

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
        }}
        .links a:hover {{
            background: rgba(255, 255, 255, 0.2);
            transform: translateY(-2px);
        }}
    </style>
</head>
<body>
    <div class="container">
        <h1>🌅 HorizCoin</h1>
        <div class="version">Version {}</div>
        <div class="description">
            <p>A blockchain protocol implementing a Proof-of-Bandwidth consensus mechanism.</p>
            <p>This is a live demo instance of the HorizCoin web interface.</p>
        </div>
        <div class="links">
            <a href="https://github.com/thehorizonholding/HorizCoin" target="_blank">GitHub Repository</a>
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