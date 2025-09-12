// Mock environment for testing extension APIs
import { vi } from 'vitest'

// Mock chrome APIs
const mockStorage = {
  local: {
    get: vi.fn().mockImplementation((_keys) => {
      return Promise.resolve({})
    }),
    set: vi.fn().mockResolvedValue(undefined),
    remove: vi.fn().mockResolvedValue(undefined)
  }
}

const mockRuntime = {
  sendMessage: vi.fn().mockResolvedValue({}),
  onMessage: {
    addListener: vi.fn()
  },
  getURL: vi.fn().mockImplementation((path) => `chrome-extension://test/${path}`)
}

const mockTabs = {
  query: vi.fn().mockResolvedValue([]),
  sendMessage: vi.fn().mockResolvedValue(undefined)
}

const mockWindows = {
  create: vi.fn().mockResolvedValue({ id: 1 })
}

// Set up global chrome object
globalThis.chrome = {
  storage: mockStorage,
  runtime: mockRuntime,
  tabs: mockTabs,
  windows: mockWindows
} as any

// Mock Web Crypto API functions that don't exist in test environment
const mockCrypto = {
  getRandomValues: vi.fn().mockImplementation((array) => {
    for (let i = 0; i < array.length; i++) {
      array[i] = Math.floor(Math.random() * 256)
    }
    return array
  }),
  subtle: {
    importKey: vi.fn().mockResolvedValue({}),
    deriveKey: vi.fn().mockResolvedValue({}),
    encrypt: vi.fn().mockResolvedValue(new ArrayBuffer(32)),
    decrypt: vi.fn().mockResolvedValue(new ArrayBuffer(32))
  }
}

// Override crypto functions if needed, but don't replace the whole object
if (typeof globalThis.crypto === 'undefined' || !globalThis.crypto.subtle) {
  Object.defineProperty(globalThis, 'crypto', {
    value: mockCrypto,
    writable: true
  })
}

export { mockStorage, mockRuntime, mockTabs, mockWindows, mockCrypto }