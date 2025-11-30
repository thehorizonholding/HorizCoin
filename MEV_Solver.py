import json
from web3 import Web3

HZC = "0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
WETH = "0xCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
USDC = "0xDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD"
MINT_100B = 100_000_000_000 * 10**18

L_map = {
    "uni":   {"router": "0xUniswap",  "reserves": (200_000_000 * 10**18, 100_000 * 10**18)},
    "sushi": {"router": "0xSushiswap", "reserves": (150_000_000 * 10**18, 75_000 * 10**18)},
    "bal":   {"router": "0xBalancer", "reserves": (300_000_000 * 10**18, 150_000 * 10**18)},
}

def get_output(amount_in, res_in, res_out):
    return res_out - ((res_in * res_out) // (res_in + amount_in))

def best_split(remaining):
    best = max(L_map.items(), key=lambda x: get_output(min(remaining//10, 10**24), *x[1]["reserves"]))
    amount = min(remaining, remaining//10 or remaining, 10**24)
    return {"router": best[1]["router"], "amount_in": amount}

def calculate_splits():
    splits = []
    remaining = MINT_100B
    while remaining > 10**20:
        split = best_split(remaining)
        splits.append(split)
        remaining -= split["amount_in"]
    return splits

if __name__ == "__main__":
    print("Optimal $100B liquidation splits:")
    print(json.dumps(calculate_splits()[:20], indent=2))
