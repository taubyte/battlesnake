#!/usr/bin/env bash
# Shared helpers for the Battlesnake tournament workflow.
#
# Flow:
#   init   : tau login + Dream universe + tau new project + templates
#   test   : docker WASM compile + dream inject push-all + wait for build
#   deploy : tau select aventr.cloud + import + domain + push + live /move test

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="${SCRIPT_LIB}/templates"

REMOTE_CLOUD="${TAUBYTE_REMOTE_CLOUD:-aventr.cloud}"
DREAM_UNIVERSE="${TAUBYTE_DREAM_UNIVERSE:-default}"
DREAM_LOG="${HOME}/.dream/dream.log"
PROJECT="${TAUBYTE_PROJECT:-battlesnake}"
DOMAIN="${TAUBYTE_DOMAIN:-snake}"

PROJECT_DIR="${ROOT}/project/${PROJECT}"
SNAKE_FILE="${ROOT}/snake.go"
SNAKE_MOVE="${PROJECT_DIR}/code/functions/fn_move/empty.go"
TEST_PAYLOAD="${TEMPLATES_DIR}/examples/move-request.json"
BUILD_DIR="${ROOT}/.build"

log()  { echo "[${SCRIPT_NAME:-battlesnake}] $*"; }
die()  { log "ERROR: $*"; exit 1; }
warn() { log "WARN: $*"; }

need()         { command -v "$1" >/dev/null 2>&1 || die "'$1' not found."; }
need_tau()     { [ -f "${HOME}/tau.yaml" ] || die "Not logged in. Run: bash scripts/tau-login.sh"; }
need_docker()  { docker info >/dev/null 2>&1 || die "Docker not running (Docker-in-Docker required)."; }
need_dream()   { command -v dream >/dev/null 2>&1 || die "'dream' not found — rebuild the Codespace."; }

# ---------------------------------------------------------------------------
# JSON helper
# ---------------------------------------------------------------------------
json_field() {
  local expr="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -r "$expr" 2>/dev/null
  else
    python3 -c "
import sys, json
try: d = json.load(sys.stdin)
except Exception: sys.exit(0)
expr = '''$expr'''
if ' // ' in expr:
    key = expr.split('//')[0].strip().lstrip('.')
    print(d.get(key, '') or '')
else:
    print(d.get(expr.lstrip('.'), '') or '')
" 2>/dev/null
  fi
}

# ---------------------------------------------------------------------------
# tau helpers
# ---------------------------------------------------------------------------
tau_failed() {
  echo "$1" | grep -Eiq 'command failed|failed with|no cloud selected|Have you selected a cloud|error:'
}

tau_run() {
  local out
  out="$("$@" 2>&1)" || true
  echo "$out"
  tau_failed "$out" && return 1
  return 0
}

tau_current_json() { tau --defaults --yes json current 2>/dev/null; }

tau_field() {
  local label="$1" val
  case "$label" in
    "Cloud Type") val="$(tau_current_json | json_field '.cloudType // .cloud_type // empty')" ;;
    "Cloud")      val="$(tau_current_json | json_field '.cloud // .Cloud // empty')" ;;
    "Project")    val="$(tau_current_json | json_field '.project // .Project // empty')" ;;
    *)            val="$(tau_current_json | json_field ".${label} // empty")" ;;
  esac
  if [ -n "$val" ] && [ "$val" != "null" ] && [ "$val" != "(none)" ]; then
    echo "$val"
    return
  fi
  tau current 2>/dev/null | awk -F'│' -v lbl="$label" '
    NF >= 3 {
      k=$2; gsub(/^[ \t]+|[ \t]+$/,"",k)
      if (k==lbl) { v=$3; gsub(/^[ \t]+|[ \t]+$/,"",v); if (v!="" && v!="(none)") print v }
    }' | head -1
}

