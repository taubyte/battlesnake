#!/usr/bin/env bash
# Fallback installer — prefers vendored binaries from post/ (workshops pattern).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [ -f "${ROOT}/post/tau" ] && [ -f "${ROOT}/post/dream" ]; then
  bash "${ROOT}/post/init.sh"
  exit $?
fi

log() { echo "[install-tools] $*"; }

install_tau() {
  if command -v tau >/dev/null 2>&1; then return 0; fi
  local version="${TAU_CLI_VERSION:-0.1.16}" arch bin_arch url
  arch="$(uname -m)"
  case "$arch" in
    x86_64) bin_arch=amd64 ;;
    aarch64|arm64) bin_arch=arm64 ;;
    *) log "ERROR: unsupported arch: ${arch}"; return 1 ;;
  esac
  url="https://github.com/taubyte/tau-cli/releases/download/v${version}/tau-cli_${version}_linux_${bin_arch}.tar.gz"
  log "Downloading tau ${version}..."
  curl -fsSL "$url" -o /tmp/tau-cli.tar.gz
  sudo tar -xzf /tmp/tau-cli.tar.gz -C /usr/local/bin tau
  sudo chmod 755 /usr/local/bin/tau
  rm -f /tmp/tau-cli.tar.gz
}

install_dream() {
  if command -v dream >/dev/null 2>&1; then return 0; fi
  if command -v npm >/dev/null 2>&1; then
    sudo npm install -g @taubyte/dream 2>/dev/null || true
  fi
  command -v dream >/dev/null 2>&1 || curl -fsSL https://get.tau.link/dream | sudo sh || true
}

log "Vendored binaries missing — falling back to network install..."
install_tau
install_dream
command -v tau >/dev/null 2>&1 && command -v dream >/dev/null 2>&1 || {
  log "ERROR: install failed — ensure post/tau and post/dream exist"
  exit 1
}
