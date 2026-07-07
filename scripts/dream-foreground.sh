#!/usr/bin/env bash
# Run Dream in foreground — use a SECOND terminal. Blocks while Dream runs.
set -euo pipefail
SCRIPT_NAME="dream-foreground"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/common.sh
source "${ROOT}/scripts/lib/common.sh"

bash "${ROOT}/scripts/ensure-tools.sh"
need_dream
docker_wait
dream_resolve_universe

if dream_universe_ready "$DREAM_UNIVERSE"; then
  log "Dream universe '${DREAM_UNIVERSE}' is already running."
  exit 0
fi

if dream_cli_has_start; then
  log "dream start --universes ${DREAM_UNIVERSE}"
  exec dream start --universes "$DREAM_UNIVERSE"
fi

log "dream new multiverse --universes ${DREAM_UNIVERSE}"
log "Leave THIS terminal open. In another: bash scripts/init.sh"
exec dream new multiverse --universes "$DREAM_UNIVERSE"
