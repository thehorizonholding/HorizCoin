# HorizCoin

Proof-of-Bandwidth (PoB) protocol – initial scaffold.

## Goals (Early Phase)
- Provide a placeholder CLI (`horizcoin`) to bootstrap development.
- Establish telemetry & observability initiative structure (see [docs/telemetry-initiative-execution.md](docs/telemetry-initiative-execution.md)).

## Quick Start

### Prerequisites
- Go 1.22+ installed.

### Build
```bash
make build
```

### Run
```bash
./bin/horizcoin --version
./bin/horizcoin demo
```

### Test (placeholder)
```bash
make test
```

## Directory Structure
```
cmd/horizcoin/     CLI entrypoint
internal/version/  Version metadata
docs/              Initiative & specification docs
scripts/           Automation scripts (progress updater, etc.)
.github/workflows/ CI & automation
```

## Telemetry Initiative
See the execution pack: [docs/telemetry-initiative-execution.md](docs/telemetry-initiative-execution.md)

## License
TBD (add an OSS license before public release).