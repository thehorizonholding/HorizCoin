// Content script - Injects the provider into web pages

// Inject provider script
function injectProvider(): void {
  try {
    const script = document.createElement('script')
    script.src = chrome.runtime.getURL('provider.js')
    script.onload = function() {
      // Remove script element after injection
      script.remove()
    }
    
    // Inject before any other scripts
    const target = document.head || document.documentElement
    target.insertBefore(script, target.firstChild)
  } catch (error) {
    console.error('HorizCoin: Failed to inject provider', error)
  }
}

// Message relay between page and extension
function setupMessageRelay(): void {
  // Listen for messages from injected provider
  window.addEventListener('message', async (event) => {
    if (event.source !== window || !event.data?.type?.startsWith('HORIZCOIN_PROVIDER_')) {
      return
    }

    if (event.data.type === 'HORIZCOIN_PROVIDER_REQUEST') {
      try {
        // Forward request to background script
        const response = await chrome.runtime.sendMessage({
          type: 'PROVIDER_REQUEST',
          payload: event.data.payload
        })

        // Send response back to page
        window.postMessage({
          type: 'HORIZCOIN_PROVIDER_RESPONSE',
          payload: response
        }, '*')
      } catch (error) {
        // Send error response
        window.postMessage({
          type: 'HORIZCOIN_PROVIDER_RESPONSE',
          payload: {
            id: event.data.payload?.id,
            error: {
              code: -32603,
              message: error instanceof Error ? error.message : 'Internal error'
            }
          }
        }, '*')
      }
    }
  })

  // Listen for events from background script
  chrome.runtime.onMessage.addListener((message) => {
    if (message.type?.startsWith('PROVIDER_EVENT_')) {
      const eventType = message.type.replace('PROVIDER_EVENT_', 'HORIZCOIN_PROVIDER_')
      
      window.postMessage({
        type: eventType,
        payload: message.payload
      }, '*')
    }
  })
}

// Initialize content script
function initialize(): void {
  // Only inject on actual web pages, not extension pages
  if (window.location.protocol === 'chrome-extension:' || 
      window.location.protocol === 'moz-extension:') {
    return
  }

  injectProvider()
  setupMessageRelay()
}

// Run on document start
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initialize)
} else {
  initialize()
}