#!/usr/bin/env bash
# Fast local WASM compile check (no cloud).
set -euo pipefail
SCRIPT_NAME="compile"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/common.sh
source "${ROOT}/scripts/lib/common.sh"

project_ready || die "Run init first: bash scripts/init.sh"
templates_sync
wasm_docker_build