cloud_verify() {
  local want_type="$1" want_cloud="$2" t c
  t="$(tau_field "Cloud Type" | tr '[:upper:]' '[:lower:]')"
  c="$(tau_field "Cloud")"
  [ "$t" = "$want_type" ] && [ "$c" = "$want_cloud" ]
}

cloud_verify_dream() {
  local t c
  t="$(tau_field "Cloud Type" | tr '[:upper:]' '[:lower:]')"
  c="$(tau_field "Cloud")"
  [ "$t" != "remote" ] && { [ "$c" = "$DREAM_UNIVERSE" ] || echo "$c" | grep -qi "$DREAM_UNIVERSE"; }
}

# ---------------------------------------------------------------------------
# GitHub helpers
# ---------------------------------------------------------------------------
github_user() {
  gh api user -q .login 2>/dev/null || git config github.user 2>/dev/null || true
}

github_slug_from_dir() {
  local dir="$1" url
  url="$(git -C "$dir" remote get-url origin 2>/dev/null)" || return 1
  echo "$url" | sed -E 's#^(git@github.com:|https://github.com/)##; s#\.git$##'
}

github_repo_slug() {
  local want="$1" user name
  user="$(github_user)"
  [ -n "$user" ] || return 1
  name="$(gh repo list "$user" --json name --limit 300 -q \
    ".[] | select(.name | ascii_downcase == \"$(echo "$want" | tr '[:upper:]' '[:lower:]')\") | .name" \
    2>/dev/null | head -1)"
  [ -n "$name" ] && echo "${user}/${name}"
}

# ---------------------------------------------------------------------------
# Project workspace
# ---------------------------------------------------------------------------
project_ready() {
  [ -d "${PROJECT_DIR}/config/.git" ] && [ -d "${PROJECT_DIR}/code/.git" ]
}

project_select() {
  tau --defaults --yes select project "$PROJECT" >/dev/null 2>&1 || \
    tau --defaults --yes select project --name "$PROJECT" >/dev/null 2>&1 || true
  tau --defaults --yes clear application >/dev/null 2>&1 || true
}

project_clone_existing() {
  local cfg code
  cfg="$(github_repo_slug "tb_${PROJECT}")"
  code="$(github_repo_slug "tb_code_${PROJECT}")"
  [ -n "$cfg" ] && [ -n "$code" ] || return 1
  log "Cloning existing repos: ${cfg}, ${code}"
  mkdir -p "${PROJECT_DIR}"
  [ -d "${PROJECT_DIR}/config/.git" ] || git clone "https://github.com/${cfg}.git" "${PROJECT_DIR}/config"
  [ -d "${PROJECT_DIR}/code/.git" ] || git clone "https://github.com/${code}.git" "${PROJECT_DIR}/code"
  project_ready
}

project_create() {
  if project_ready; then
    log "Project already present at project/${PROJECT}/"
    return 0
  fi
  mkdir -p "${ROOT}/project"
  if project_clone_existing; then
    return 0
  fi
  log "Creating project + GitHub repos (tau new project)..."
  tau_run tau --defaults --yes new project \
    --name "$PROJECT" \
    --description "Battlesnake tournament snake" \
    --location "${ROOT}/project" \
    --private \
    --no-embed-token || die "tau new project failed."
  tau --defaults --yes select project --name "$PROJECT" >/dev/null 2>&1 || true
  project_ready || project_clone_existing || die "Project repos not found after creation."
}

project_id_yaml() {
  awk '/^id:/{print $2; exit}' "${PROJECT_DIR}/config/config.yaml" 2>/dev/null
}

align_project_id() {
  local cloud_id yaml_id
  cloud_id="$(tau --defaults --yes query project "$PROJECT" --json 2>/dev/null | json_field '.id // empty')"
  yaml_id="$(project_id_yaml)"
  [ -n "$cloud_id" ] && [ "$cloud_id" != "null" ] || return 1
  [ "$cloud_id" = "$yaml_id" ] && return 1
  log "Aligning project id: ${yaml_id:-<empty>} -> ${cloud_id}"
  sed -i "s/^id:.*/id: ${cloud_id}/" "${PROJECT_DIR}/config/config.yaml"
  return 0
}

