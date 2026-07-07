#!/usr/bin/env bash
set -euo pipefail
SCRIPT_NAME="dream-background"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/common.sh
source "${ROOT}/scripts/lib/common.sh"

dream_install_npm
need_dream
docker_wait
dream_resolve_universe

if dream_universe_ready "$DREAM_UNIVERSE"; then
  log "Dream universe '${DREAM_UNIVERSE}' already running."
  exit 0
fi

mkdir -p "${HOME}/.dream"
nohup dream start --universes "$DREAM_UNIVERSE" >>"${DREAM_LOG}" 2>&1 &
log "Dream starting (log: ${DREAM_LOG})"
sleep 5
dream_wait_universe "$DREAM_UNIVERSE" 24 || { tail -n 20 "${DREAM_LOG}"; exit 1; }
log "Dream ready."
