#!/usr/bin/env bash
set -euo pipefail

# Rocky Linux 9 bootstrap script
# Safe to run repeatedly on fresh VMs.

if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

log() {
  printf "\n[%s] %s\n" "$(date +"%H:%M:%S")" "$*"
}

warn() {
  printf "[WARN] %s\n" "$*"
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command not found: $1"
    exit 1
  fi
}

pkg_available() {
  local pkg="$1"
  dnf -q list --available "$pkg" >/dev/null 2>&1 || dnf -q list --installed "$pkg" >/dev/null 2>&1
}

install_available_packages() {
  local pkgs=("$@")
  local to_install=()
  local missing=()
  local p

  for p in "${pkgs[@]}"; do
    if pkg_available "$p"; then
      to_install+=("$p")
    else
      missing+=("$p")
    fi
  done

  if ((${#to_install[@]} > 0)); then
    $SUDO dnf -y install "${to_install[@]}"
  fi

  if ((${#missing[@]} > 0)); then
    warn "Skipped unavailable packages: ${missing[*]}"
  fi
}

require_cmd bash
require_cmd dnf
require_cmd rpm

if [[ ! -f /etc/os-release ]]; then
  echo "Cannot detect OS (/etc/os-release not found)."
  exit 1
fi

# shellcheck source=/dev/null
source /etc/os-release

if [[ "${ID:-}" != "rocky" || "${VERSION_ID:-}" != 9* ]]; then
  echo "This script is intended for Rocky Linux 9."
  echo "Detected: ID='${ID:-unknown}', VERSION_ID='${VERSION_ID:-unknown}'"
  exit 1
fi

log "Installing DNF plugin tooling"
$SUDO dnf -y install dnf-plugins-core

log "Enabling CRB repository"
if command -v crb >/dev/null 2>&1; then
  $SUDO crb enable || true
else
  $SUDO dnf config-manager --set-enabled crb || true
fi

log "Installing EPEL repository"
$SUDO dnf -y install epel-release

log "Refreshing metadata"
$SUDO dnf -y makecache

log "Updating base system packages"
$SUDO dnf -y upgrade

BASE_PACKAGES=(
  bash-completion
  bat
  btop
  ca-certificates
  curl
  eza
  fd-find
  fzf
  gcc
  gcc-c++
  git
  htop
  jq
  make
  neovim
  openssl-devel
  python3
  python3-pip
  ripgrep
  stow
  tmux
  tree
  unzip
  wget
  which
  xz
  zip
  zsh
)

TROUBLESHOOTING_PACKAGES=(
  atop
  audit
  bind-utils
  blktrace
  bpftool
  bpftrace
  bcc-tools
  crash
  dmidecode
  dnf-utils
  ethtool
  iotop
  iperf3
  iproute
  ipset
  iptables
  iputils
  kexec-tools
  lm_sensors
  lsof
  ltrace
  mtr
  nc
  net-tools
  nethogs
  nmap
  nmap-ncat
  nvme-cli
  pciutils
  perf
  policycoreutils-python-utils
  sos
  smartmontools
  strace
  sysstat
  tcpdump
  traceroute
  usbutils
  wireshark-cli
)

log "Installing core CLI packages"
install_available_packages "${BASE_PACKAGES[@]}"

log "Installing advanced Linux troubleshooting packages"
install_available_packages "${TROUBLESHOOTING_PACKAGES[@]}"

if command -v pip3 >/dev/null 2>&1; then
  log "Upgrading pip for current user"
  python3 -m pip install --user --upgrade pip || true
fi

log "Setting zsh as default shell for $USER (if available)"
if command -v zsh >/dev/null 2>&1; then
  if [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v zsh)" ]]; then
    chsh -s "$(command -v zsh)" "$USER" || true
  fi
fi

if [[ -d "${HOME}/.dotfiles" ]]; then
  log "Dotfiles repository found at ${HOME}/.dotfiles"
  if command -v stow >/dev/null 2>&1; then
    log "Tip: link configs with stow from ${HOME}/.dotfiles when ready"
    echo "  cd ~/.dotfiles"
    echo "  stow zsh tmux nvim ranger"
  fi
fi

log "Rocky Linux 9 bootstrap complete"
