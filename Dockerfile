# Multi-stage build for HorizCoin Web Demo
FROM rust:1.75 AS builder

WORKDIR /usr/src/horizcoin

# Install ca-certificates to fix potential SSL issues
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

# Copy workspace configuration
COPY Cargo.toml ./
COPY rustfmt.toml ./

# Copy source code
COPY crates/ ./crates/
COPY bins/ ./bins/

# Build the web binary in release mode
RUN cargo build --release -p horizcoin-web

# Runtime stage using minimal debian image
FROM debian:bookworm-slim

# Install ca-certificates and curl for health checks
RUN apt-get update && apt-get install -y ca-certificates curl && rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN useradd -r -s /bin/false horizcoin

# Copy the built binary
COPY --from=builder /usr/src/horizcoin/target/release/horizcoin-web /usr/local/bin/horizcoin-web

# Switch to non-root user
USER horizcoin

# Set environment variables
ENV PORT=3000

# Expose the port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:${PORT}/healthz || exit 1

# Run the binary
CMD ["horizcoin-web"]