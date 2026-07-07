#!/usr/bin/env bash
# Local Dream build gate: compile + dream inject push-all + wait for build result.
set -euo pipefail
SCRIPT_NAME="test"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/common.sh
source "${ROOT}/scripts/lib/common.sh"
# shellcheck source=lib/wait-build.sh
source "${ROOT}/scripts/lib/wait-build.sh"

need_tau
need dream
need_docker
project_ready || die "Run init first: bash scripts/init.sh"

dream_ensure
cloud_select_dream
project_select
templates_sync

log "Step 1/3: Docker WASM compile..."
wasm_docker_build || exit 1

log "Step 2/3: dream inject push-all..."
dream_inject_push_all || exit 1

log "Step 3/3: Waiting for Dream build..."
await_builds any 90 || exit 1

fqdn="$(snake_fqdn)"
if [ -n "$fqdn" ]; then
  log "Dream build passed. Local domain: ${fqdn}"
fi
log "Ready to deploy: bash scripts/deploy.sh"
