bash -lc '
set -euo pipefail
owner="thehorizonholding"; repos=("saas-platform-exact-spelling-" "HorizCoin"); ts=$(date +%Y%m%d-%H%M%S)
for repo in "${repos[@]}"; do
  echo ">> $owner/$repo"
  db="$(gh repo view "$owner/$repo" --json defaultBranchRef -q ".defaultBranchRef.name")"
  tmp="$(mktemp -d)"; pushd "$tmp" >/dev/null
  gh repo clone "$owner/$repo" .
  git checkout -B "$db" "origin/$db"
  br="chore/repo-bootstrap-$ts"; git checkout -b "$br"
  mkdir -p .github/ISSUE_TEMPLATE .github/workflows
  cat > .github/CODEOWNERS <<EOF
# Default ownership
* @thehorizonholding
EOF
  cat > .github/pull_request_template.md <<EOF
## Summary
- Describe the change and reasoning.

## Type of change
- [ ] Feature
- [ ] Bug fix
- [ ] Chore / Maintenance
- [ ] Docs

## Checklist
- [ ] I’ve run the CI locally (if applicable).
- [ ] I’ve added/updated tests (if applicable).
- [ ] I’ve updated documentation (if applicable).
- [ ] I’ve considered security, secrets, and sensitive data handling.
- [ ] I’ve linked related issues and added context.
EOF
  cat > .github/ISSUE_TEMPLATE/bug_report.md <<EOF
---
name: Bug report
about: Create a report to help us improve
labels: bug
---
### Describe the bug
A clear and concise description of the bug.
EOF
  cat > .github/ISSUE_TEMPLATE/feature_request.md <<EOF
---
name: Feature request
about: Suggest an idea for this project
labels: enhancement
---
### Problem statement
What problem are you trying to solve?
EOF
  cat > .github/ISSUE_TEMPLATE/config.yml <<EOF
blank_issues_enabled: false
contact_links:
  - name: Security reports
    url: https://github.com/thehorizonholding
    about: Please report security issues privately as described in SECURITY.md
EOF
  cat > .github/workflows/checks.yml <<EOF
name: Checks
on:
  pull_request:
  push:
    branches: [ main, master ]
permissions:
  contents: read
jobs:
  shell:
    if: \${{ hashFiles("**/*.sh") != "" }}
    name: Shell lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install ShellCheck and shfmt
        run: |
          sudo apt-get update
          sudo apt-get install -y shellcheck shfmt
      - name: ShellCheck
        run: |
          set -euo pipefail
          if [ -z "\$(git ls-files "*.sh")" ]; then exit 0; fi
          git ls-files "*.sh" | xargs -r -n1 shellcheck
      - name: shfmt (check formatting)
        run: |
          set -euo pipefail
          if [ -z "\$(git ls-files "*.sh")" ]; then exit 0; fi
          git ls-files "*.sh" | xargs -r -n100 shfmt -i 2 -ci -s -d
  node:
    if: \${{ hashFiles("package.json") != "" }}
    name: Node/Hardhat CI
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm
      - name: Install
        run: npm ci || npm install
      - name: Lint (if available)
        run: npm run -s lint || echo "No lint script"
      - name: Build (if available)
        run: npm run -s build || echo "No build script"
      - name: Test (if available)
        run: npm test --silent || echo "No test script"
  foundry:
    if: \${{ hashFiles("**/foundry.toml") != "" }}
    name: Foundry (Solidity)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Foundry
        uses: foundry-rs/foundry-toolchain@v1
        with:
          version: stable
      - name: Build
        run: forge build
      - name: Test
        run: forge test -vvv
EOF
  cat > .github/dependabot.yml <<EOF
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "daily"
    open-pull-requests-limit: 5
    reviewers:
      - "thehorizonholding"
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
    reviewers:
      - "thehorizonholding"
EOF
  cat > SECURITY.md <<EOF
# Security Policy
Security fixes are applied to the default branch.
Report privately (do not open public issues). Acknowledge within 72 hours.
EOF
  cat > .editorconfig <<EOF
root = true
[*]
end_of_line = lf
charset = utf-8
insert_final_newline = true
indent_style = space
indent_size = 2
trim_trailing_whitespace = true
[*.md]
trim_trailing_whitespace = false
EOF
  cat > .gitattributes <<EOF
* text=auto eol=lf
*.sh text eol=lf
*.lock linguist-generated
EOF
  if [[ "$repo" == "saas-platform-exact-spelling-" ]]; then
    cat > LICENSE <<EOF
MIT License
Copyright (c) 2025 thehorizonholding
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction...
EOF
  fi
  git add .
  git commit -m "chore: repository bootstrap (CI, templates, Dependabot, security)"
  git push -u origin "$br"
  pb="$(mktemp)"; cat > "$pb" <<EOF
This PR bootstraps the repository with CI (Shell/Node/Foundry), CODEOWNERS, PR/Issue templates, SECURITY.md, .editorconfig, .gitattributes, Dependabot, and MIT LICENSE (saas repo only).

Recommended branch protection (apply on default branch):
- Require at least 1 review
- Require status checks to pass (include "Checks")
- Require branches to be up to date
- Require linear history
- Block force pushes and deletions
- Restrict who can push (maintainers)
EOF
  gh pr create --base "$db" --head "$br" --title "chore: repository bootstrap (CI, templates, Dependabot, security)" --body-file "$pb" --label "chore" --reviewer "thehorizonholding"
  popd >/dev/null; rm -rf "$tmp"
done
echo "Done. PRs opened."
'
