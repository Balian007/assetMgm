#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${1:-$PWD}"

log() { echo "[$(date '+%F %T')] $*"; }
err() { echo "[ERROR] $*" >&2; }

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    err "Please run as root: sudo bash scripts/linux/rollback.sh /path/to/assetMgm"
    exit 1
  fi
}

validate_project() {
  if [[ ! -d "${PROJECT_DIR}" ]]; then
    err "Project directory does not exist: ${PROJECT_DIR}"
    exit 1
  fi
  if [[ ! -f "${PROJECT_DIR}/docker-compose.yml" ]]; then
    err "docker-compose.yml not found in ${PROJECT_DIR}"
    exit 1
  fi
}

rollback() {
  cd "${PROJECT_DIR}"

  if ! docker image inspect asset-mgm/backend:rollback-latest >/dev/null 2>&1; then
    err "Rollback image missing: asset-mgm/backend:rollback-latest"
    exit 1
  fi

  if ! docker image inspect asset-mgm/frontend:rollback-latest >/dev/null 2>&1; then
    err "Rollback image missing: asset-mgm/frontend:rollback-latest"
    exit 1
  fi

  docker tag asset-mgm/backend:rollback-latest asset-mgm/backend:1.0.0
  docker tag asset-mgm/frontend:rollback-latest asset-mgm/frontend:1.0.0

  log "Rollback images tagged, restarting services"
  docker compose up -d --no-build backend frontend
  docker compose ps
}

main() {
  require_root
  validate_project
  rollback
}

main "$@"