# ---------------------------------------------------------------------------
# Templates
# ---------------------------------------------------------------------------
_sync_dir() {
  local src="$1" dst="$2"; shift 2
  local excludes=("$@") item name skip e
  [ -d "$src" ] || die "Missing templates: $src"
  [ -d "$dst" ] || die "Missing project dir: $dst (run init)"
  for item in "$src"/*; do
    [ -e "$item" ] || continue
    name="$(basename "$item")"
    skip=0
    for e in "${excludes[@]}"; do [ "$name" = "$e" ] && skip=1; done
    [ "$skip" = "1" ] && continue
    rm -rf "${dst:?}/${name}"
    cp -a "$item" "${dst}/${name}"
  done
}

sync_templates_config() {
  _sync_dir "${TEMPLATES_DIR}/config" "${PROJECT_DIR}/config" domains config.yaml
}

sync_templates_code() {
  _sync_dir "${TEMPLATES_DIR}/code" "${PROJECT_DIR}/code"
}

snake_init() {
  [ -f "$SNAKE_FILE" ] && return 0
  log "Creating snake.go from template..."
  cp "${TEMPLATES_DIR}/code/functions/fn_move/empty.go" "$SNAKE_FILE"
}

snake_sync_to_project() {
  [ -f "$SNAKE_FILE" ] || die "Missing snake.go — run: bash scripts/init.sh"
  mkdir -p "$(dirname "$SNAKE_MOVE")"
  cp "$SNAKE_FILE" "$SNAKE_MOVE"
}

templates_install() {
  log "Installing templates into project/${PROJECT}/"
  sync_templates_config
  sync_templates_code
  snake_init
  snake_sync_to_project
  local email
  email="$(git config user.email 2>/dev/null || echo you@example.com)"
  if [ -f "${PROJECT_DIR}/config/config.yaml" ]; then
    sed -i "s/^\([[:space:]]*email:\).*/\1 ${email}/" "${PROJECT_DIR}/config/config.yaml" 2>/dev/null || true
  fi
  log "Templates installed."
}

templates_sync() {
  project_ready || die "Run init first: bash scripts/init.sh"
  sync_templates_config
  sync_templates_code
  snake_sync_to_project
}

# ---------------------------------------------------------------------------
# Dream cloud (@taubyte/dream from npm — `dream start`, universe default)
# ---------------------------------------------------------------------------
dream_cli_has_start() {
  dream --help 2>/dev/null | grep -qE '(^|[[:space:]])start([[:space:]]|$)'
}

dream_resolve_universe() {
  DREAM_UNIVERSE="${TAUBYTE_DREAM_UNIVERSE:-default}"
  export DREAM_UNIVERSE
}

dream_install_npm() {
  command -v dream >/dev/null 2>&1 && return 0
  command -v npm >/dev/null 2>&1 || die "npm missing — rebuild Codespace or run: bash post/init.sh"
  log "Installing @taubyte/dream@latest from npm..."
  sudo npm install -g @taubyte/dream@latest
  command -v dream >/dev/null 2>&1 || die "dream install failed — run: bash post/init.sh"
}

docker_wait() {
  local i
  for i in $(seq 1 45); do
    docker info >/dev/null 2>&1 && return 0
    [ $((i % 5)) -eq 0 ] && log "Waiting for Docker... (${i}/45)"
    sleep 2
  done
  die "Docker not ready — wait for Codespace Docker-in-Docker, then retry."
}

dream_universe_ready() {
  local name="$1"
  dream status universe "$name" >/dev/null 2>&1
}

