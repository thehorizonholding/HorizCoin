# Multi-stage Dockerfile for HorizCoin Server
# Build stage
FROM rust:1.70.0 AS builder

WORKDIR /app

# Copy workspace configuration
COPY Cargo.toml ./
COPY bins/server/Cargo.toml ./bins/server/

# Create dummy main.rs to cache dependencies
RUN mkdir -p bins/server/src && \
    echo "fn main() {}" > bins/server/src/main.rs

# Build dependencies (this layer will be cached if dependencies don't change)
RUN cargo build --release -p horizcoin-server

# Copy actual source code
COPY bins/server/src ./bins/server/src

# Build the actual application
RUN cargo build --release -p horizcoin-server

# Runtime stage
FROM debian:bookworm-slim

# Install CA certificates, curl for health check, and create non-root user
RUN apt-get update && \
    apt-get install -y ca-certificates curl && \
    rm -rf /var/lib/apt/lists/* && \
    useradd -r -u 1000 -m horizcoin

# Copy the binary from builder stage
COPY --from=builder /app/target/release/horizcoin-server /usr/local/bin/horizcoin-server

# Switch to non-root user
USER horizcoin

# Expose port 8080 for local development
# Note: Render will set the PORT environment variable
EXPOSE 8080

# Set default port if not provided
ENV PORT=8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:${PORT}/healthz || exit 1

# Run the application
ENTRYPOINT ["horizcoin-server"]