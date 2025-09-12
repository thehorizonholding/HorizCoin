// HorizCoin dApp Example
class HorizCoinDApp {
    constructor() {
        this.provider = null
        this.currentAccount = null
        this.isConnected = false
        
        this.init()
    }

    init() {
        this.detectProvider()
        this.setupEventListeners()
        this.setupProviderEvents()
        this.updateUI()
    }

    detectProvider() {
        this.log('Detecting HorizCoin provider...')
        
        // Check for HorizCoin provider
        if (window.horizcoin) {
            this.provider = window.horizcoin
            this.log('✅ HorizCoin provider detected')
            document.getElementById('horizcoinStatus').textContent = '✅'
        } else {
            this.log('❌ HorizCoin provider not found')
        }

        // Check for Ethereum provider (compatibility)
        if (window.ethereum) {
            this.log('✅ Ethereum provider detected')
            document.getElementById('ethereumStatus').textContent = '✅'
            
            if (window.ethereum.isHorizCoin) {
                this.log('✅ HorizCoin extension confirmed')
                document.getElementById('extensionStatus').textContent = '✅'
                if (!this.provider) this.provider = window.ethereum
            }
        }

        if (!this.provider) {
            this.log('❌ No compatible wallet provider found')
            this.log('Please install the HorizCoin wallet extension')
        }
    }

    setupEventListeners() {
        // Connection buttons
        document.getElementById('connectBtn').addEventListener('click', () => this.connect())
        document.getElementById('disconnectBtn').addEventListener('click', () => this.disconnect())
        
        // Info buttons
        document.getElementById('getAccountsBtn').addEventListener('click', () => this.getAccounts())
        document.getElementById('getChainIdBtn').addEventListener('click', () => this.getChainId())
        
        // Signing
        document.getElementById('signMessageBtn').addEventListener('click', () => this.signMessage())
        
        // Transactions
        document.getElementById('sendTxBtn').addEventListener('click', () => this.sendTransaction())
        
        // Utility
        document.getElementById('clearLogBtn').addEventListener('click', () => this.clearLog())
    }

    setupProviderEvents() {
        if (!this.provider) return

        this.provider.on('connect', (connectInfo) => {
            this.log(`🔗 Connected to chain ${connectInfo.chainId}`)
            this.isConnected = true
            this.updateUI()
        })

        this.provider.on('disconnect', (error) => {
            this.log('🔌 Disconnected from wallet', error)
            this.isConnected = false
            this.currentAccount = null
            this.updateUI()
        })

        this.provider.on('accountsChanged', (accounts) => {
            this.log('👤 Accounts changed:', accounts)
            this.currentAccount = accounts[0] || null
            this.updateUI()
        })

        this.provider.on('chainChanged', (chainId) => {
            this.log(`🔄 Chain changed to ${chainId}`)
            this.updateUI()
        })
    }

    async connect() {
        if (!this.provider) {
            this.log('❌ No provider available')
            return
        }

        try {
            this.log('🔄 Requesting account access...')
            
            // Try HorizCoin-specific method first
            let accounts
            try {
                accounts = await this.provider.request({ method: 'hc_requestAccounts' })
            } catch (error) {
                // Fallback to standard Ethereum method
                this.log('Falling back to eth_requestAccounts')
                accounts = await this.provider.request({ method: 'eth_requestAccounts' })
            }

            if (accounts && accounts.length > 0) {
                this.currentAccount = accounts[0]
                this.isConnected = true
                this.log('✅ Connected successfully')
                this.log(`Account: ${this.currentAccount}`)
            } else {
                this.log('❌ No accounts returned')
            }
        } catch (error) {
            this.log('❌ Connection failed:', error.message)
        }

        this.updateUI()
    }

    async disconnect() {
        this.isConnected = false
        this.currentAccount = null
        this.log('🔌 Disconnected locally')
        this.updateUI()
    }

    async getAccounts() {
        if (!this.provider) {
            this.log('❌ No provider available')
            return
        }

        try {
            let accounts
            try {
                accounts = await this.provider.request({ method: 'hc_accounts' })
            } catch (error) {
                accounts = await this.provider.request({ method: 'eth_accounts' })
            }
            
            this.log('📋 Accounts:', accounts)
            return accounts
        } catch (error) {
            this.log('❌ Failed to get accounts:', error.message)
        }
    }

    async getChainId() {
        if (!this.provider) {
            this.log('❌ No provider available')
            return
        }

        try {
            let chainId
            try {
                chainId = await this.provider.request({ method: 'hc_chainId' })
            } catch (error) {
                chainId = await this.provider.request({ method: 'eth_chainId' })
            }
            
            const decimalChainId = parseInt(chainId, 16)
            this.log(`🔗 Chain ID: ${chainId} (${decimalChainId})`)
            return chainId
        } catch (error) {
            this.log('❌ Failed to get chain ID:', error.message)
        }
    }

