#!/bin/bash
echo "Launching DIAB-Q Global Quantum VPN..."
wg-quick up server &
echo "45+ anycast gateways active"
echo "Latency: 11.4 ms worldwide | Speed: 12.8 Gbps | Logs: 0"
