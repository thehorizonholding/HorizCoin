// Popup script for wallet extension
import type { WalletState } from '../shared/types'
import { SecureVault } from '../shared/storage'

class PopupController {
  private currentState: WalletState | null = null
  private currentScreen = 'loading'

  constructor() {
    this.initializePopup()
    this.setupEventListeners()
  }

  private async initializePopup(): Promise<void> {
    try {
      // Check if wallet exists
      const vaultExists = await SecureVault.vaultExists()
      
      if (!vaultExists) {
        this.showScreen('welcome')
        return
      }

      // Get current wallet state
      const response = await this.sendMessage({ type: 'GET_STATE' })
      
      if (response.success && response.data) {
        this.currentState = response.data
        
        if (this.currentState && this.currentState.isLocked) {
          this.showScreen('unlock')
        } else {
          this.showScreen('wallet')
          this.updateWalletUI()
        }
      } else {
        this.showScreen('welcome')
      }
    } catch (error) {
      console.error('Failed to initialize popup:', error)
      this.showScreen('welcome')
    }
  }

  private setupEventListeners(): void {
    // Welcome screen
    document.getElementById('createWallet')?.addEventListener('click', () => {
      this.showScreen('create')
    })

    document.getElementById('importWallet')?.addEventListener('click', () => {
      this.showScreen('import')
    })

    // Create wallet screen
    document.getElementById('backFromCreate')?.addEventListener('click', () => {
      this.showScreen('welcome')
    })

    document.getElementById('createWalletBtn')?.addEventListener('click', () => {
      this.handleCreateWallet()
    })

    // Import wallet screen
    document.getElementById('backFromImport')?.addEventListener('click', () => {
      this.showScreen('welcome')
    })

    document.getElementById('importWalletBtn')?.addEventListener('click', () => {
      this.handleImportWallet()
    })

    // Unlock screen
    document.getElementById('unlockBtn')?.addEventListener('click', () => {
      this.handleUnlockWallet()
    })

    document.getElementById('unlockPassword')?.addEventListener('keypress', (e) => {
      if (e.key === 'Enter') {
        this.handleUnlockWallet()
      }
    })

    // Main wallet screen
    document.getElementById('lockBtn')?.addEventListener('click', () => {
      this.handleLockWallet()
    })

    document.getElementById('copyAddress')?.addEventListener('click', () => {
      this.copyAddress()
    })

    // Password validation
    this.setupPasswordValidation()
  }

  private setupPasswordValidation(): void {
    const createPassword = document.getElementById('createPassword') as HTMLInputElement
    const confirmPassword = document.getElementById('confirmPassword') as HTMLInputElement
    const createBtn = document.getElementById('createWalletBtn') as HTMLButtonElement

    const importPassword = document.getElementById('importPassword') as HTMLInputElement
    const importConfirmPassword = document.getElementById('importConfirmPassword') as HTMLInputElement
    const importMnemonic = document.getElementById('importMnemonic') as HTMLTextAreaElement
    const importBtn = document.getElementById('importWalletBtn') as HTMLButtonElement

    const validateCreate = () => {
      const password = createPassword?.value || ''
      const confirm = confirmPassword?.value || ''
      const isValid = password.length >= 8 && password === confirm
      if (createBtn) createBtn.disabled = !isValid
    }

    const validateImport = () => {
      const password = importPassword?.value || ''
      const confirm = importConfirmPassword?.value || ''
      const mnemonic = importMnemonic?.value || ''
      const isValid = password.length >= 8 && password === confirm && mnemonic.trim().split(' ').length >= 12
      if (importBtn) importBtn.disabled = !isValid
    }

    createPassword?.addEventListener('input', validateCreate)
    confirmPassword?.addEventListener('input', validateCreate)
    importPassword?.addEventListener('input', validateImport)
    importConfirmPassword?.addEventListener('input', validateImport)
    importMnemonic?.addEventListener('input', validateImport)
  }

  private showScreen(screenId: string): void {
    // Hide all screens
    const screens = ['loading', 'welcome', 'create', 'import', 'unlock', 'wallet', 'connect']
    screens.forEach(id => {
      const element = document.getElementById(id)
      if (element) {
        element.classList.add('hidden')
      }
    })

    // Show target screen
    const targetScreen = document.getElementById(screenId)
    if (targetScreen) {
      targetScreen.classList.remove('hidden')
    }

    this.currentScreen = screenId
  }

