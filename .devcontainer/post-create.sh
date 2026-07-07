#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

chmod +x "${ROOT}"/post/*.sh "${ROOT}"/.devcontainer/*.sh "${ROOT}"/scripts/*.sh "${ROOT}"/scripts/lib/*.sh 2>/dev/null || true

# Install vendored tau + dream (taubyte/workshops pattern — no network required)
bash "${ROOT}/post/init.sh"

if [ -n "${GITHUB_TOKEN:-}" ] && command -v gh >/dev/null 2>&1; then
  echo "$GITHUB_TOKEN" | gh auth login --with-token 2>/dev/null || true
  gh auth setup-git 2>/dev/null || true
fi

# Install Taubyte agent skills for Copilot / Cursor-style assistants
if command -v npx >/dev/null 2>&1; then
  mkdir -p "${HOME}/.cursor/skills"
  npx skills@latest add taubyte/skills --agent cursor --global --copy --yes 2>/dev/null \
    || echo "NOTE: taubyte/skills install skipped (non-fatal)"
  npx skills@latest add taubyte/skills -g --all 2>/dev/null \
    || true
fi

bash "${ROOT}/scripts/tau-login.sh" 2>/dev/null || \
  echo "NOTE: run bash scripts/tau-login.sh if init asks for tau login"

echo ""
echo " Ready."
echo " bash scripts/doctor.sh  # verify tau + dream + docker"
echo " bash scripts/init.sh    # once: Dream project + tau setup"
echo " edit snake.go"
echo " bash scripts/test.sh    # local Dream build gate"
echo " bash scripts/deploy.sh  # deploy to aventr.cloud"
echo ""
