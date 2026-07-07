#!/usr/bin/env bash
# Install vendored tau + dream binaries (same pattern as taubyte/workshops).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
POST="${ROOT}/post"

log() { echo "[post/init] $*"; }

install_vendored() {
  [ -f "${POST}/tau" ]   || { log "ERROR: missing ${POST}/tau"; return 1; }
  [ -f "${POST}/dream" ] || { log "ERROR: missing ${POST}/dream"; return 1; }

  log "Installing vendored tau + dream to /usr/local/bin ..."
  sudo cp "${POST}/tau" "${POST}/dream" /usr/local/bin/
  sudo chmod 755 /usr/local/bin/tau /usr/local/bin/dream

  command -v tau >/dev/null 2>&1   || { log "ERROR: tau not on PATH"; return 1; }
  command -v dream >/dev/null 2>&1 || { log "ERROR: dream not on PATH"; return 1; }

  if command -v tau >/dev/null 2>&1; then
    grep -q 'tau autocomplete' "${HOME}/.bashrc" 2>/dev/null || \
      echo 'eval "$(tau autocomplete)"' >> "${HOME}/.bashrc" || true
  fi

  log "tau:   $(tau version 2>/dev/null || echo ok)"
  log "dream: $(dream --help 2>&1 | head -1 || echo ok)"
}

install_vendored
