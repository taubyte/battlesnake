#!/usr/bin/env bash
# Wait for Taubyte builds to finish (Dream or remote cloud).
# Usage: wait_for_builds [config|code|any] [max_polls]

set -euo pipefail

SCRIPT_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_LIB}/common.sh"

kind="${1:-any}"
max="${2:-90}"

await_builds() {
  local i out status_line
  log "Waiting for ${kind} build (max ${max} polls)..."
  for i in $(seq 1 "$max"); do
    out="$(tau --defaults --yes query builds --since 30m 2>/dev/null || true)"
    if [ -n "$out" ]; then
      if echo "$out" | grep -q '…'; then
        : # still building
      elif echo "$out" | grep -Eiq 'fail|error|×'; then
        log "Build FAILED."
        echo "$out"
        local jid
        jid="$(echo "$out" | grep -oE 'jid[=: ][a-zA-Z0-9_-]+' | head -1 | awk '{print $NF}' | tr -d ':')"
        if [ -n "$jid" ]; then
          log "Build logs (jid=${jid}):"
          tau --defaults --yes query logs --jid "$jid" 2>/dev/null || true
        fi
        return 1
      elif [ "$kind" = "any" ]; then
        if echo "$out" | grep -qE '✔|success|succeeded'; then
          log "Build succeeded."
          echo "$out"
          return 0
        fi
      elif echo "$out" | grep -i "$kind" | grep -qE '✔|success|succeeded'; then
        log "${kind} build succeeded."
        echo "$out"
        return 0
      fi
    fi
    [ $((i % 6)) -eq 0 ] && log "Still building... (${i}/${max})"
    sleep 5
  done
  log "Build wait timed out."
  tau --defaults --yes query builds --since 1h 2>/dev/null || true
  return 1
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  SCRIPT_NAME="wait-build"
  need_tau
  await_builds "$kind" "$max"
fi
