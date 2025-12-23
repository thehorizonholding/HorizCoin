# Negawatts + V2G Arbitrage — Monetizes energy reduction
def sell_negawatts(mw_reduction: float = 10.0):
    """Sells demand response to grid operator"""
    print(f"Selling {mw_reduction} MW negawatts — earning $50k/hour during peak")
    # Integrate with Energy Web or Power Ledger in production

def v2g_arbitrage(ev_battery_kwh: int = 100):
    """EV sells power back during peak pricing"""
    revenue = ev_battery_kwh * 0.35  # $0.35/kWh peak rate
    print(f"V2G arbitrage: {ev_battery_kwh} kWh → ${revenue:.2f} profit")

v2g_arbitrage()
