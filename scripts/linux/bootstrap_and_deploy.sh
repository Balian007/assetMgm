#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${1:-$PWD}"
OPEN_BACKEND_PORT="${OPEN_BACKEND_PORT:-false}"
EXPOSE_MYSQL="${EXPOSE_MYSQL:-false}"

log() { echo "[$(date '+%F %T')] $*"; }
err() { echo "[ERROR] $*" >&2; }

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    err "Please run as root: sudo bash scripts/linux/bootstrap_and_deploy.sh /path/to/assetMgm"
    exit 1
  fi
}

random_string() {
  local len="${1:-32}"
  # Avoid pipefail + SIGPIPE issues from `tr | head` under strict mode.
  local out=""
  while [[ ${#out} -lt ${len} ]]; do
    out+=$(cat /proc/sys/kernel/random/uuid | tr -d '-')
  done
  echo "${out:0:${len}}"
}

set_env_value() {
  local file="$1"
  local key="$2"
  local value="$3"
  if grep -qE "^${key}=" "${file}"; then
    sed -i "s#^${key}=.*#${key}=${value}#" "${file}"
  else
    echo "${key}=${value}" >> "${file}"
  fi
}

get_env_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "${file}" | tail -n1 | cut -d'=' -f2-
}

ensure_secret_if_placeholder() {
  local file="$1"
  local key="$2"
  local len="$3"
  local current
  current="$(get_env_value "${file}" "${key}" || true)"

  if [[ -z "${current}" || "${current}" == ChangeMe* ]]; then
    set_env_value "${file}" "${key}" "$(random_string "${len}")"
    log "Generated value for ${key}"
  else
    log "Keeping existing value for ${key}"
  fi
}

docker_ready() {
  command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1
}

install_docker_debian() {
  log "Installing Docker on Debian/Ubuntu"
  apt-get update
  apt-get install -y ca-certificates curl gnupg lsb-release ufw

  install -m 0755 -d /etc/apt/keyrings
  if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
    curl -fsSL "https://download.docker.com/linux/${ID}/gpg" | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
  fi

  local codename
  codename="${VERSION_CODENAME:-}"
  if [[ -z "${codename}" ]]; then
    codename="$(lsb_release -cs)"
  fi

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${ID} ${codename} stable" \
    > /etc/apt/sources.list.d/docker.list

  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

install_docker_rhel() {
  log "Installing Docker on RHEL/CentOS/Rocky"
  if command -v dnf >/dev/null 2>&1; then
    dnf -y install dnf-plugins-core curl ca-certificates firewalld
    dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  else
    yum -y install yum-utils curl ca-certificates firewalld
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    yum -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  fi
}

ensure_docker_running() {
  systemctl daemon-reload
  systemctl enable docker
  systemctl restart docker
  docker --version
  docker compose version
}

configure_firewall() {
  log "Configuring firewall"
  local env_file="${PROJECT_DIR}/.env"
  local frontend_port backend_port mysql_port
  frontend_port="$(get_env_value "${env_file}" "FRONTEND_PORT" || true)"
  backend_port="$(get_env_value "${env_file}" "BACKEND_PORT" || true)"
  mysql_port="$(get_env_value "${env_file}" "MYSQL_PORT" || true)"
  frontend_port="${frontend_port:-80}"
  backend_port="${backend_port:-8080}"
  mysql_port="${mysql_port:-3306}"

  if command -v ufw >/dev/null 2>&1; then
    if ufw status | grep -q "Status: active"; then
      ufw allow 22/tcp || true
      ufw allow "${frontend_port}/tcp" || true
      [[ "${OPEN_BACKEND_PORT}" == "true" ]] && ufw allow "${backend_port}/tcp" || true
      [[ "${EXPOSE_MYSQL}" == "true" ]] && ufw allow "${mysql_port}/tcp" || true
      log "UFW rules updated"
    fi
  fi

  if command -v firewall-cmd >/dev/null 2>&1; then
    if systemctl is-active --quiet firewalld; then
      firewall-cmd --permanent --add-port="${frontend_port}/tcp" || true
      [[ "${OPEN_BACKEND_PORT}" == "true" ]] && firewall-cmd --permanent --add-port="${backend_port}/tcp" || true
      [[ "${EXPOSE_MYSQL}" == "true" ]] && firewall-cmd --permanent --add-port="${mysql_port}/tcp" || true
      firewall-cmd --reload || true
      log "firewalld rules updated"
    fi
  fi
}

prepare_env() {
  local env_file="${PROJECT_DIR}/.env"
  local example_file="${PROJECT_DIR}/.env.example"

  if [[ ! -f "${example_file}" ]]; then
    err "Missing ${example_file}."
    exit 1
  fi

  if [[ ! -f "${env_file}" ]]; then
    cp "${example_file}" "${env_file}"
    log "Created .env from .env.example"
  fi

  ensure_secret_if_placeholder "${env_file}" "MYSQL_PASSWORD" 24
  ensure_secret_if_placeholder "${env_file}" "MYSQL_ROOT_PASSWORD" 24
  ensure_secret_if_placeholder "${env_file}" "JWT_SECRET" 48
  chmod 600 "${env_file}" || true
}

deploy_stack() {
  cd "${PROJECT_DIR}"

  if [[ ! -f docker-compose.yml ]]; then
    err "docker-compose.yml not found in ${PROJECT_DIR}"
    exit 1
  fi

  log "Building and starting containers"
  docker compose up -d --build

  log "Container status"
  docker compose ps

  local frontend_port backend_port
  frontend_port="$(get_env_value .env FRONTEND_PORT || true)"
  backend_port="$(get_env_value .env BACKEND_PORT || true)"
  frontend_port="${frontend_port:-80}"
  backend_port="${backend_port:-8080}"

  log "Deployment complete"
  log "Frontend: http://<SERVER_IP>:${frontend_port}/"
  log "Backend:  http://<SERVER_IP>:${backend_port}/"
  log "Swagger:  http://<SERVER_IP>:${backend_port}/swagger-ui.html"
}

main() {
  require_root

  if [[ ! -d "${PROJECT_DIR}" ]]; then
    err "Project directory does not exist: ${PROJECT_DIR}"
    exit 1
  fi

  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
  else
    err "Cannot detect Linux distribution"
    exit 1
  fi

  if ! docker_ready; then
    case "${ID}" in
      ubuntu|debian)
        install_docker_debian
        ;;
      centos|rhel|rocky|almalinux)
        install_docker_rhel
        ;;
      *)
        if [[ "${ID_LIKE:-}" == *debian* ]]; then
          install_docker_debian
        elif [[ "${ID_LIKE:-}" == *rhel* || "${ID_LIKE:-}" == *fedora* ]]; then
          install_docker_rhel
        else
          err "Unsupported distribution: ${ID}. Please install Docker manually first."
          exit 1
        fi
        ;;
    esac
  else
    log "Docker and docker compose already available"
  fi

  ensure_docker_running
  prepare_env
  configure_firewall
  deploy_stack
}

main "$@"
