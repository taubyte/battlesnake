#!/usr/bin/env bash
# Run in a DEDICATED terminal — blocks while Dream runs (legacy/workshops CLI).
# Do NOT use --daemon. Leave this terminal open.
set -euo pipefail
SCRIPT_NAME="dream-foreground"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/common.sh
source "${ROOT}/scripts/lib/common.sh"

need_dream
docker_wait
dream_resolve_universe

if dream_universe_ready "$DREAM_UNIVERSE"; then
  log "Dream universe '${DREAM_UNIVERSE}' is already running."
  dream status universe "$DREAM_UNIVERSE" 2>&1 | head -10 || true
  exit 0
fi

if dream_cli_has_start; then
  log "New Dream CLI — running: dream start --universes ${DREAM_UNIVERSE}"
  exec dream start --universes "$DREAM_UNIVERSE"
fi

log "Legacy/workshops Dream — running in foreground (universe: ${DREAM_UNIVERSE})"
log "Leave THIS terminal open. In another terminal run: bash scripts/init.sh"
exec dream new multiverse --universes "$DREAM_UNIVERSE"
