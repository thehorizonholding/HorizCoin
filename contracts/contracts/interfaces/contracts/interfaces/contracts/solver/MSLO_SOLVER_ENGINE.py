import requests

def get_1inch_calldata(from_token, to_token, amount):
    url = "https://api.1inch.io/v5.0/137/swap"
    params = {
        "fromTokenAddress": from_token,
        "toTokenAddress": to_token,
        "amount": str(amount),
        "fromAddress": "0xYourRouterAddress",
        "slippage": "0.3"
    }
    r = requests.get(url, params=params).json()
    print("=== 1INCH CALLDATA FOR ATOMIC ROUTER ===")
    print(r['tx']['data'])
    print(f"Expected profit: ${int(r['toTokenAmount'])/1e6:,.2f}")

# Example usage
get_1inch_calldata(
    "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",  # WETH
    "0xdAC17F958D2ee523a2206206994597C13D831ec7",  # USDT
    100_000_000_000_000_000_000  # 100k ETH example
)