dream_wait_universe() {
  local name="$1" max="${2:-36}" i
  for i in $(seq 1 "$max"); do
    dream_universe_ready "$name" && return 0
    [ $((i % 3)) -eq 0 ] && log "Waiting for Dream universe '${name}'... (${i}/${max})"
    sleep 5
  done
  return 1
}

dream_ensure() {
  dream_install_npm
  need_dream
  docker_wait
  dream_resolve_universe
  dream_cli_has_start || die "Expected npm Dream with 'dream start' — run: bash post/init.sh"

  log "Dream npm CLI | universe: ${DREAM_UNIVERSE}"

  if dream_universe_ready "$DREAM_UNIVERSE"; then
    log "Dream universe '${DREAM_UNIVERSE}' is ready."
    return 0
  fi

  log "Starting Dream (dream start)..."
  mkdir -p "${HOME}/.dream"
  nohup dream start --universes "$DREAM_UNIVERSE" >>"${DREAM_LOG}" 2>&1 &
  sleep 8
  dream new universe "$DREAM_UNIVERSE" >/dev/null 2>&1 || true

  if dream_wait_universe "$DREAM_UNIVERSE" 36; then
    log "Dream universe '${DREAM_UNIVERSE}' is ready."
    return 0
  fi

  log "Dream log (${DREAM_LOG}):"
  tail -n 20 "${DREAM_LOG}" 2>/dev/null || true
  die "Dream timed out. Run: bash scripts/dream-foreground.sh in another terminal, then retry init."
}

cloud_select_dream() {
  cloud_verify_dream && { log "Cloud: Dream (${DREAM_UNIVERSE})"; return 0; }
  local i
  for i in $(seq 1 10); do
    log "tau select cloud --universe ${DREAM_UNIVERSE} (${i}/10)..."
    tau --defaults --yes select cloud --universe "$DREAM_UNIVERSE" >/dev/null 2>&1 || true
    cloud_verify_dream && { log "Cloud: Dream (${DREAM_UNIVERSE})"; return 0; }
    sleep 3
  done
  die "Could not select Dream universe ${DREAM_UNIVERSE}."
}

dream_ensure_domain() {
  local fqdn
  fqdn="$(snake_fqdn)"
  if [ -n "$fqdn" ] && [ "$fqdn" != "null" ]; then
    log "Domain: ${fqdn}"
    return 0
  fi
  log "Creating generated domain on Dream..."
  ( cd "${PROJECT_DIR}/config" && tau --defaults --yes delete domain "$DOMAIN" >/dev/null 2>&1 || true )
  local out
  out="$( cd "${PROJECT_DIR}/config" && tau --defaults --yes new domain \
    --name "$DOMAIN" --generated-fqdn --type auto \
    --description "Battlesnake tournament snake" 2>&1 )" || { echo "$out"; die "tau new domain failed on Dream."; }
  fqdn="$(domain_fqdn_from_config)"
  [ -n "$fqdn" ] || fqdn="$(echo "$out" | grep -oE 'Fqdn:[^[:space:]]+' | head -1 | sed 's/^Fqdn://')"
  [ -n "$fqdn" ] || { echo "$out"; die "No FQDN after domain create on Dream."; }
  log "Domain: ${fqdn}"
}

dream_inject_push_all() {
  local project_id out
  project_id="$(project_id_yaml)"
  [ -n "$project_id" ] || die "Missing project id in config/config.yaml — run init first."
  log "dream inject push-all (project ${project_id})..."
  out="$(dream inject push-all \
    --path "$(cd "${PROJECT_DIR}" && pwd)" \
    --project-id "$project_id" \
    --universe "$DREAM_UNIVERSE" 2>&1)" || true
  echo "$out"
  if echo "$out" | grep -Eiq 'failed|error|not found|missing'; then
    if ! echo "$out" | grep -Eiq 'success|succeeded|pushed|complete'; then
      log "dream inject push-all reported failure."
      return 1
    fi
  fi
  return 0
}

