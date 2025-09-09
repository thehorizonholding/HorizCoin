# Contributing to HorizCoin

We welcome contributions to HorizCoin! This document outlines the development process, coding standards, and how to submit changes.

## Development Workflow

1. **Fork the repository** on GitHub
2. **Create a feature branch** from `main` for your changes
3. **Make your changes** following our coding standards
4. **Test thoroughly** - all tests must pass
5. **Submit a pull request** with a clear description

## Setting Up Development Environment

### Prerequisites

- Rust 1.70+ with Cargo
- Git
- A text editor or IDE with Rust support

### Initial Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/HorizCoin.git
cd HorizCoin

# Add upstream remote
git remote add upstream https://github.com/thehorizonholding/HorizCoin.git

# Install development dependencies
cargo install cargo-llvm-cov cargo-fuzz cargo-audit

# Build and test
cargo build
cargo test
```

## Coding Standards

### Rust Style

- **Formatting**: Use `cargo fmt` with the project's `rustfmt.toml`
- **Linting**: All code must pass `cargo clippy -- -D warnings`
- **Documentation**: Public APIs must have comprehensive documentation
- **Testing**: New code must include appropriate tests

### Code Organization

- **Modularity**: Keep crates focused on single responsibilities
- **Error Handling**: Use `thiserror` for structured error types
- **Async Code**: Use `tokio` for async runtime, `tracing` for logging
- **Dependencies**: Minimize external dependencies, prefer std when possible

### Commit Messages

Use conventional commit format:
```
type(scope): description

[optional body]

[optional footer]
```

Types: `feat`, `fix`, `docs`, `test`, `refactor`, `perf`, `chore`

Examples:
- `feat(tx): add memo field validation`
- `fix(p2p): handle connection timeout properly`
- `docs(readme): update quickstart guide`

## Testing

### Test Categories

1. **Unit Tests**: Test individual functions and modules
2. **Integration Tests**: Test component interactions
3. **Property Tests**: Use `proptest` for property-based testing
4. **Fuzz Tests**: Use `cargo-fuzz` for fuzzing critical parsers

### Running Tests

```bash
# Run all tests
cargo test

# Run with coverage
cargo llvm-cov --html

# Run property tests
cargo test --features proptest

# Run integration tests
cargo test --test integration

# Run fuzz tests
cargo fuzz run codec_decode
```

### Test Requirements

- All new code must have tests
- Tests must be deterministic (use `testutil` helpers)
- Property tests for complex data structures
- Fuzz tests for parsers and codecs

## Documentation

### Code Documentation

- All public items must have doc comments
- Include examples for complex APIs
- Document panics, errors, and safety requirements
- Use `#[must_use]` where appropriate

### Architecture Documentation

- Update `docs/architecture.md` for structural changes
- Add protocol specs to `docs/protocol/` for new features
- Keep README quickstart up to date

## Pull Request Process

### Before Submitting

1. **Sync with upstream**: `git pull upstream main`
2. **Run full test suite**: `cargo test`
3. **Check formatting**: `cargo fmt --check`
4. **Run clippy**: `cargo clippy -- -D warnings`
5. **Update documentation** if needed

### PR Description Template

```markdown
## Summary
Brief description of changes

## Changes
- List of specific changes
- Each change on its own line

## Testing
- Description of tests added/modified
- Manual testing performed

## Documentation
- Documentation updated (if applicable)
- Breaking changes noted

## Checklist
- [ ] Tests pass locally
- [ ] Code formatted with `cargo fmt`
- [ ] No clippy warnings
- [ ] Documentation updated
- [ ] CHANGELOG updated (if applicable)
```

### Review Process

1. **Automated checks** must pass (CI)
2. **Code review** by maintainers
3. **Testing** on review branch
4. **Approval** and merge

## Architecture Guidelines

### Crate Design

Each crate should:
- Have a single, clear responsibility
- Minimize dependencies on other crates
- Provide stable public APIs
- Include comprehensive tests

### Error Handling

- Use `Result<T, E>` for fallible operations
- Create specific error types with `thiserror`
- Provide helpful error messages
- Don't panic in library code

### Async Programming

- Use `tokio` for async runtime
- Prefer `async`/`await` over futures combinators
- Use `tracing` for structured logging
- Handle cancellation properly

## Performance Considerations

- **Benchmarks**: Add benchmarks for performance-critical code
- **Profiling**: Use `cargo flamegraph` for profiling
- **Memory**: Avoid unnecessary allocations
- **Concurrency**: Design for concurrent access where appropriate

## Security Guidelines

- **Input Validation**: Validate all external inputs
- **Crypto**: Use established crypto libraries (k256, sha2)
- **Dependencies**: Regularly audit with `cargo audit`
- **Fuzzing**: Fuzz parsers and critical paths

## Release Process

### Version Numbering

We follow [Semantic Versioning](https://semver.org/):
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

### Release Checklist

1. Update version numbers in `Cargo.toml`
2. Update `CHANGELOG.md`
3. Run full test suite
4. Tag release: `git tag v0.1.0`
5. Push tag: `git push origin v0.1.0`
6. Create GitHub release

## Getting Help

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: Questions and community support
- **Code Review**: Ask questions in PR comments
- **Architecture**: Discuss in issues before major changes

## Code of Conduct

This project adheres to the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## License

By contributing to HorizCoin, you agree that your contributions will be licensed under both the MIT and Apache-2.0 licenses.