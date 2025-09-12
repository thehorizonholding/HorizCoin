// Background service worker for wallet extension

import type { ProviderRequest, ProviderResponse, WalletState, Account, Network } from '../shared/types'
import { SecureVault } from '../shared/storage'
import { NetworkManager, DEFAULT_NETWORKS } from '../shared/networks'
import { PROVIDER_METHODS } from '../shared/provider'

class WalletBackground {
  private walletState: WalletState = {
    isLocked: true,
    accounts: [],
    currentNetwork: DEFAULT_NETWORKS[0],
    networks: DEFAULT_NETWORKS,
    connectedSites: {}
  }

  private networkManager = new NetworkManager()
  private lockTimer: number | null = null
  private readonly AUTO_LOCK_MINUTES = 30

  constructor() {
    this.setupMessageHandlers()
    this.setupAutoLock()
  }

  private setupMessageHandlers(): void {
    chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
      this.handleMessage(message, sender)
        .then(sendResponse)
        .catch(error => {
          console.error('Background script error:', error)
          sendResponse({ 
            success: false, 
            error: error.message || 'Unknown error' 
          })
        })
      
      return true // Keep message channel open for async response
    })
  }

  private async handleMessage(message: any, sender: chrome.runtime.MessageSender): Promise<any> {
    switch (message.type) {
      case 'PROVIDER_REQUEST':
        return this.handleProviderRequest(message.payload, sender)
      case 'UNLOCK_WALLET':
        return this.unlockWallet(message.payload.password)
      case 'LOCK_WALLET':
        return this.lockWallet()
      case 'CREATE_WALLET':
        return this.createWallet(message.payload.password, message.payload.mnemonic)
      case 'IMPORT_WALLET':
        return this.importWallet(message.payload.password, message.payload.mnemonic)
      case 'GET_STATE':
        return this.getWalletState()
      case 'ADD_NETWORK':
        return this.addNetwork(message.payload.network)
      case 'SWITCH_NETWORK':
        return this.switchNetwork(message.payload.chainId)
      case 'CONNECT_SITE':
        return this.connectSite(message.payload.origin)
      case 'DISCONNECT_SITE':
        return this.disconnectSite(message.payload.origin)
      default:
        throw new Error(`Unknown message type: ${message.type}`)
    }
  }

  private async handleProviderRequest(request: ProviderRequest, _sender: chrome.runtime.MessageSender): Promise<ProviderResponse> {
    const { method, params, id, origin } = request

    // Check if method is supported
    if (!PROVIDER_METHODS[method as keyof typeof PROVIDER_METHODS]) {
      return {
        id,
        error: {
          code: -32601,
          message: `Method not found: ${method}`
        }
      }
    }

    try {
      let result: unknown

      switch (method) {
        case 'eth_requestAccounts':
        case 'hc_requestAccounts':
          result = await this.requestAccounts(origin)
          break
        case 'eth_accounts':
        case 'hc_accounts':
          result = this.getAccounts(origin)
          break
        case 'eth_chainId':
        case 'hc_chainId':
          result = this.walletState.currentNetwork.chainId
          break
        case 'net_version':
        case 'hc_networkVersion':
          result = parseInt(this.walletState.currentNetwork.chainId, 16).toString()
          break
        case 'personal_sign':
        case 'hc_signMessage':
          result = await this.signMessage(params as [string, string], origin)
          break
        case 'eth_sendTransaction':
        case 'hc_sendTransaction':
          result = await this.sendTransaction(params as [any], origin)
          break
        case 'web3_clientVersion':
        case 'hc_clientVersion':
          result = 'HorizCoin-Wallet/0.1.0'
          break
        default:
          throw new Error(`Unsupported method: ${method}`)
      }

      return { id, result }
    } catch (error) {
      return {
        id,
        error: {
          code: -32603,
          message: error instanceof Error ? error.message : 'Internal error'
        }
      }
    }
  }

  private async requestAccounts(origin: string): Promise<string[]> {
    if (this.walletState.isLocked) {
      throw new Error('Wallet is locked')
    }

    // Check if site is already connected
    if (this.walletState.connectedSites[origin]) {
      return this.getAccounts(origin)
    }

    // Open popup for connection approval
    await this.openPopup('connect', { origin })
    
    // This would normally wait for user approval
    // For now, auto-approve localhost
    if (origin.includes('localhost') || origin.includes('127.0.0.1')) {
      await this.connectSite(origin)
      return this.getAccounts(origin)
    }

    throw new Error('User rejected connection')
  }

  private getAccounts(origin: string): string[] {
    if (!this.walletState.connectedSites[origin] || this.walletState.isLocked) {
      return []
    }
    
    return this.walletState.currentAccount ? [this.walletState.currentAccount.address] : []
  }

  private async signMessage(params: [string, string], origin: string): Promise<string> {
    if (this.walletState.isLocked) {
      throw new Error('Wallet is locked')
    }

    if (!this.walletState.connectedSites[origin]) {
      throw new Error('Site not connected')
    }

    const [_message, address] = params
    
    if (!this.walletState.currentAccount || this.walletState.currentAccount.address !== address) {
      throw new Error('Account not found')
    }

    // Get private key from vault
    const vault = await SecureVault.loadVault()
    if (!vault) {
      throw new Error('No vault found')
    }

    // For now, we'd need to prompt for password again for security
    // This is a simplified implementation
    throw new Error('Sign message not implemented - requires password prompt')
  }

  private async sendTransaction(_params: [any], origin: string): Promise<string> {
    if (this.walletState.isLocked) {
      throw new Error('Wallet is locked')
    }

    if (!this.walletState.connectedSites[origin]) {
      throw new Error('Site not connected')
    }

    // This is a mock implementation
    // In reality, this would validate the transaction, show confirmation popup, etc.
    const txHash = '0x' + Array.from(crypto.getRandomValues(new Uint8Array(32)), 
      b => b.toString(16).padStart(2, '0')).join('')
    
    return txHash
  }

  private async createWallet(password: string, mnemonic?: string): Promise<{ success: boolean; account?: Account }> {
    const { account } = await SecureVault.createVault(password, mnemonic)
    
    this.walletState = {
      isLocked: false,
      currentAccount: account,
      accounts: [account],
      currentNetwork: DEFAULT_NETWORKS[0],
      networks: DEFAULT_NETWORKS,
      connectedSites: {}
    }

    this.resetAutoLock()
    
    return { success: true, account }
  }

  private async importWallet(password: string, mnemonic: string): Promise<{ success: boolean; account?: Account }> {
    return this.createWallet(password, mnemonic)
  }

  private async unlockWallet(password: string): Promise<{ success: boolean; state?: WalletState; error?: string }> {
    try {
      const vaultData = await SecureVault.unlockVault(password)
      
      // Convert vault accounts to UI accounts
      const accounts: Account[] = vaultData.accounts.map(acc => ({
        id: acc.id,
        name: acc.name,
        address: acc.address,
        publicKey: acc.publicKey
      }))

      this.walletState = {
        isLocked: false,
        currentAccount: accounts[0],
        accounts,
        currentNetwork: this.networkManager.getCurrentNetwork(),
        networks: this.networkManager.getNetworks(),
        connectedSites: {} // Could be persisted
      }

      this.resetAutoLock()
      
      return { success: true, state: this.walletState }
    } catch (error) {
      return { success: false, error: error instanceof Error ? error.message : 'Invalid password' }
    }
  }

  private async lockWallet(): Promise<{ success: boolean }> {
    this.walletState.isLocked = true
    this.walletState.currentAccount = undefined
    this.clearAutoLock()
    
    // Notify all connected sites
    this.broadcastToConnectedSites('PROVIDER_EVENT_DISCONNECT', null)
    
    return { success: true }
  }

  private getWalletState(): WalletState {
    return { ...this.walletState }
  }

  private async connectSite(origin: string): Promise<{ success: boolean }> {
    this.walletState.connectedSites[origin] = true
    
    // Notify site of connection
    this.broadcastToSite(origin, 'PROVIDER_EVENT_CONNECT', {
      accounts: this.getAccounts(origin),
      chainId: this.walletState.currentNetwork.chainId
    })
    
    return { success: true }
  }

  private async disconnectSite(origin: string): Promise<{ success: boolean }> {
    delete this.walletState.connectedSites[origin]
    
    // Notify site of disconnection
    this.broadcastToSite(origin, 'PROVIDER_EVENT_DISCONNECT', null)
    
    return { success: true }
  }

  private async addNetwork(network: Network): Promise<{ success: boolean; errors?: string[] }> {
    const errors = this.networkManager.validateNetwork(network)
    if (errors.length > 0) {
      return { success: false, errors }
    }
    
    this.networkManager.addNetwork(network)
    this.walletState.networks = this.networkManager.getNetworks()
    
    return { success: true }
  }

  private async switchNetwork(chainId: string): Promise<{ success: boolean }> {
    const success = this.networkManager.setCurrentNetwork(chainId)
    if (success) {
      this.walletState.currentNetwork = this.networkManager.getCurrentNetwork()
      
      // Notify all connected sites
      this.broadcastToConnectedSites('PROVIDER_EVENT_CHAIN_CHANGED', chainId)
    }
    
    return { success }
  }

  private async openPopup(page: string, _data?: any): Promise<void> {
    const url = chrome.runtime.getURL(`popup.html#${page}`)
    await chrome.windows.create({
      url,
      type: 'popup',
      width: 400,
      height: 600
    })
  }

  private setupAutoLock(): void {
    this.resetAutoLock()
  }

  private resetAutoLock(): void {
    this.clearAutoLock()
    this.lockTimer = window.setTimeout(() => {
      this.lockWallet()
    }, this.AUTO_LOCK_MINUTES * 60 * 1000)
  }

  private clearAutoLock(): void {
    if (this.lockTimer) {
      clearTimeout(this.lockTimer)
      this.lockTimer = null
    }
  }

  private broadcastToConnectedSites(type: string, payload: any): void {
    Object.keys(this.walletState.connectedSites).forEach(origin => {
      this.broadcastToSite(origin, type, payload)
    })
  }

  private async broadcastToSite(origin: string, type: string, payload: any): Promise<void> {
    try {
      const tabs = await chrome.tabs.query({ url: `${origin}/*` })
      tabs.forEach(tab => {
        if (tab.id) {
          chrome.tabs.sendMessage(tab.id, { type, payload })
        }
      })
    } catch (error) {
      console.warn('Failed to broadcast to site:', origin, error)
    }
  }
}

// Initialize background script
new WalletBackground()