    async signMessage() {
        if (!this.provider || !this.currentAccount) {
            this.log('❌ Not connected')
            return
        }

        const message = document.getElementById('messageInput').value
        if (!message) {
            this.log('❌ Please enter a message')
            return
        }

        try {
            this.log(`🖋️ Signing message: "${message}"`)
            
            let signature
            try {
                signature = await this.provider.request({
                    method: 'hc_signMessage',
                    params: [message, this.currentAccount]
                })
            } catch (error) {
                signature = await this.provider.request({
                    method: 'personal_sign',
                    params: [message, this.currentAccount]
                })
            }
            
            this.log('✅ Message signed successfully')
            this.log(`Signature: ${signature}`)
            return signature
        } catch (error) {
            this.log('❌ Failed to sign message:', error.message)
        }
    }

    async sendTransaction() {
        if (!this.provider || !this.currentAccount) {
            this.log('❌ Not connected')
            return
        }

        const toAddress = document.getElementById('toAddress').value
        const amount = document.getElementById('amount').value

        if (!toAddress || !amount) {
            this.log('❌ Please enter recipient address and amount')
            return
        }

        try {
            const tx = {
                from: this.currentAccount,
                to: toAddress,
                value: this.toHex(parseFloat(amount) * 1e18) // Convert to wei
            }

            this.log('💸 Sending transaction:', tx)

            let txHash
            try {
                txHash = await this.provider.request({
                    method: 'hc_sendTransaction',
                    params: [tx]
                })
            } catch (error) {
                txHash = await this.provider.request({
                    method: 'eth_sendTransaction',
                    params: [tx]
                })
            }

            this.log('✅ Transaction sent successfully')
            this.log(`Transaction hash: ${txHash}`)
            return txHash
        } catch (error) {
            this.log('❌ Failed to send transaction:', error.message)
        }
    }

    updateUI() {
        // Update connection status
        const statusIndicator = document.getElementById('statusIndicator')
        const statusText = document.getElementById('statusText')
        const accountInfo = document.getElementById('accountInfo')
        const connectedAccount = document.getElementById('connectedAccount')

        if (this.isConnected && this.currentAccount) {
            statusIndicator.className = 'w-3 h-3 rounded-full bg-green-500'
            statusText.textContent = 'Connected'
            accountInfo.classList.remove('hidden')
            connectedAccount.textContent = this.currentAccount
        } else {
            statusIndicator.className = 'w-3 h-3 rounded-full bg-red-500'
            statusText.textContent = 'Not connected'
            accountInfo.classList.add('hidden')
        }

        // Update button states
        const isConnected = this.isConnected && this.provider
        document.getElementById('connectBtn').disabled = !this.provider || isConnected
        document.getElementById('disconnectBtn').disabled = !isConnected
        document.getElementById('getAccountsBtn').disabled = !this.provider
        document.getElementById('getChainIdBtn').disabled = !this.provider
        document.getElementById('signMessageBtn').disabled = !isConnected
        document.getElementById('sendTxBtn').disabled = !isConnected
    }

    log(message, data = null) {
        const timestamp = new Date().toLocaleTimeString()
        const logEntry = `[${timestamp}] ${message}`
        
        console.log(logEntry, data || '')
        
        const eventLog = document.getElementById('eventLog')
        const logElement = document.createElement('div')
        logElement.className = 'mb-1'
        logElement.textContent = logEntry
        
        if (data) {
            const dataElement = document.createElement('div')
            dataElement.className = 'ml-4 text-gray-600'
            dataElement.textContent = typeof data === 'object' ? JSON.stringify(data, null, 2) : data
            logElement.appendChild(dataElement)
        }
        
        eventLog.appendChild(logElement)
        eventLog.scrollTop = eventLog.scrollHeight
    }

    clearLog() {
        const eventLog = document.getElementById('eventLog')
        eventLog.innerHTML = '<div class="text-gray-500">Log cleared</div>'
    }

    toHex(num) {
        return '0x' + num.toString(16)
    }
}

// Initialize dApp when page loads
document.addEventListener('DOMContentLoaded', () => {
    window.horizcoinDApp = new HorizCoinDApp()
})

// Also listen for provider injection
window.addEventListener('horizcoin#initialized', () => {
    console.log('HorizCoin provider initialized')
    if (window.horizcoinDApp) {
        window.horizcoinDApp.detectProvider()
        window.horizcoinDApp.updateUI()
    }
})

window.addEventListener('ethereum#initialized', () => {
    console.log('Ethereum provider initialized')
    if (window.horizcoinDApp) {
        window.horizcoinDApp.detectProvider()
        window.horizcoinDApp.updateUI()
    }
})