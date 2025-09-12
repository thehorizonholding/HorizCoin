import type { EncryptedVault, VaultData, Account } from '../types'
import { CryptoUtils } from '../crypto'

export class SecureVault {
  private static readonly STORAGE_KEY = 'horizcoin_vault'
  private static readonly ITERATIONS = 100000 // PBKDF2 iterations

  // Encrypt vault data with password
  static async encrypt(data: VaultData, password: string): Promise<EncryptedVault> {
    const encoder = new TextEncoder()
    const passwordBytes = encoder.encode(password)
    const dataBytes = encoder.encode(JSON.stringify(data))
    
    // Generate random salt and IV
    const salt = crypto.getRandomValues(new Uint8Array(32))
    const iv = crypto.getRandomValues(new Uint8Array(12))
    
    // Derive key using PBKDF2
    const keyMaterial = await crypto.subtle.importKey(
      'raw',
      passwordBytes,
      'PBKDF2',
      false,
      ['deriveKey']
    )
    
    const key = await crypto.subtle.deriveKey(
      {
        name: 'PBKDF2',
        salt,
        iterations: this.ITERATIONS,
        hash: 'SHA-256'
      },
      keyMaterial,
      { name: 'AES-GCM', length: 256 },
      false,
      ['encrypt']
    )
    
    // Encrypt data
    const encrypted = await crypto.subtle.encrypt(
      { name: 'AES-GCM', iv },
      key,
      dataBytes
    )
    
    return {
      encrypted: Array.from(new Uint8Array(encrypted), b => b.toString(16).padStart(2, '0')).join(''),
      salt: Array.from(salt, b => b.toString(16).padStart(2, '0')).join(''),
      iv: Array.from(iv, b => b.toString(16).padStart(2, '0')).join('')
    }
  }

  // Decrypt vault data with password
  static async decrypt(vault: EncryptedVault, password: string): Promise<VaultData> {
    const encoder = new TextEncoder()
    const passwordBytes = encoder.encode(password)
    
    // Convert hex strings back to bytes
    const encrypted = new Uint8Array(vault.encrypted.match(/.{2}/g)!.map(byte => parseInt(byte, 16)))
    const salt = new Uint8Array(vault.salt.match(/.{2}/g)!.map(byte => parseInt(byte, 16)))
    const iv = new Uint8Array(vault.iv.match(/.{2}/g)!.map(byte => parseInt(byte, 16)))
    
    // Derive key using same parameters
    const keyMaterial = await crypto.subtle.importKey(
      'raw',
      passwordBytes,
      'PBKDF2',
      false,
      ['deriveKey']
    )
    
    const key = await crypto.subtle.deriveKey(
      {
        name: 'PBKDF2',
        salt,
        iterations: this.ITERATIONS,
        hash: 'SHA-256'
      },
      keyMaterial,
      { name: 'AES-GCM', length: 256 },
      false,
      ['decrypt']
    )
    
    // Decrypt data
    const decrypted = await crypto.subtle.decrypt(
      { name: 'AES-GCM', iv },
      key,
      encrypted
    )
    
    const decoder = new TextDecoder()
    const dataString = decoder.decode(decrypted)
    return JSON.parse(dataString)
  }

  // Save encrypted vault to storage
  static async saveVault(vault: EncryptedVault): Promise<void> {
    await chrome.storage.local.set({ [this.STORAGE_KEY]: vault })
  }

  // Load encrypted vault from storage
  static async loadVault(): Promise<EncryptedVault | null> {
    const result = await chrome.storage.local.get(this.STORAGE_KEY)
    return result[this.STORAGE_KEY] || null
  }

  // Check if vault exists
  static async vaultExists(): Promise<boolean> {
    const vault = await this.loadVault()
    return vault !== null
  }

  // Create new vault with mnemonic
  static async createVault(password: string, mnemonic?: string): Promise<{ vault: EncryptedVault; account: Account }> {
    if (!mnemonic) {
      mnemonic = CryptoUtils.generateMnemonic()
    }
    
    if (!CryptoUtils.validateMnemonic(mnemonic)) {
      throw new Error('Invalid mnemonic phrase')
    }
    
    // Derive first account
    const masterKey = await CryptoUtils.deriveMasterKey(mnemonic)
    const accountKey = CryptoUtils.deriveAccount(masterKey, 0)
    
    if (!accountKey.privateKey) {
      throw new Error('Failed to derive account key')
    }
    
    const publicKey = CryptoUtils.getPublicKey(accountKey.privateKey)
    const address = CryptoUtils.publicKeyToAddress(publicKey)
    
    const accountId = CryptoUtils.generateId()
    const account: Account = {
      id: accountId,
      name: 'Account 1',
      address,
      publicKey: CryptoUtils.bytesToHex(publicKey)
    }
    
    const vaultData: VaultData = {
      mnemonic,
      accounts: [{
        id: accountId,
        name: 'Account 1',
        privateKey: CryptoUtils.bytesToHex(accountKey.privateKey),
        publicKey: CryptoUtils.bytesToHex(publicKey),
        address,
        derivationPath: "m/44'/0'/0'/0/0"
      }]
    }
    
    const vault = await this.encrypt(vaultData, password)
    await this.saveVault(vault)
    
    return { vault, account }
  }

  // Import vault from mnemonic
  static async importVault(password: string, mnemonic: string): Promise<{ vault: EncryptedVault; account: Account }> {
    return this.createVault(password, mnemonic)
  }

  // Unlock vault with password
  static async unlockVault(password: string): Promise<VaultData> {
    const vault = await this.loadVault()
    if (!vault) {
      throw new Error('No vault found')
    }
    
    try {
      return await this.decrypt(vault, password)
    } catch (error) {
      throw new Error('Invalid password')
    }
  }

  // Clear vault (for reset/logout)
  static async clearVault(): Promise<void> {
    await chrome.storage.local.remove(this.STORAGE_KEY)
  }
}