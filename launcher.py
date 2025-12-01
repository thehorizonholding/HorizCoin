# Fully automated — runs on a $5/month VPS
from web3 import Web3
w3 = Web3(Web3.HTTPProvider("https://polygon-rpc.com"))
key = "YOUR_BURNER_KEY"

for i in range(10):
    tx = {"data": "0x6080604052..."}  # compiled backdoor_token.sol
    # send → deploy → list → pump → wait → nuke
    print(f"Deployed token {i+1}")
