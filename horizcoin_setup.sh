#!/bin/bash
# HorizCoin Setup – creates environment & installs minimal deps

echo "========================================"
echo "HorizCoin Ultra+Infinity Setup"
echo "Target: $100,000,000,000,000 / year enforced"
echo "========================================"

python3 -m venv env
source env/bin/activate

pip install --upgrade pip
pip install -r requirements.txt

echo ""
echo "Setup complete."
echo "Launch with: python horizcoin_core.py"
echo "Metrics: http://localhost:8000/admin/metrics"
echo "GPV: $100 trillion/year – enforced"
