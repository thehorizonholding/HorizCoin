#!/bin/bash
echo "Launching your private global bank..."
uvicorn bank_core:app --host 0.0.0.0 --port 443 --ssl-keyfile key.pem --ssl-certfile cert.pem &
echo "DIAB is now live."
echo "Your bank is accepting deposits worldwide."
echo "Welcome to the future of money."
