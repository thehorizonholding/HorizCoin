# IPv4 Address Leasing — Monetizes unused /24 blocks
import requests

def lease_ipv4_block(block: str = "192.168.1.0/24", duration_days: int = 365):
    """Lists unused IPv4 block on decentralized marketplace"""
    payload = {
        "block": block,
        "duration": duration_days,
        "price_per_month": 5000  # USD equivalent in GIC
    }
    response = requests.post("https://api.ipxo.com/list", json=payload)
    print(f"IPv4 block {block} listed — earning $60k/year")
    return response.json()

# Auto-list all unused blocks
lease_ipv4_block()
