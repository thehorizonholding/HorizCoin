#!/usr/bin/env bash
set -euo pipefail
owner="thehorizonholding"
repos=("saas-platform-exact-spelling-" "HorizCoin")
for repo in "${repos[@]}"; do
  db="$(gh repo view "$owner/$repo" --json defaultBranchRef -q '.defaultBranchRef.name')"
  gh api -X PUT "repos/$owner/$repo/branches/$db/protection" \
    -H "Accept: application/vnd.github+json" \
    -f required_status_checks='{"strict":true,"contexts":["Checks"]}' \
    -f enforce_admins=true \
    -f required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true,"require_code_owner_reviews":false}' \
    -f restrictions='null' \
    -f allow_force_pushes=false \
    -f allow_deletions=false \
    -f block_creations=false \
    -f required_linear_history=true \
    -f required_conversation_resolution=true
  echo "Protected $owner/$repo:$db"
done
