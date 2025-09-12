// Provider script injected into web pages
(function() {
  'use strict'

  // Check if provider is already injected
  if (window.horizcoin || window.ethereum?.isHorizCoin) {
    return
  }

  class HorizCoinProvider {
    constructor() {
      this.isHorizCoin = true
      this.connected = false
      this.accounts = []
      this.chainId = '0x1337'
      this.networkVersion = '4919'
      this.listeners = {}
    }

    // EIP-1193 request method
    async request(args) {
      return new Promise((resolve, reject) => {
        const id = Date.now() + Math.random()
        
        const message = {
          ...args,
          id,
          origin: window.location.origin
        }

        // Listen for response
        const handleResponse = (event) => {
          if (event.source !== window || event.data?.type !== 'HORIZCOIN_PROVIDER_RESPONSE') {
            return
          }

          const response = event.data.payload
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
    async send(method, params) {
      return this.request({ method, params })
    }

    async sendAsync(args, callback) {
      try {
        const result = await this.request(args)
        callback(null, result)
      } catch (error) {
        callback(error)
      }
    }

    // Event handling
    on(event, listener) {
      if (!this.listeners[event]) {
        this.listeners[event] = []
      }
      this.listeners[event].push(listener)
    }

    removeListener(event, listener) {
      if (this.listeners[event]) {
        const index = this.listeners[event].indexOf(listener)
        if (index > -1) {
          this.listeners[event].splice(index, 1)
        }
      }
    }

    emit(event, ...args) {
      if (this.listeners[event]) {
        this.listeners[event].forEach(listener => listener(...args))
      }
    }

    // Getters for current state
    get isConnected() {
      return this.connected
    }

    get selectedAddress() {
      return this.accounts[0] || null
    }
  }

  // Create provider instance
  const provider = new HorizCoinProvider()

  // Setup message handler for provider events
  window.addEventListener('message', (event) => {
    if (event.source !== window || !event.data?.type?.startsWith('HORIZCOIN_PROVIDER_')) {
      return
    }

    switch (event.data.type) {
      case 'HORIZCOIN_PROVIDER_CONNECT':
        provider.connected = true
        provider.accounts = event.data.payload.accounts
        provider.chainId = event.data.payload.chainId
        provider.emit('connect', { chainId: provider.chainId })
        provider.emit('accountsChanged', provider.accounts)
        break
      case 'HORIZCOIN_PROVIDER_DISCONNECT':
        provider.connected = false
        provider.accounts = []
        provider.emit('disconnect')
        provider.emit('accountsChanged', [])
        break
      case 'HORIZCOIN_PROVIDER_ACCOUNTS_CHANGED':
        provider.accounts = event.data.payload
        provider.emit('accountsChanged', event.data.payload)
        break
      case 'HORIZCOIN_PROVIDER_CHAIN_CHANGED':
        provider.chainId = event.data.payload
        provider.networkVersion = parseInt(event.data.payload, 16).toString()
        provider.emit('chainChanged', event.data.payload)
        provider.emit('networkChanged', provider.networkVersion)
        break
    }
  })

  // Expose provider
  window.horizcoin = provider
  
  // Also expose as ethereum for compatibility (but mark as HorizCoin)
  if (!window.ethereum) {
    window.ethereum = provider
  }

  // Announce provider
  window.dispatchEvent(new Event('horizcoin#initialized'))
  window.dispatchEvent(new Event('ethereum#initialized'))
})();