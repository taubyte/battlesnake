#!/usr/bin/env bash
# Idempotent install for tau + dream. Handles missing npm, nvm, old Codespaces, PATH issues.
set -euo pipefail

INSTALL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TAU_BIN="${INSTALL_ROOT}/post/tau"
DREAM_NPM_PKG="${DREAM_NPM_PKG:-@taubyte/dream@latest}"

ilog() { echo "[install-tooling] $*"; }

path_refresh() {
  local npm_bin=""
  if [ -s /usr/local/share/nvm/nvm.sh ]; then
    # shellcheck disable=SC1091
    export NVM_DIR="/usr/local/share/nvm"
    . "${NVM_DIR}/nvm.sh" 2>/dev/null || true
  fi
  npm_bin="$(npm bin -g 2>/dev/null || true)"
  export PATH="/usr/local/bin:/bin:/usr/bin:${npm_bin}:${HOME}/.npm-global/bin:${PATH}"
}

dream_is_valid() {
  command -v dream >/dev/null 2>&1 || return 1
  dream --help 2>/dev/null | grep -qE '(^|[[:space:]])(inject|new)([[:space:]]|$)'
}

install_tau() {
  command -v tau >/dev/null 2>&1 && { ilog "tau ok: $(tau version 2>/dev/null | head -1 || echo ready)"; return 0; }
  [ -f "${TAU_BIN}" ] || { ilog "ERROR: missing ${TAU_BIN}"; return 1; }
  ilog "Installing vendored tau..."
  sudo cp "${TAU_BIN}" /usr/local/bin/tau
  sudo chmod 755 /usr/local/bin/tau
  sudo ln -sf /usr/local/bin/tau /bin/tau 2>/dev/null || true
  path_refresh
  command -v tau >/dev/null 2>&1
}

install_node_npm() {
  path_refresh
  command -v npm >/dev/null 2>&1 && return 0

  ilog "npm missing — installing Node.js..."
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -qq
    sudo apt-get install -y -qq ca-certificates curl gnupg
    sudo apt-get install -y -qq nodejs npm 2>/dev/null || {
      curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
      sudo apt-get install -y -qq nodejs
    }
  fi
  path_refresh
  command -v npm >/dev/null 2>&1
}

dream_link_npm_global() {
  local root dream_js
  for root in "$(npm root -g 2>/dev/null)" "/usr/lib/node_modules" "/usr/local/lib/node_modules"; do
    dream_js="${root}/@taubyte/dream/index.js"
    if [ -f "${dream_js}" ]; then
      sudo ln -sf "${dream_js}" /usr/local/bin/dream
      sudo chmod 755 /usr/local/bin/dream 2>/dev/null || true
      return 0
    fi
  done
  return 1
}

install_dream_npm() {
  install_node_npm || return 1
  path_refresh
  ilog "Installing ${DREAM_NPM_PKG} via npm..."
  npm install -g "${DREAM_NPM_PKG}" 2>/dev/null || \
    sudo env "PATH=${PATH}" npm install -g "${DREAM_NPM_PKG}"
  path_refresh
  dream_link_npm_global || true
  command -v dream >/dev/null 2>&1
}

install_dream_curl() {
  ilog "npm install failed — trying get.tau.link/dream..."
  curl -fsSL https://get.tau.link/dream | sudo sh
  path_refresh
  command -v dream >/dev/null 2>&1
}

install_dream() {
  if dream_is_valid; then
    ilog "dream ok ($(dream --help 2>&1 | grep -E 'start|inject' | head -1 || echo ready))"
    return 0
  fi
  install_dream_npm && return 0
  install_dream_curl && return 0
  return 1
}

install_tooling_all() {
  path_refresh
  install_tau || return 1
  install_dream || return 1
  path_refresh

  grep -q 'tau autocomplete' "${HOME}/.bashrc" 2>/dev/null || \
    echo 'eval "$(tau autocomplete)"' >> "${HOME}/.bashrc" || true

  ilog "tau:  $(command -v tau) ($(tau version 2>/dev/null | head -1 || echo ok))"
  ilog "dream: $(command -v dream) (inject/new CLI)"
  ilog "npm:  $(command -v npm || echo missing)"
  ilog "Done."
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  install_tooling_all
fi
