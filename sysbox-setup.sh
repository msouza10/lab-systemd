#!/usr/bin/env bash
set -euo pipefail

# log builder
log() { echo "[INFO] $*"; }

# root check
if [[ $EUID -ne 0 ]]; then
    log "This script must be run as root (sudo)." >&2
    exit 1
fi

# auto passing flag
ASSUME_YES=false

# auto passing
for arg in "$@"; do
  [[ $arg == "-y" ]] && ASSUME_YES=true && break
done

confirm() {
  local prompt="$1"
  if $ASSUME_YES; then
    return 0
  fi
  local reply
  read -rp "$prompt [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

log "Updating repos APT..."
DEBIAN_FRONTEND=noninteractive apt-get update -qq

# ensure dependencies
for cmd in wget mktemp jq curl wget; do
    if ! command -v "$cmd" &>/dev/null; then
        log "Installing dependency $cmd"
        DEBIAN_FRONTEND=noninteractive apt-get install -y "$cmd"
    fi
done

# variables
DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
CLI_PLUGINS_DIR="$DOCKER_CONFIG/cli-plugins"
ARCH="$(dpkg --print-architecture)"
SYSBOX_URL="https://downloads.nestybox.com/sysbox/releases/v0.6.6/sysbox-ce_0.6.6-0.linux_amd64.deb"
SYSBOX_URL_LATEST=$(curl -fsSL https://api.github.com/repos/nestybox/sysbox/releases/latest \
  | jq -r '.assets[] | select(.name | endswith(".deb")) | .browser_download_url' \
  | head -n1)

# Confirmation number 1
confirm "We will install missing dependencies and may stop your running containers and Docker service. Continue?" \
  || { log "Aborting."; exit 1; }

# functions
docker_install() {
    if ! command -v docker &>/dev/null; then
        confirm "Docker not found. Install it?" \
            || { log "Docker is needed. Abort."; exit 1; }
        log "Installing Docker..."
        curl -fsSL https://get.docker.com | bash
    else
        log "Docker is installed."
    fi

    mapfile -t containers_running < <(docker ps -q || true)

}

docker_ce_install() {
    log "Configuring docker-compose plugin..."
    if [[ -x "$CLI_PLUGINS_DIR/docker-compose" ]] || command -v docker-compose &>/dev/null; then
        log "docker-compose-plugin is installed"
    else
        log "Attempting install via apt..."
        if DEBIAN_FRONTEND=noninteractive apt-get install -y docker-compose-plugin; then
            log "Installed by apt"
        else
            log "apt install failed, falling back to official script"
            mkdir -p "$CLI_PLUGINS_DIR"
            curl -fsSL "https://github.com/docker/compose/releases/download/v2.35.1/docker-compose-linux-x86_64" \
                -o "$CLI_PLUGINS_DIR/docker-compose"
            chmod +x "$CLI_PLUGINS_DIR/docker-compose"
            log "docker-compose installed at $CLI_PLUGINS_DIR/docker-compose"
        fi
    fi
}

sysbox_install() {
    if command -v sysbox-runc &>/dev/null; then
        log "sysbox-runc already installed"
        return
    fi
    log "sysbox-runc not found. Installing sysbox-ce..."

    TMP_DEB=$(mktemp --suffix=.deb)
    LOGDIR=$(dirname "$TMP_DEB")
    LOGFILE="$LOGDIR/sysbox-install.log"
    mkdir -p "$LOGDIR"

    cleanup() {
        local code=$?
        if [[ $code -eq 0 ]]; then
            rm -f "$TMP_DEB" "$LOGFILE"
        else
            log "Failed — preserved .deb at $TMP_DEB and logs in $LOGFILE"
        fi
    }
    trap cleanup ERR EXIT

    if [[ ${#containers_running[@]} -gt 0 ]]; then
        log "Stopping running containers:"
        docker ps --format "table {{.ID}}	{{.Names}}	{{.Status}}"
        confirm "Stop all containers and Docker service?" \
            || { log "Abort installation."; exit 1; }
        docker stop "${containers_running[@]}"
        systemctl stop docker
    fi

    if [[ "$ARCH" != "amd64" ]]; then
        log "Unsupported architecture: $ARCH. Only amd64 supported."
        exit 1
    fi

    echo "Choose sysbox version to install:"
    echo "[1] Latest available"
    echo "[2] Tested (0.6.6)"
    read -rp "Choose [1/2]: " answer
    answer="${answer:-2}"

    case "$answer" in
        1)
            log "Installing latest version..." | tee -a "$LOGFILE"
            wget --show-progress --timeout=30 --tries=3 -qO "$TMP_DEB" "$SYSBOX_URL_LATEST" >>"$LOGFILE" 2>&1
            ;;
        2)
            log "Installing tested version (0.6.6)..." | tee -a "$LOGFILE"
            wget --show-progress --timeout=30 --tries=3 -qO "$TMP_DEB" "$SYSBOX_URL" >>"$LOGFILE" 2>&1
            ;;
        *)
            log "Invalid option. Abort." | tee -a "$LOGFILE"
            exit 1
            ;;
    esac


    log "Installing sysbox package..."
    apt-get update >>"$LOGFILE" 2>&1
    dpkg -i "$TMP_DEB" >>"$LOGFILE" 2>&1 || true
    apt-get install -f -y >>"$LOGFILE" 2>&1

    if ! command -v sysbox-runc &>/dev/null; then
        log "sysbox-runc not found after install. Check $LOGFILE"
        exit 1
    fi
    log "sysbox-ce installed successfully"
}

# ————— exec functions —————
docker_install
docker_ce_install
sysbox_install

if confirm "Reboot required to complete installation. Reboot now?"; then
    log "Rebooting..."
    sleep 3
    reboot
else
    log "Installation complete. Please reboot manually."
    systemctl start docker
    if [[ ${#containers_running[@]} -gt 0 ]]; then
        docker start "${containers_running[@]}"
    fi
fi
