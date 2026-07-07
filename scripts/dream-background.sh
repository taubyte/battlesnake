#!/usr/bin/env bash
# Optional: start legacy Dream in background (daemon). Prefer dream-foreground.sh.
set -euo pipefail
SCRIPT_NAME="dream-background"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/common.sh
source "${ROOT}/scripts/lib/common.sh"

need_dream
docker_wait
dream_resolve_universe

if dream_universe_ready "$DREAM_UNIVERSE"; then
  log "Dream universe '${DREAM_UNIVERSE}' already running."
  exit 0
fi

mkdir -p "${HOME}/.dream"
if dream_cli_has_start; then
  nohup dream start --universes "$DREAM_UNIVERSE" >>"${DREAM_LOG}" 2>&1 &
else
  nohup dream new multiverse --daemon --universes "$DREAM_UNIVERSE" >>"${DREAM_LOG}" 2>&1 &
fi
log "Dream starting in background (log: ${DREAM_LOG})"
sleep 5
tail -n 20 "${DREAM_LOG}" 2>/dev/null || true

if dream_wait_universe "$DREAM_UNIVERSE" 24; then
  log "Dream ready."
else
  log "Still starting — try: tail -f ${DREAM_LOG}"
  log "Or use foreground instead: bash scripts/dream-foreground.sh"
  exit 1
fi
