# Integration with your BIN sponsor (e.g. Marqeta, Stripe Issuing)
import requests

def issue_real_card():
    return requests.post("https://api.yourbinsponsor.com/cards", json={
        "type": "virtual",
        "currency": "USD"
    }).json()
