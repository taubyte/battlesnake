#!/usr/bin/env bash
# Check Dream status (legacy uses blackhole, new CLI uses default).
set -euo pipefail
SCRIPT_NAME="dream-status"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/common.sh
source "${ROOT}/scripts/lib/common.sh"

need_dream
dream_resolve_universe
log "CLI: $(dream_cli_has_start && echo new || echo legacy) | universe: ${DREAM_UNIVERSE}"
dream status universe "$DREAM_UNIVERSE" 2>&1 || true
[ -f "${DREAM_LOG}" ] && { log "Recent log:"; tail -n 15 "${DREAM_LOG}"; }
