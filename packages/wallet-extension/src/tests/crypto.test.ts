// Tests for crypto utilities
import { describe, it, expect } from 'vitest'
import { CryptoUtils } from '../shared/crypto'

describe('CryptoUtils', () => {
  it('should generate valid mnemonic', () => {
    const mnemonic = CryptoUtils.generateMnemonic()
    expect(mnemonic).toBeDefined()
    expect(mnemonic.split(' ')).toHaveLength(12)
    expect(CryptoUtils.validateMnemonic(mnemonic)).toBe(true)
  })

  it('should validate mnemonic correctly', () => {
    const validMnemonic = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about'
    const invalidMnemonic = 'invalid mnemonic phrase'
    
    expect(CryptoUtils.validateMnemonic(validMnemonic)).toBe(true)
    expect(CryptoUtils.validateMnemonic(invalidMnemonic)).toBe(false)
  })

  it('should generate consistent addresses from public keys', () => {
    const testPrivateKey = new Uint8Array(32).fill(1)
    const publicKey = CryptoUtils.getPublicKey(testPrivateKey)
    const address1 = CryptoUtils.publicKeyToAddress(publicKey)
    const address2 = CryptoUtils.publicKeyToAddress(publicKey)
    
    expect(address1).toBe(address2)
    expect(address1).toMatch(/^0x[a-fA-F0-9]{40}$/)
  })

  it('should generate unique account IDs', () => {
    const id1 = CryptoUtils.generateId()
    const id2 = CryptoUtils.generateId()
    
    expect(id1).not.toBe(id2)
    expect(id1).toMatch(/^[a-fA-F0-9]{32}$/)
    expect(id2).toMatch(/^[a-fA-F0-9]{32}$/)
  })

  it('should convert between hex and bytes correctly', () => {
    const originalBytes = new Uint8Array([0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef])
    const hex = CryptoUtils.bytesToHex(originalBytes)
    const convertedBytes = CryptoUtils.hexToBytes(hex)
    
    expect(hex).toBe('0x0123456789abcdef')
    expect(convertedBytes).toEqual(originalBytes)
  })
})