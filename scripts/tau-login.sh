#!/usr/bin/env bash
# Non-interactive tau login for Codespaces (uses GITHUB_TOKEN / gh).
set -euo pipefail
SCRIPT_NAME="tau-login"

need() { command -v "$1" >/dev/null 2>&1 || { echo "[${SCRIPT_NAME}] ERROR: '$1' not found."; exit 1; }; }
need tau

token="${GITHUB_TOKEN:-}"
if [ -z "$token" ] && command -v gh >/dev/null 2>&1; then
  token="$(gh auth token 2>/dev/null || true)"
fi

if [ -z "$token" ]; then
  if [ -f "${HOME}/tau.yaml" ]; then
    echo "[${SCRIPT_NAME}] tau profile exists (no token to refresh)."
    exit 0
  fi
  echo "[${SCRIPT_NAME}] No GitHub token — run: tau login"
  exit 1
fi

user="$(gh api user -q .login 2>/dev/null || git config user.name 2>/dev/null || echo "codespaces")"

if [ -f "${HOME}/tau.yaml" ]; then
  echo "[${SCRIPT_NAME}] Refreshing tau token for ${user}..."
  tau login -n "$user" --token "$token" --provider github --set-default --new
else
  echo "[${SCRIPT_NAME}] Logging in as ${user}..."
  tau login -n "$user" --token "$token" --provider github --set-default
fi

if [ ! -f "${HOME}/tau.yaml" ]; then
  echo "[${SCRIPT_NAME}] ERROR: tau login failed — check 'tau version' and try again."
  exit 1
fi
echo "[${SCRIPT_NAME}] Done."
