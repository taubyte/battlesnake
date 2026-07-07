#!/usr/bin/env bash
# Deploy to aventr.cloud: import project, update domain, push config+code, test /move.
set -euo pipefail
SCRIPT_NAME="deploy"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/common.sh
source "${ROOT}/scripts/lib/common.sh"
# shellcheck source=lib/wait-build.sh
source "${ROOT}/scripts/lib/wait-build.sh"

MSG="${1:-update snake}"

need_tau
need_docker
project_ready || die "Run init first: bash scripts/init.sh"

templates_sync
wasm_docker_build || exit 1

cloud_select_remote
remote_ensure_project
remote_apply_https_triggers
remote_ensure_domain
align_project_id || true

log "Pushing config -> ${REMOTE_CLOUD}..."
tau_push_config "$MSG" || exit 1
await_builds config 60 || exit 1

log "Pushing code -> ${REMOTE_CLOUD}..."
tau_push_code "$MSG" || exit 1
await_builds code 90 || exit 1

remote_test_move || exit 1
print_tournament_urls
fork_push "$MSG"
