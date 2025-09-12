// Core types for the HorizCoin wallet extension

export interface Account {
  id: string
  name: string
  address: string
  publicKey: string
  // privateKey is stored encrypted in vault
}

export interface Network {
  chainId: string
  name: string
  rpcUrls: string[]
  nativeCurrency: {
    name: string
    symbol: string
    decimals: number
  }
  blockExplorerUrls?: string[]
}

export interface WalletState {
  isLocked: boolean
  currentAccount?: Account
  accounts: Account[]
  currentNetwork: Network
  networks: Network[]
  connectedSites: Record<string, boolean> // origin -> connected
}

export interface EncryptedVault {
  encrypted: string
  salt: string
  iv: string
}

export interface VaultData {
  mnemonic: string
  accounts: Array<{
    id: string
    name: string
    privateKey: string
    publicKey: string
    address: string
    derivationPath: string
  }>
}

// Provider types (EIP-1193 compatible)
export interface RequestArguments {
  method: string
  params?: unknown[] | Record<string, unknown>
}

export interface ProviderMessage {
  type: string
  data: unknown
}

export interface ProviderRequest extends RequestArguments {
  id: string | number
  origin: string
}

export interface ProviderResponse {
  id: string | number
  result?: unknown
  error?: {
    code: number
    message: string
    data?: unknown
  }
}

// Extension message types
export interface ExtensionMessage {
  type: string
  payload?: unknown
  id?: string | number
}

export type ExtensionResponse<T = unknown> = {
  success: boolean
  data?: T
  error?: string
}