#!/usr/bin/env bash
set -euo pipefail
SCRIPT_NAME="doctor"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/common.sh
source "${ROOT}/scripts/lib/common.sh"

if ! command -v tau >/dev/null 2>&1 || ! command -v dream >/dev/null 2>&1; then
  log "Installing missing tooling..."
  bash "${ROOT}/.devcontainer/install-tools.sh"
fi

ok=0
fail() { log "FAIL: $*"; ok=1; }
pass() { log "OK:   $*"; }

command -v tau   >/dev/null && pass "tau installed"   || fail "tau missing"
command -v dream >/dev/null && pass "dream installed" || fail "dream missing"
command -v docker >/dev/null && pass "docker installed" || fail "docker missing"
command -v gh    >/dev/null && pass "gh installed"    || fail "gh missing"
command -v jq    >/dev/null && pass "jq installed"    || warn "jq missing (python fallback used)"

if docker info >/dev/null 2>&1; then pass "docker daemon running"; else fail "docker daemon not running"; fi
if [ -f "${HOME}/tau.yaml" ]; then pass "tau profile present"; else fail "tau not logged in — run: bash scripts/tau-login.sh"; fi
if gh auth status >/dev/null 2>&1; then pass "gh authenticated"; else warn "gh not authenticated"; fi
if project_ready; then pass "project bootstrapped"; else warn "project not bootstrapped — run: bash scripts/init.sh"; fi

exit "$ok"