# ---------------------------------------------------------------------------
# tau push (remote)
# ---------------------------------------------------------------------------
tau_push_config() {
  local msg="$1"
  ( cd "${PROJECT_DIR}/config" && tau_run tau --defaults --yes push project --config-only --message "$msg" )
}

tau_push_code() {
  local msg="$1"
  ( cd "${PROJECT_DIR}/code" && tau_run tau --defaults --yes push project --code-only --message "$msg" )
}

# ---------------------------------------------------------------------------
# Docker WASM compile
# ---------------------------------------------------------------------------
wasm_image_for_function() {
  awk '/^[[:space:]]*image:/{print $2; exit}' "${1}/.taubyte/config.yaml" 2>/dev/null \
    || echo "taubyte/go-wasi:latest"
}

wasm_docker_build() {
  local dir="${1:-${PROJECT_DIR}/code/functions/fn_move}" image out src
  [ -d "$dir" ] || die "Function dir missing: $dir (run init)"
  need_docker
  image="$(wasm_image_for_function "$dir")"
  out="${BUILD_DIR}/fn_move"
  mkdir -p "$out"; find "$out" -mindepth 1 -delete 2>/dev/null || true
  src="$(cd "$dir" && pwd)"
  log "Compiling snake.go -> WASM (docker ${image})..."
  if ! docker run --rm \
    -e FILENAME=empty.go \
    -e GOPROXY=https://proxy.golang.org,direct \
    -v "${out}:/out" \
    --mount "type=bind,src=${src},dst=/src_ro,ro" \
    --mount type=tmpfs,dst=/src \
    "$image" /bin/bash -lc '
      set -euo pipefail
      cp -a /src_ro/. /src/
      [ -e /src/.git ] || mkdir -p /src/.git
      export CODE=/src
      export PATH="/usr/local/go/bin:/usr/local/tinygo/bin:${PATH}"
      source /utils/wasm.sh
      build "${FILENAME}"
    '; then
    log "WASM compile FAILED — fix snake.go (errors above)."
    return 1
  fi
  if [ -z "$(ls -A "$out" 2>/dev/null)" ]; then
    log "WASM compile produced no artifact."
    return 1
  fi
  log "WASM compile OK."
  return 0
}

# ---------------------------------------------------------------------------
# Remote cloud (aventr.cloud)
# ---------------------------------------------------------------------------
cloud_select_remote() {
  cloud_verify "remote" "$REMOTE_CLOUD" && { log "Cloud: ${REMOTE_CLOUD}"; return 0; }
  local i
  for i in $(seq 1 10); do
    log "tau select cloud --fqdn ${REMOTE_CLOUD} (${i}/10)..."
    tau --defaults --yes select cloud --fqdn "$REMOTE_CLOUD" >/dev/null 2>&1 || true
    cloud_verify "remote" "$REMOTE_CLOUD" && { log "Cloud: ${REMOTE_CLOUD}"; return 0; }
    sleep 3
  done
  die "Could not select remote cloud ${REMOTE_CLOUD}."
}

remote_ensure_project() {
  local cfg code
  cfg="$(github_slug_from_dir "${PROJECT_DIR}/config")" || die "Cannot read config repo remote."
  code="$(github_slug_from_dir "${PROJECT_DIR}/code")" || die "Cannot read code repo remote."
  project_select
  if tau --defaults --yes query project "$PROJECT" --json 2>/dev/null | grep -q '"id"'; then
    log "Project already on ${REMOTE_CLOUD}."
    align_project_id || true
    return 0
  fi
  log "Importing project on ${REMOTE_CLOUD}..."
  tau_run tau --defaults --yes import project "$PROJECT" \
    --config "$cfg" --code "$code" || die "tau import project failed on ${REMOTE_CLOUD}."
  project_select
  align_project_id || true
}

