import * as secp256k1 from '@noble/secp256k1'
import { sha256 } from '@noble/hashes/sha256'
import { generateMnemonic, mnemonicToSeed, validateMnemonic } from '@scure/bip39'
import { wordlist } from '@scure/bip39/wordlists/english'
import { HDKey } from '@scure/bip32'

// HorizCoin uses secp256k1 and SHA-256 like Bitcoin
// Address format will be bech32m (to be implemented based on chain spec)

export class CryptoUtils {
  // Generate a new mnemonic phrase
  static generateMnemonic(): string {
    return generateMnemonic(wordlist, 128) // 12 words
  }

  // Validate mnemonic phrase
  static validateMnemonic(mnemonic: string): boolean {
    return validateMnemonic(mnemonic, wordlist)
  }

  // Derive master key from mnemonic
  static async deriveMasterKey(mnemonic: string, passphrase = ''): Promise<HDKey> {
    const seed = await mnemonicToSeed(mnemonic, passphrase)
    return HDKey.fromMasterSeed(seed)
  }

  // Derive account key using BIP44-like path
  // Using coin type 0 (Bitcoin) until HorizCoin gets its own registered number
  static deriveAccount(masterKey: HDKey, accountIndex = 0): HDKey {
    const path = `m/44'/0'/0'/0/${accountIndex}`
    return masterKey.derive(path)
  }

  // Get public key from private key
  static getPublicKey(privateKey: Uint8Array): Uint8Array {
    return secp256k1.getPublicKey(privateKey, true) // compressed
  }

  // Create HorizCoin address from public key
  // For now, using a simple hex format until bech32m spec is finalized
  static publicKeyToAddress(publicKey: Uint8Array): string {
    const hash = sha256(publicKey)
    // Take first 20 bytes like Ethereum
    const addressBytes = hash.slice(0, 20)
    return '0x' + Array.from(addressBytes, b => b.toString(16).padStart(2, '0')).join('')
  }

  // Sign message with private key
  static async signMessage(message: string, privateKey: Uint8Array): Promise<string> {
    const messageBytes = new TextEncoder().encode(message)
    const messageHash = sha256(messageBytes)
    const signature = await secp256k1.sign(messageHash, privateKey)
    return signature.toCompactHex()
  }

  // Verify message signature
  static async verifyMessage(message: string, signature: string, publicKey: Uint8Array): Promise<boolean> {
    try {
      const messageBytes = new TextEncoder().encode(message)
      const messageHash = sha256(messageBytes)
      return secp256k1.verify(signature, messageHash, publicKey)
    } catch {
      return false
    }
  }

  // Generate random bytes for account ID
  static generateId(): string {
    const bytes = crypto.getRandomValues(new Uint8Array(16))
    return Array.from(bytes, b => b.toString(16).padStart(2, '0')).join('')
  }

  // Convert hex string to bytes
  static hexToBytes(hex: string): Uint8Array {
    if (hex.startsWith('0x')) {
      hex = hex.slice(2)
    }
    const bytes = new Uint8Array(hex.length / 2)
    for (let i = 0; i < hex.length; i += 2) {
      bytes[i / 2] = parseInt(hex.slice(i, i + 2), 16)
    }
    return bytes
  }

  // Convert bytes to hex string
  static bytesToHex(bytes: Uint8Array): string {
    return '0x' + Array.from(bytes, b => b.toString(16).padStart(2, '0')).join('')
  }
}