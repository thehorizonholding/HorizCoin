#!/usr/bin/env bash

echo "HorizCoin Setup – Installing dependencies..."

# Python packages
pip install --upgrade pip
pip install gymnasium stable-baselines3 torch numpy eth-account web3 requests base64 uuid fastapi uvicorn

# Foundry for contracts
if ! command -v forge &> /dev/null; then
    echo "Installing Foundry..."
    curl -L https://foundry.paradigm.xyz | bash
    foundryup
fi

# iperf3 for PoB
if ! command -v iperf3 &> /dev/null; then
    echo "Installing iperf3..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt update && sudo apt install -y iperf3
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install iperf3
    else
        echo "Please install iperf3 manually: https://iperf.fr/iperf-download.php"
    fi
fi

echo "Setup finished."
echo "Launch with: python horizcoin_core.py --enforce-target --simulation"
echo "$100 trillion per year enforcement starts immediately."
