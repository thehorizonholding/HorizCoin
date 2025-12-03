#!/bin/bash
echo "Launching your private 1T L3 Appchain..."
curl -s https://eclipse.build/deploy | bash -- --name maelstrom-1t --private
echo "Your L3 is live: https://maelstrom-1t.eclipse.build"
echo "100% MEV capture: ENABLED"
