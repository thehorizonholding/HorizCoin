// Tests for network management
import { describe, it, expect, beforeEach } from 'vitest'
import { NetworkManager, DEFAULT_NETWORKS } from '../shared/networks'

describe('NetworkManager', () => {
  let networkManager: NetworkManager

  beforeEach(() => {
    networkManager = new NetworkManager()
  })

  it('should start with default networks', () => {
    const networks = networkManager.getNetworks()
    expect(networks).toHaveLength(DEFAULT_NETWORKS.length)
    expect(networks[0]).toEqual(DEFAULT_NETWORKS[0])
  })

  it('should set current network correctly', () => {
    const chainId = DEFAULT_NETWORKS[1].chainId
    const success = networkManager.setCurrentNetwork(chainId)
    
    expect(success).toBe(true)
    expect(networkManager.getCurrentNetwork().chainId).toBe(chainId)
  })

  it('should fail to set non-existent network', () => {
    const success = networkManager.setCurrentNetwork('0x999')
    expect(success).toBe(false)
  })

  it('should add new network', () => {
    const newNetwork = {
      chainId: '0x1',
      name: 'Test Network',
      rpcUrls: ['https://test.rpc'],
      nativeCurrency: {
        name: 'Test Token',
        symbol: 'TEST',
        decimals: 18
      }
    }

    networkManager.addNetwork(newNetwork)
    const networks = networkManager.getNetworks()
    
    expect(networks).toContain(newNetwork)
  })

  it('should validate network correctly', () => {
    const validNetwork = {
      chainId: '0x1',
      name: 'Valid Network',
      rpcUrls: ['https://valid.rpc'],
      nativeCurrency: {
        name: 'Valid Token',
        symbol: 'VALID',
        decimals: 18
      }
    }

    const invalidNetwork = {
      chainId: 'invalid',
      name: '',
      rpcUrls: [],
      nativeCurrency: {
        name: '',
        symbol: '',
        decimals: -1
      }
    }

    expect(networkManager.validateNetwork(validNetwork)).toHaveLength(0)
    expect(networkManager.validateNetwork(invalidNetwork).length).toBeGreaterThan(0)
  })

  it('should not remove last network', () => {
    // Remove all networks except one
    const networks = networkManager.getNetworks()
    for (let i = 1; i < networks.length; i++) {
      networkManager.removeNetwork(networks[i].chainId)
    }

    // Try to remove the last network
    const success = networkManager.removeNetwork(networks[0].chainId)
    expect(success).toBe(false)
    expect(networkManager.getNetworks()).toHaveLength(1)
  })
})