import os
import requests
from typing import Dict, Any, Union
from decimal import Decimal

class FalconXAPIError(Exception):
    pass

def get_conversion_quote(
    pair: str = "BTC-USD",
    side: str = "buy",
    quantity: Union[float, Decimal] = 100.0,
    api_token: str = None,
    timeout: int = 15
) -> Dict[str, Any]:
    token = api_token or os.getenv("FALCONX_API_TOKEN")
    if not token:
        raise ValueError("Missing FalconX API token")

    url = "https://api.falconx.io/v1/quote"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
        "Accept": "application/json"
    }

    payload = {
        "pair": pair.upper(),
        "side": side.lower(),
        "quantity": float(quantity)
    }

    try:
        r = requests.post(url, json=payload, headers=headers, timeout=timeout)
        r.raise_for_status()
        data = r.json()

        if "price" not in data:
            raise FalconXAPIError("Invalid quote response")

        return data

    except requests.RequestException as e:
        raise FalconXAPIError(f"FalconX request failed: {e}")