remote_apply_https_triggers() {
  local f
  for f in "${PROJECT_DIR}/config/functions/"*.yaml; do
    [ -f "$f" ] || continue
    sed -i 's/^\([[:space:]]*\)type:[[:space:]]*http$/\1type: https/' "$f"
  done
}

domain_fqdn_from_config() {
  local f="${PROJECT_DIR}/config/domains/${DOMAIN}.yaml"
  [ -f "$f" ] && awk '/^fqdn:/{print $2; exit}' "$f"
}

snake_fqdn() {
  local fqdn
  fqdn="$(domain_fqdn_from_config)"
  [ -n "$fqdn" ] && [ "$fqdn" != "null" ] && { echo "$fqdn"; return; }
  tau --defaults --yes clear application >/dev/null 2>&1 || true
  tau --defaults --yes query domain --name "$DOMAIN" --json 2>/dev/null | json_field '.fqdn // empty'
}

remote_ensure_domain() {
  local fqdn out
  fqdn="$(snake_fqdn)"
  if [ -n "$fqdn" ] && [ "$fqdn" != "null" ] && ! echo "$fqdn" | grep -qiE 'localtau|\.local$'; then
    log "Domain: ${fqdn}"
    return 0
  fi
  log "Creating generated domain on ${REMOTE_CLOUD}..."
  ( cd "${PROJECT_DIR}/config" && tau --defaults --yes delete domain "$DOMAIN" >/dev/null 2>&1 || true )
  out="$( cd "${PROJECT_DIR}/config" && tau --defaults --yes new domain \
    --name "$DOMAIN" --generated-fqdn --type auto \
    --description "Battlesnake tournament snake" 2>&1 )" || { echo "$out"; die "tau new domain failed."; }
  fqdn="$(domain_fqdn_from_config)"
  [ -n "$fqdn" ] || fqdn="$(echo "$out" | grep -oE 'Fqdn:[^[:space:]]+' | head -1 | sed 's/^Fqdn://')"
  [ -n "$fqdn" ] || { echo "$out"; die "No FQDN after domain create."; }
  log "Domain: ${fqdn}"
}

remote_test_move() {
  local fqdn url resp move
  need curl
  fqdn="$(snake_fqdn)"
  [ -n "$fqdn" ] && [ "$fqdn" != "null" ] || die "No tournament FQDN — run: bash scripts/deploy.sh"
  url="https://${fqdn}/move"
  log "Testing POST ${url} ..."
  resp="$(curl -sS -f -X POST "$url" \
    -H "Content-Type: application/json" \
    --data-binary "@${TEST_PAYLOAD}" 2>/dev/null || true)"
  [ -n "$resp" ] || { log "Empty /move response (still deploying — wait 30s, then retry)"; return 1; }
  move="$(echo "$resp" | json_field '.move // empty')"
  case "$move" in
    up|down|left|right) log "Live test OK — {\"move\":\"${move}\"}"; return 0 ;;
  esac
  log "Bad /move response:"; echo "$resp"; return 1
}

print_tournament_urls() {
  local fqdn
  fqdn="$(snake_fqdn)"
  [ -n "$fqdn" ] && [ "$fqdn" != "null" ] || { log "FQDN not ready — wait ~1 min and retry test"; return; }
  log ""
  log " Your snake is live:"
  log " https://${fqdn}/"
  log " https://${fqdn}/move  <- register this at play.battlesnake.com"
  log ""
}

fork_push() {
  local msg="$1"
  git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1 || return 0
  [ -f "$SNAKE_FILE" ] || return 0
  ( cd "$ROOT"
    git add snake.go
    git diff --cached --quiet && { log "No snake.go changes to commit."; exit 0; }
    git commit -m "$msg" >/dev/null 2>&1 || true
    git push origin HEAD >/dev/null 2>&1 && log "Committed snake.go to your fork." \
      || warn "Could not push to fork (optional)."
  )
}
