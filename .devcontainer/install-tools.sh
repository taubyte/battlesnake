#!/usr/bin/env bash
# Re-run tooling install (tau vendored + dream from npm).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "${ROOT}/post/init.sh"
