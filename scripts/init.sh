#!/usr/bin/env bash
# One-time setup: tau login, Dream universe, tau new project, templates, initial Dream build.
set -euo pipefail
SCRIPT_NAME="init"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/common.sh
source "${ROOT}/scripts/lib/common.sh"
# shellcheck source=lib/wait-build.sh
source "${ROOT}/scripts/lib/wait-build.sh"

if ! command -v tau >/dev/null 2>&1 || ! command -v dream >/dev/null 2>&1; then
  log "Installing missing tooling..."
  bash "${ROOT}/post/init.sh" 2>/dev/null || bash "${ROOT}/.devcontainer/install-tools.sh"
fi

need tau
need dream
need_docker

if [ ! -f "${HOME}/tau.yaml" ]; then
  bash "${ROOT}/scripts/tau-login.sh" || die "tau login required — run: bash scripts/tau-login.sh"
fi

dream_ensure
cloud_select_dream
project_create
project_select
templates_install
align_project_id || true
dream_ensure_domain
align_project_id || true

log "Initial Dream push (dream inject push-all)..."
dream_inject_push_all || die "Initial dream inject push-all failed."
await_builds any 90 || die "Initial Dream build failed."

log ""
log " Init complete."
log " Edit snake.go, then:"
log "   bash scripts/test.sh    # local Dream build gate"
log "   bash scripts/deploy.sh  # deploy to ${REMOTE_CLOUD}"
log ""
