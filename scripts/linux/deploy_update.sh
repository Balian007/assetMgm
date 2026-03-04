#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${1:-$PWD}"

log() { echo "[$(date '+%F %T')] $*"; }
err() { echo "[ERROR] $*" >&2; }

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    err "Please run as root: sudo bash scripts/linux/deploy_update.sh /path/to/assetMgm"
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

backup_running_images() {
  local backed_up=0

  if docker ps -a --format '{{.Names}}' | grep -qx 'asset-mgm-backend'; then
    local backend_id
    backend_id="$(docker inspect --format='{{.Image}}' asset-mgm-backend)"
    docker tag "${backend_id}" asset-mgm/backend:rollback-latest
    log "Saved rollback image: asset-mgm/backend:rollback-latest"
    backed_up=1
  fi

  if docker ps -a --format '{{.Names}}' | grep -qx 'asset-mgm-frontend'; then
    local frontend_id
    frontend_id="$(docker inspect --format='{{.Image}}' asset-mgm-frontend)"
    docker tag "${frontend_id}" asset-mgm/frontend:rollback-latest
    log "Saved rollback image: asset-mgm/frontend:rollback-latest"
    backed_up=1
  fi

  if [[ "${backed_up}" -eq 0 ]]; then
    log "No existing backend/frontend containers found, skipped rollback image backup"
  fi
}

deploy() {
  cd "${PROJECT_DIR}"
  backup_running_images

  log "Updating stack"
  docker compose up -d --build
  docker compose ps
}

main() {
  require_root
  validate_project
  deploy
}

main "$@"
