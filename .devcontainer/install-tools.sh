#!/usr/bin/env bash
# Install tau + dream into the Codespace. Idempotent — safe to re-run.
set -euo pipefail

log() { echo "[install-tools] $*"; }

install_tau() {
  if command -v tau >/dev/null 2>&1; then
    log "tau already installed: $(tau version 2>/dev/null || echo ok)"
    return 0
  fi

  local version="${TAU_CLI_VERSION:-0.1.16}" arch bin_arch url
  arch="$(uname -m)"
  case "$arch" in
    x86_64) bin_arch=amd64 ;;
    aarch64|arm64) bin_arch=arm64 ;;
    *) log "ERROR: unsupported arch: ${arch}"; return 1 ;;
  esac

  url="https://github.com/taubyte/tau-cli/releases/download/v${version}/tau-cli_${version}_linux_${bin_arch}.tar.gz"
  log "Installing tau ${version} (${bin_arch})..."
  curl -fsSL "$url" -o /tmp/tau-cli.tar.gz
  sudo tar -xzf /tmp/tau-cli.tar.gz -C /usr/local/bin tau
  sudo chmod 755 /usr/local/bin/tau
  rm -f /tmp/tau-cli.tar.gz
  command -v tau >/dev/null 2>&1 || { log "ERROR: tau install failed"; return 1; }
  log "tau installed: $(tau version 2>/dev/null || echo ok)"
}

install_dream() {
  if command -v dream >/dev/null 2>&1; then
    log "dream already installed"
    return 0
  fi

  log "Installing dream via npm..."
  if command -v npm >/dev/null 2>&1; then
    sudo npm install -g @taubyte/dream 2>/dev/null || npm install -g @taubyte/dream 2>/dev/null || true
  fi

  if ! command -v dream >/dev/null 2>&1; then
    log "npm install failed — trying get.tau.link/dream..."
    curl -fsSL https://get.tau.link/dream | sudo sh || true
  fi

  if ! command -v dream >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
    local dream_js
    dream_js="$(npm root -g 2>/dev/null)/@taubyte/dream/index.js"
    if [ -f "$dream_js" ]; then
      sudo ln -sf "$dream_js" /usr/local/bin/dream
      sudo chmod +x /usr/local/bin/dream 2>/dev/null || true
    fi
  fi

  command -v dream >/dev/null 2>&1 || { log "ERROR: dream install failed"; return 1; }
  log "dream installed"
}

install_tau
install_dream
log "Tooling ready."
