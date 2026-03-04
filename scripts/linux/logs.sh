#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${1:-$PWD}"
LINES="${LINES:-200}"

if [[ ! -d "${PROJECT_DIR}" ]]; then
  echo "[ERROR] Project directory does not exist: ${PROJECT_DIR}" >&2
  exit 1
fi

if [[ ! -f "${PROJECT_DIR}/docker-compose.yml" ]]; then
  echo "[ERROR] docker-compose.yml not found in ${PROJECT_DIR}" >&2
  exit 1
fi

cd "${PROJECT_DIR}"
docker compose logs --tail "${LINES}" -f "${@:2}"
