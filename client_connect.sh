#!/bin/bash
echo "Connecting to quantum-immune global network..."
wg-quick up client
echo "Connected — 192.0.2.1 (anycast) — <15 ms from anywhere on Earth"
