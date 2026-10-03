#!/usr/bin/env bash

DRY_RUN=${DRY_RUN:-0}
BACKUP_STAMP=${BACKUP_STAMP:-$(date +%Y%m%d%H%M%S)}

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_RESET=$'\033[0m'
  C_BLUE=$'\033[34m'
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
  C_RED=$'\033[31m'
  C_DIM=$'\033[2m'
else
  C_RESET=
  C_BLUE=
  C_GREEN=
  C_YELLOW=
  C_RED=
  C_DIM=
fi

step() { printf '\n%s==>%s %s\n' "$C_BLUE" "$C_RESET" "$*"; }
ok() { printf '  %s+%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
skip() { printf '  %s.%s %s\n' "$C_DIM" "$C_RESET" "$*"; }
warn() { printf '  %s!%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
die() {
  printf '\n%serror:%s %s\n' "$C_RED" "$C_RESET" "$*" >&2
  exit 1
}

have() { command -v "$1" >/dev/null 2>&1; }

run() {
  if [ "$DRY_RUN" = 1 ]; then
    printf '  %s$ %s%s\n' "$C_DIM" "$*" "$C_RESET"
    return 0
  fi
  "$@"
}

run_sh() { run sh -c "$1"; }

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  if have sudo; then SUDO=sudo; fi
fi
sudo_run() {
  if [ -z "$SUDO" ] && [ "$(id -u)" -ne 0 ]; then
    die "need root or sudo for: $*"
  fi
  run $SUDO "$@"
}

fetch() { curl -fsSL "$@"; }

os_name() {
  case "$(uname -s)" in
    Linux) echo linux ;;
    Darwin) echo darwin ;;
    *) echo unsupported ;;
  esac
}

is_wsl() { grep -qi microsoft /proc/version 2>/dev/null; }

arch_go() {
  case "$(uname -m)" in
    x86_64 | amd64) echo amd64 ;;
    aarch64 | arm64) echo arm64 ;;
    *) echo unsupported ;;
  esac
}

arch_uname() {
  case "$(uname -m)" in
    x86_64 | amd64) echo x86_64 ;;
    aarch64 | arm64) echo aarch64 ;;
    *) echo unsupported ;;
  esac
}

latest_tag() {
  local json v
  json=$(fetch "https://api.github.com/repos/$1/releases/latest") || return 1
  v=$(printf '%s\n' "$json" | sed -n 's/.*"tag_name": *"v\{0,1\}\([^"]*\)".*/\1/p' | head -1)
  [ -n "$v" ] || return 1
  printf '%s\n' "$v"
}

mktmp() { mktemp -d "${TMPDIR:-/tmp}/terminal-setup.XXXXXX"; }

install_bin() { sudo_run install -m 0755 "$1" "/usr/local/bin/$(basename "$1")"; }

version_ge() {
  [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]
}

link() {
  local src=$1 dest=$2
  [ -e "$src" ] || die "missing source: $src"
  run mkdir -p "$(dirname "$dest")"

  if [ -L "$dest" ] && [ "$(readlink -f "$dest" 2>/dev/null)" = "$(readlink -f "$src")" ]; then
    skip "$dest"
    return 0
  fi

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    run mv "$dest" "$dest.bak.$BACKUP_STAMP"
    warn "backed up $dest -> $dest.bak.$BACKUP_STAMP"
  fi

  run ln -s "$src" "$dest"
  ok "$dest -> $src"
}
