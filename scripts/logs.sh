#!/usr/bin/env bash
set -euo pipefail
SCRIPT_NAME="logs"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/common.sh
source "${ROOT}/scripts/lib/common.sh"

need_tau
cloud_select_remote 2>/dev/null || true
project_select 2>/dev/null || true
log "Recent builds on ${REMOTE_CLOUD}:"
tau --defaults --yes query builds --since 1h 2>/dev/null || true
