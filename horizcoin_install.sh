#!/bin/bash
# HorizCoin Ultra+Infinity Deployment Script

echo "=== HorizCoin Ultra+Infinity GIC Deployment ==="
echo "Target GPV: $100,000,000,000,000 USD annualized"
echo "Activating environment..."

python3 -m venv horizcoin_env
source horizcoin_env/bin/activate

pip install --upgrade pip
pip install -r requirements.txt

echo ""
echo "Deployment complete."
echo "Launch with: python horizcoin_core.py"
echo "Metrics: http://localhost:8000/admin/metrics"
echo "Protocol Status: ENFORCED"
