import type { RequestArguments, ProviderRequest, ProviderResponse } from '../types'

// EIP-1193 compatible provider for HorizCoin
export class HorizCoinProvider {
  private connected = false
  private accounts: string[] = []
  private chainId = '0x1337'
  private networkVersion = '4919'

  // Event listeners
  private listeners: Record<string, Function[]> = {}

  constructor() {
    this.setupMessageHandler()
  }

  // EIP-1193 request method
  async request(args: RequestArguments): Promise<unknown> {
    return new Promise((resolve, reject) => {
      const id = Date.now() + Math.random()
      
      const message: ProviderRequest = {
        ...args,
        id,
        origin: window.location.origin
      }

      // Listen for response
      const handleResponse = (event: MessageEvent) => {
        if (event.source !== window || event.data?.type !== 'HORIZCOIN_PROVIDER_RESPONSE') {
          return
        }

        const response = event.data.payload as ProviderResponse
        if (response.id !== id) {
          return
        }

        window.removeEventListener('message', handleResponse)

        if (response.error) {
          reject(new Error(response.error.message))
        } else {
          resolve(response.result)
        }
      }

      window.addEventListener('message', handleResponse)

      // Send request to content script
      window.postMessage({
        type: 'HORIZCOIN_PROVIDER_REQUEST',
        payload: message
      }, '*')

      // Timeout after 30 seconds
      setTimeout(() => {
        window.removeEventListener('message', handleResponse)
        reject(new Error('Request timeout'))
      }, 30000)
    })
  }

  // Legacy methods for compatibility
  async send(method: string, params?: unknown[]): Promise<unknown> {
    return this.request({ method, params })
  }

  async sendAsync(args: RequestArguments, callback: (error: Error | null, result?: unknown) => void): Promise<void> {
    try {
      const result = await this.request(args)
      callback(null, result)
    } catch (error) {
      callback(error as Error)
    }
  }

  // Event handling
  on(event: string, listener: Function): void {
    if (!this.listeners[event]) {
      this.listeners[event] = []
    }
    this.listeners[event].push(listener)
  }

  removeListener(event: string, listener: Function): void {
    if (this.listeners[event]) {
      const index = this.listeners[event].indexOf(listener)
      if (index > -1) {
        this.listeners[event].splice(index, 1)
      }
    }
  }

  emit(event: string, ...args: unknown[]): void {
    if (this.listeners[event]) {
      this.listeners[event].forEach(listener => listener(...args))
    }
  }

  // Setup message handler for provider events
  private setupMessageHandler(): void {
    window.addEventListener('message', (event) => {
      if (event.source !== window || !event.data?.type?.startsWith('HORIZCOIN_PROVIDER_')) {
        return
      }

      switch (event.data.type) {
        case 'HORIZCOIN_PROVIDER_CONNECT':
          this.handleConnect(event.data.payload)
          break
        case 'HORIZCOIN_PROVIDER_DISCONNECT':
          this.handleDisconnect()
          break
        case 'HORIZCOIN_PROVIDER_ACCOUNTS_CHANGED':
          this.handleAccountsChanged(event.data.payload)
          break
        case 'HORIZCOIN_PROVIDER_CHAIN_CHANGED':
          this.handleChainChanged(event.data.payload)
          break
      }
    })
  }

  private handleConnect(payload: { accounts: string[], chainId: string }): void {
    this.connected = true
    this.accounts = payload.accounts
    this.chainId = payload.chainId
    this.emit('connect', { chainId: this.chainId })
    this.emit('accountsChanged', this.accounts)
  }

  private handleDisconnect(): void {
    this.connected = false
    this.accounts = []
    this.emit('disconnect')
    this.emit('accountsChanged', [])
  }

  private handleAccountsChanged(accounts: string[]): void {
    this.accounts = accounts
    this.emit('accountsChanged', accounts)
  }

  private handleChainChanged(chainId: string): void {
    this.chainId = chainId
    this.networkVersion = parseInt(chainId, 16).toString()
    this.emit('chainChanged', chainId)
    this.emit('networkChanged', this.networkVersion)
  }

  // Getters for current state
  get isConnected(): boolean {
    return this.connected
  }

  get selectedAddress(): string | null {
    return this.accounts[0] || null
  }
}

// Provider method implementations
export const PROVIDER_METHODS = {
  // Account methods
  'eth_requestAccounts': 'requestAccounts',
  'hc_requestAccounts': 'requestAccounts',
  'eth_accounts': 'getAccounts',
  'hc_accounts': 'getAccounts',

  // Network methods
  'eth_chainId': 'getChainId',
  'hc_chainId': 'getChainId',
  'net_version': 'getNetworkVersion',
  'hc_networkVersion': 'getNetworkVersion',

  // Signing methods
  'personal_sign': 'personalSign',
  'hc_signMessage': 'signMessage',
  'eth_sign': 'ethSign',
  'hc_sign': 'sign',

  // Transaction methods
  'eth_sendTransaction': 'sendTransaction',
  'hc_sendTransaction': 'sendTransaction',
  'eth_signTransaction': 'signTransaction',
  'hc_signTransaction': 'signTransaction',

  // Utility methods
  'web3_clientVersion': 'getClientVersion',
  'hc_clientVersion': 'getClientVersion'
} as const

export type ProviderMethod = keyof typeof PROVIDER_METHODS