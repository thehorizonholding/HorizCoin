# HorizCoin Wallet Architecture

## Overview

The HorizCoin Wallet is a browser extension that provides secure key management and dApp integration for the HorizCoin blockchain. It follows a security-first architecture with local key storage and EIP-1193 compatible provider interface.

## Architecture Components

### 1. Browser Extension Structure

```
packages/wallet-extension/
├── src/
│   ├── background/          # Service worker
│   ├── content/            # Content script for provider injection
│   ├── popup/              # Extension popup UI
│   ├── options/            # Settings page
│   ├── shared/             # Shared utilities
│   │   ├── crypto/         # Cryptographic functions
│   │   ├── storage/        # Secure vault management
│   │   ├── networks/       # Network configuration
│   │   ├── provider/       # Provider interface
│   │   └── types/          # TypeScript definitions
│   ├── provider.js         # Injected provider script
│   └── manifest.json       # Extension manifest
└── dist/                   # Built extension
```

### 2. Security Model

#### Key Storage
- **Local Storage Only**: Private keys never leave the device
- **Encryption**: PBKDF2 + AES-GCM encryption for vault data
- **Password Protection**: User password required for all key operations
- **Auto-lock**: Configurable auto-lock timer for security

#### Vault Structure
```typescript
interface EncryptedVault {
  encrypted: string    // AES-GCM encrypted vault data
  salt: string        // PBKDF2 salt (32 bytes)
  iv: string          // AES-GCM initialization vector (12 bytes)
}

interface VaultData {
  mnemonic: string    // BIP39 mnemonic phrase
  accounts: Account[] // Derived accounts with private keys
}
```

#### Cryptographic Primitives
- **Hashing**: SHA-256 throughout
- **Signatures**: secp256k1 via @noble/secp256k1
- **Key Derivation**: BIP39 + BIP44-like derivation
- **Addresses**: Simple hex format (future: bech32m)

### 3. Provider Integration

#### EIP-1193 Compatibility
The wallet provides both HorizCoin-specific and Ethereum-compatible methods:

```javascript
// HorizCoin methods
window.horizcoin.request({ method: 'hc_requestAccounts' })
window.horizcoin.request({ method: 'hc_signMessage', params: [message, address] })

// Ethereum compatibility
window.ethereum.request({ method: 'eth_requestAccounts' })
window.ethereum.request({ method: 'personal_sign', params: [message, address] })
```

#### Supported Methods

| Method | HorizCoin | Ethereum | Description |
|--------|-----------|----------|-------------|
| Request Accounts | `hc_requestAccounts` | `eth_requestAccounts` | Connect wallet |
| Get Accounts | `hc_accounts` | `eth_accounts` | Get connected accounts |
| Chain ID | `hc_chainId` | `eth_chainId` | Get current network |
| Sign Message | `hc_signMessage` | `personal_sign` | Sign arbitrary message |
| Send Transaction | `hc_sendTransaction` | `eth_sendTransaction` | Send transaction |

### 4. Network Management

#### Default Networks
- **HorizCoin Devnet**: Local development network
- **HorizCoin Local**: Localhost testing network

#### Network Configuration
```typescript
interface Network {
  chainId: string           // Hex chain identifier
  name: string             // Human-readable name
  rpcUrls: string[]        // RPC endpoints
  nativeCurrency: {
    name: string
    symbol: string
    decimals: number
  }
  blockExplorerUrls?: string[]
}
```

### 5. Permission Model

#### Site Connections
- **Explicit Approval**: Users must approve each site connection
- **Origin-based**: Permissions stored per origin
- **Revocable**: Users can disconnect sites at any time

#### Security Boundaries
- Content scripts isolated from page context
- Background script handles all sensitive operations
- Popup/options pages for user interactions

## Message Flow

### Provider Request Flow
1. dApp calls `window.horizcoin.request()`
2. Provider script receives request
3. Content script forwards to background
4. Background script processes request
5. Response sent back through content script
6. Provider script resolves promise

### Connection Flow
1. dApp requests accounts
2. Extension opens approval popup
3. User approves/rejects connection
4. Background script stores permission
5. Accounts returned to dApp

## Security Considerations

### Threat Model
- **Malicious dApps**: Sandboxed provider prevents unauthorized access
- **Phishing**: Address verification and clear transaction details
- **Key Extraction**: Encrypted storage with device-only access
- **Man-in-the-middle**: HTTPS enforcement for sensitive operations

### Best Practices
- Regular password prompts for sensitive operations
- Clear transaction details before signing
- Origin verification for all requests
- Auto-lock on inactivity

## Development Guidelines

### Building the Extension
```bash
cd packages/wallet-extension
npm install
npm run build
```

### Loading in Browser
1. Open Chrome/Edge extension management
2. Enable "Developer mode"
3. Click "Load unpacked"
4. Select the `dist/` folder

### Testing with dApp
1. Load extension in browser
2. Open `examples/dapp/index.html`
3. Test connection and provider methods

### Code Organization
- **Shared utilities**: Reusable across all contexts
- **Type safety**: Full TypeScript coverage
- **Minimal dependencies**: Only essential crypto libraries
- **Clear separation**: UI, business logic, and crypto isolated

## Future Considerations

### Protocol Evolution
- Ready for custom HorizCoin JSON-RPC methods
- Abstracted crypto layer for algorithm changes
- Network configuration for mainnet deployment

### UX Improvements
- Hardware wallet integration
- Multi-account management
- Transaction history
- Advanced security features

### Scaling
- Multiple network support
- Cross-chain compatibility
- Enhanced developer tools