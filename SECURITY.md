# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

The HorizCoin team takes security bugs seriously. We appreciate your efforts to responsibly disclose your findings, and will make every effort to acknowledge your contributions.

### Reporting Process

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report them via email to: **security@horizonholding.com**

Include the following information in your report:

- **Description**: A clear description of the vulnerability
- **Impact**: Potential impact and attack scenarios
- **Reproduction**: Step-by-step instructions to reproduce the issue
- **Environment**: Version, operating system, and configuration details
- **Suggested Fix**: If you have ideas for how to address the issue

### What to Expect

1. **Acknowledgment**: We will acknowledge receipt of your report within 48 hours
2. **Initial Assessment**: We will provide an initial assessment within 7 days
3. **Progress Updates**: We will keep you informed of our progress
4. **Resolution**: We will notify you when the issue is resolved
5. **Public Disclosure**: We will coordinate with you on public disclosure timing

### Scope

This security policy applies to:

- The HorizCoin node software (`horizd`)
- The HorizCoin CLI wallet (`horiz-cli`)
- Core libraries and cryptographic implementations
- Network protocol implementations
- RPC interfaces

### Security Considerations

#### Cryptographic Security

- **Key Management**: Private keys should never be logged or transmitted
- **Randomness**: All cryptographic operations use cryptographically secure randomness
- **Signature Verification**: All signatures are properly validated
- **Hash Functions**: We use SHA-256 for all hashing operations

#### Network Security

- **P2P Protocol**: Implements anti-DoS protections and peer scoring
- **RPC Interface**: Runs on localhost by default, authentication required for remote access
- **Input Validation**: All network inputs are validated and bounded
- **Rate Limiting**: Peer connections and RPC requests are rate-limited

#### Node Security

- **File Permissions**: Database and key files use restrictive permissions
- **Resource Limits**: Memory and disk usage are bounded
- **Error Handling**: No sensitive information leaked in error messages
- **Graceful Shutdown**: Node handles shutdown signals properly

#### Wallet Security

- **Key Storage**: Private keys are encrypted at rest
- **Mnemonic Seeds**: BIP39 mnemonic generation and validation
- **Transaction Signing**: Transactions are signed locally, never transmitted
- **Address Validation**: All addresses are validated before use

### Known Security Considerations

#### Development Consensus

The initial implementation uses a development consensus mechanism (DevConsensus) that is:
- **Not production-ready**: Single-sealer PoA is not suitable for mainnet
- **For testing only**: Should only be used in controlled environments
- **Centralized**: Single point of failure for block production

#### Alpha Software

This is alpha software with the following limitations:
- **No formal security audit**: Code has not been professionally audited
- **Rapid development**: APIs and protocols may change
- **Limited testing**: May contain undiscovered vulnerabilities
- **Experimental features**: Some features are experimental and unproven

### Best Practices for Users

#### Node Operators

- **Firewall**: Run behind a firewall, expose only necessary ports
- **Updates**: Keep software updated with latest security patches
- **Monitoring**: Monitor for unusual network activity or resource usage
- **Backups**: Maintain secure backups of blockchain data and configuration

#### Wallet Users

- **Key Security**: Store private keys and mnemonic seeds securely
- **Verification**: Always verify transaction details before signing
- **Software**: Only use official releases from trusted sources
- **Environment**: Use wallet software on secure, up-to-date systems

### Vulnerability Disclosure Timeline

We follow responsible disclosure practices:

1. **T+0**: Vulnerability reported
2. **T+48h**: Acknowledgment sent
3. **T+7d**: Initial assessment provided
4. **T+30d**: Target for fix development (may extend for complex issues)
5. **T+90d**: Public disclosure (may extend by mutual agreement)

### Bounty Program

We are considering a bug bounty program for the future. Currently, we do not offer monetary rewards, but we will:

- Acknowledge security researchers in our security advisories
- Provide credit in release notes for responsible disclosure
- Consider contributors for future bounty programs

### Contact Information

- **Security Email**: security@horizonholding.com
- **PGP Key**: Available on request
- **Response Time**: We aim to respond within 48 hours

### Acknowledgments

We thank the security research community for helping to keep HorizCoin and its users safe. Responsible disclosure helps protect the entire ecosystem.

---

This security policy is subject to change as the project evolves. Please check back regularly for updates.