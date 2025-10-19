#!/usr/bin/env bash
# deploy_staging.sh - helper to add package in a new branch and create a PR locally (requires gh)
set -euo pipefail
PKG_DIR=tools/horiz_private_ai
mkdir -p $PKG_DIR
cp -r . $PKG_DIR || true
git checkout -b feat/horiz-private-ai
git add $PKG_DIR
git commit -m "feat: add horiz private ai package (contained)" || true
git push -u origin feat/horiz-private-ai
echo "Branch pushed: feat/horiz-private-ai. Create a PR on GitHub to merge into staging or main."
