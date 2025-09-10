//! HorizCoin HTTP Server
//!
//! A minimal HTTP server that provides a public endpoint for the HorizCoin project.
//! This server offers basic health checking and project information endpoints
//! suitable for deployment to cloud platforms.

use axum::{
    response::Html,
    routing::get,
    Router,
};
use std::env;
use tracing::{info, warn};

/// Creates the main application router with all routes
fn app() -> Router {
    Router::new()
        .route("/", get(banner))
        .route("/healthz", get(health))
}

/// Returns a banner with package name and version
async fn banner() -> Html<String> {
    let name = env!("CARGO_PKG_NAME");
    let version = env!("CARGO_PKG_VERSION");
    
    let html = format!(
        r#"<!DOCTYPE html>
<html>
<head>
    <title>{name}</title>
    <style>
        body {{ 
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
            margin: 0;
            padding: 40px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }}
        .banner {{
            text-align: center;
            background: rgba(255, 255, 255, 0.1);
            padding: 60px;
            border-radius: 20px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
        }}
        h1 {{ 
            font-size: 3em; 
            margin: 0 0 20px 0;
            text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
        }}
        .version {{ 
            font-size: 1.2em; 
            opacity: 0.9;
            margin-bottom: 30px;
        }}
        .description {{
            font-size: 1.1em;
            line-height: 1.6;
            opacity: 0.8;
            max-width: 600px;
            margin: 0 auto;
        }}
    </style>
</head>
<body>
    <div class="banner">
        <h1>{name}</h1>
        <div class="version">Version {version}</div>
        <div class="description">
            A blockchain protocol implementing a Proof-of-Bandwidth consensus mechanism.
            This is the HTTP interface for the HorizCoin project.
        </div>
    </div>
</body>
</html>"#
    );
    
    Html(html)
}

/// Health check endpoint that returns "ok"
async fn health() -> &'static str {
    "ok"
}

#[tokio::main]
async fn main() {
    // Initialize tracing
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "horizcoin_server=info".into()),
        )
        .init();

    // Get port from environment variable or use default
    let port = env::var("PORT")
        .unwrap_or_else(|_| "8080".to_string())
        .parse::<u16>()
        .unwrap_or_else(|_| {
            warn!("Invalid PORT value, using default 8080");
            8080
        });

    let app = app();

    let listener = tokio::net::TcpListener::bind(format!("0.0.0.0:{port}"))
        .await
        .unwrap_or_else(|e| {
            panic!("Failed to bind to port {port}: {e}");
        });

    info!("HorizCoin server listening on port {port}");
    info!("Health check available at http://localhost:{port}/healthz");
    info!("Banner available at http://localhost:{port}/");

    axum::serve(listener, app)
        .await
        .unwrap_or_else(|e| {
            panic!("Server error: {e}");
        });
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::{
        body::Body,
        http::{Request, StatusCode},
    };
    use tower::ServiceExt;

    #[tokio::test]
    async fn test_health_endpoint() {
        let app = app();

        let response = app
            .oneshot(Request::builder().uri("/healthz").body(Body::empty()).unwrap())
            .await
            .unwrap();

        assert_eq!(response.status(), StatusCode::OK);

        let body = axum::body::to_bytes(response.into_body(), usize::MAX).await.unwrap();
        assert_eq!(&body[..], b"ok");
    }

    #[tokio::test]
    async fn test_banner_endpoint() {
        let app = app();

        let response = app
            .oneshot(Request::builder().uri("/").body(Body::empty()).unwrap())
            .await
            .unwrap();

        assert_eq!(response.status(), StatusCode::OK);

        let body = axum::body::to_bytes(response.into_body(), usize::MAX).await.unwrap();
        let body_str = String::from_utf8(body.to_vec()).unwrap();
        
        // Check that it contains the package name and version
        assert!(body_str.contains("horizcoin-server"));
        assert!(body_str.contains("0.1.0"));
        assert!(body_str.contains("HorizCoin"));
    }
}