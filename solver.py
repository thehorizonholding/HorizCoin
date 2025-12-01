import requests

def nuke_calldata(token):
    r = requests.get(f"https://api.1inch.io/v5.0/137/swap", params={
        "fromTokenAddress": token,
        "toTokenAddress": "0xFF970A61A04b1cA14834A43f5dE4533EbDDB5CC8",
        "amount": str(100_000_000_000 * 10**18),
        "fromAddress": "0xYourNukeContract",
        "slippage": "0.3"
    }).json()
    print("NUKE CALLDATA → paste into nuke.sol:")
    print(r['tx']['data'])

# Run when your token hits $500M+ TVL
nuke_calldata("0xYourLatestHZC")
