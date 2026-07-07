#!/usr/bin/env bash
# Run Dream in foreground (optional second terminal). npm @taubyte/dream uses `dream start`.
set -euo pipefail
SCRIPT_NAME="dream-foreground"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/common.sh
source "${ROOT}/scripts/lib/common.sh"

dream_install_npm
need_dream
docker_wait
dream_resolve_universe

if dream_universe_ready "$DREAM_UNIVERSE"; then
  log "Dream universe '${DREAM_UNIVERSE}' is already running."
  exit 0
fi

log "Running: dream start --universes ${DREAM_UNIVERSE}"
log "Leave THIS terminal open. In another terminal: bash scripts/init.sh"
exec dream start --universes "$DREAM_UNIVERSE"
