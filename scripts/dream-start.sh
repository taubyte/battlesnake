#!/usr/bin/env bash
# Start Dream with the correct command for your installed binary (new vs legacy/workshops).
set -euo pipefail
SCRIPT_NAME="dream-start"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/common.sh
source "${ROOT}/scripts/lib/common.sh"

need_dream
need_docker

if dream_cli_has_start; then
  log "New Dream CLI detected — running: dream start --universes ${DREAM_UNIVERSE}"
  dream start --universes "$DREAM_UNIVERSE"
else
  log "Legacy/workshops Dream CLI detected."
  if dream_universe_ready "blackhole"; then
    log "Multiverse already up (blackhole)."
  else
    log "Running: dream new multiverse --daemon --universes ${DREAM_UNIVERSE}"
    dream new multiverse --daemon --universes "$DREAM_UNIVERSE"
  fi
  if ! dream_universe_ready "$DREAM_UNIVERSE"; then
    log "Creating universe: dream new universe ${DREAM_UNIVERSE}"
    dream new universe "$DREAM_UNIVERSE"
  fi
fi

dream_ensure
cloud_select_dream
log "Dream ready. Universe: ${DREAM_UNIVERSE}"