  private async handleCreateWallet(): Promise<void> {
    const passwordInput = document.getElementById('createPassword') as HTMLInputElement
    const password = passwordInput?.value

    if (!password || password.length < 8) {
      this.showError('Password must be at least 8 characters')
      return
    }

    try {
      this.showScreen('loading')
      
      const response = await this.sendMessage({
        type: 'CREATE_WALLET',
        payload: { password }
      })

      if (response.success) {
        this.currentState = await this.getWalletState()
        this.showScreen('wallet')
        this.updateWalletUI()
      } else {
        this.showError(response.error || 'Failed to create wallet')
        this.showScreen('create')
      }
    } catch (error) {
      this.showError('Failed to create wallet')
      this.showScreen('create')
    }
  }

  private async handleImportWallet(): Promise<void> {
    const passwordInput = document.getElementById('importPassword') as HTMLInputElement
    const mnemonicInput = document.getElementById('importMnemonic') as HTMLTextAreaElement
    
    const password = passwordInput?.value
    const mnemonic = mnemonicInput?.value?.trim()

    if (!password || password.length < 8) {
      this.showError('Password must be at least 8 characters')
      return
    }

    if (!mnemonic || mnemonic.split(' ').length < 12) {
      this.showError('Invalid recovery phrase')
      return
    }

    try {
      this.showScreen('loading')
      
      const response = await this.sendMessage({
        type: 'IMPORT_WALLET',
        payload: { password, mnemonic }
      })

      if (response.success) {
        this.currentState = await this.getWalletState()
        this.showScreen('wallet')
        this.updateWalletUI()
      } else {
        this.showError(response.error || 'Failed to import wallet')
        this.showScreen('import')
      }
    } catch (error) {
      this.showError('Failed to import wallet')
      this.showScreen('import')
    }
  }

  private async handleUnlockWallet(): Promise<void> {
    const passwordInput = document.getElementById('unlockPassword') as HTMLInputElement
    const password = passwordInput?.value

    if (!password) {
      this.showError('Please enter your password')
      return
    }

    try {
      const response = await this.sendMessage({
        type: 'UNLOCK_WALLET',
        payload: { password }
      })

      if (response.success) {
        this.currentState = response.data.state
        this.showScreen('wallet')
        this.updateWalletUI()
      } else {
        this.showError('Invalid password')
      }
    } catch (error) {
      this.showError('Failed to unlock wallet')
    }
  }

  private async handleLockWallet(): Promise<void> {
    try {
      await this.sendMessage({ type: 'LOCK_WALLET' })
      this.showScreen('unlock')
      
      // Clear form
      const passwordInput = document.getElementById('unlockPassword') as HTMLInputElement
      if (passwordInput) passwordInput.value = ''
    } catch (error) {
      this.showError('Failed to lock wallet')
    }
  }

  private updateWalletUI(): void {
    if (!this.currentState || !this.currentState.currentAccount) {
      return
    }

    const account = this.currentState.currentAccount
    
    // Update account name
    const accountNameEl = document.getElementById('accountName')
    if (accountNameEl) {
      accountNameEl.textContent = account.name
    }

    // Update address
    const addressEl = document.getElementById('accountAddress')
    if (addressEl) {
      const truncated = `${account.address.slice(0, 6)}...${account.address.slice(-4)}`
      addressEl.textContent = truncated
    }

    // Update network
    const networkBtn = document.getElementById('networkBtn')
    if (networkBtn) {
      networkBtn.textContent = this.currentState.currentNetwork.name
    }
  }

  private async copyAddress(): Promise<void> {
    if (!this.currentState?.currentAccount) return

    try {
      await navigator.clipboard.writeText(this.currentState.currentAccount.address)
      
      // Show feedback
      const copyBtn = document.getElementById('copyAddress')
      if (copyBtn) {
        const originalText = copyBtn.textContent
        copyBtn.textContent = '✓'
        setTimeout(() => {
          copyBtn.textContent = originalText
        }, 1000)
      }
    } catch (error) {
      console.error('Failed to copy address:', error)
    }
  }

  private async getWalletState(): Promise<WalletState> {
    const response = await this.sendMessage({ type: 'GET_STATE' })
    return response.data
  }

  private showError(message: string): void {
    // Show error in unlock screen if visible
    if (this.currentScreen === 'unlock') {
      const errorEl = document.getElementById('unlockError')
      if (errorEl) {
        errorEl.textContent = message
        errorEl.classList.remove('hidden')
        setTimeout(() => {
          errorEl.classList.add('hidden')
        }, 3000)
      }
    } else {
      // Generic error display
      console.error('Wallet error:', message)
      alert(message) // TODO: Better error UI
    }
  }

  private async sendMessage(message: any): Promise<any> {
    return new Promise((resolve) => {
      chrome.runtime.sendMessage(message, resolve)
    })
  }
}

// Initialize popup when DOM is loaded
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => new PopupController())
} else {
  new PopupController()
}