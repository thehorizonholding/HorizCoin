import type { Network } from '../types'

export const DEFAULT_NETWORKS: Network[] = [
  {
    chainId: '0x1337', // 4919 in decimal
    name: 'HorizCoin Devnet',
    rpcUrls: ['http://localhost:8545'],
    nativeCurrency: {
      name: 'HorizCoin',
      symbol: 'HRZ',
      decimals: 18
    },
    blockExplorerUrls: ['http://localhost:8080/explorer']
  },
  {
    chainId: '0x7a69', // 31337 in decimal - common for local hardhat/anvil
    name: 'HorizCoin Local',
    rpcUrls: ['http://localhost:8545', 'http://127.0.0.1:8545'],
    nativeCurrency: {
      name: 'HorizCoin',
      symbol: 'HRZ',
      decimals: 18
    }
  }
]

export class NetworkManager {
  private networks: Network[] = [...DEFAULT_NETWORKS]
  private currentNetwork: Network = DEFAULT_NETWORKS[0]

  getNetworks(): Network[] {
    return [...this.networks]
  }

  getCurrentNetwork(): Network {
    return this.currentNetwork
  }

  setCurrentNetwork(chainId: string): boolean {
    const network = this.networks.find(n => n.chainId === chainId)
    if (network) {
      this.currentNetwork = network
      return true
    }
    return false
  }

  addNetwork(network: Network): void {
    const existingIndex = this.networks.findIndex(n => n.chainId === network.chainId)
    if (existingIndex >= 0) {
      this.networks[existingIndex] = network
    } else {
      this.networks.push(network)
    }
  }

  removeNetwork(chainId: string): boolean {
    if (this.networks.length <= 1) {
      return false // Cannot remove last network
    }
    
    const index = this.networks.findIndex(n => n.chainId === chainId)
    if (index >= 0) {
      this.networks.splice(index, 1)
      
      // If we removed the current network, switch to the first one
      if (this.currentNetwork.chainId === chainId) {
        this.currentNetwork = this.networks[0]
      }
      return true
    }
    return false
  }

  validateNetwork(network: Partial<Network>): string[] {
    const errors: string[] = []
    
    if (!network.chainId) {
      errors.push('Chain ID is required')
    } else if (!/^0x[0-9a-fA-F]+$/.test(network.chainId)) {
      errors.push('Chain ID must be a valid hex string (e.g., 0x1)')
    }
    
    if (!network.name?.trim()) {
      errors.push('Network name is required')
    }
    
    if (!network.rpcUrls?.length) {
      errors.push('At least one RPC URL is required')
    } else {
      for (const url of network.rpcUrls) {
        try {
          new URL(url)
        } catch {
          errors.push(`Invalid RPC URL: ${url}`)
        }
      }
    }
    
    if (!network.nativeCurrency) {
      errors.push('Native currency is required')
    } else {
      if (!network.nativeCurrency.name?.trim()) {
        errors.push('Currency name is required')
      }
      if (!network.nativeCurrency.symbol?.trim()) {
        errors.push('Currency symbol is required')
      }
      if (typeof network.nativeCurrency.decimals !== 'number' || 
          network.nativeCurrency.decimals < 0 || 
          network.nativeCurrency.decimals > 18) {
        errors.push('Currency decimals must be a number between 0 and 18')
      }
    }
    
    return errors
  }
}