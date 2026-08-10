#!/usr/bin/env bash
# Shared helpers for install.sh. Sourced, not executed.

DRY_RUN=${DRY_RUN:-0}

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_RESET=$'\033[0m'; C_BLUE=$'\033[34m'; C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'; C_RED=$'\033[31m'; C_DIM=$'\033[2m'
else
  C_RESET=; C_BLUE=; C_GREEN=; C_YELLOW=; C_RED=; C_DIM=
fi

step() { printf '\n%s==>%s %s\n' "$C_BLUE" "$C_RESET" "$*"; }
ok()   { printf '  %s✓%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
skip() { printf '  %s·%s %s\n' "$C_DIM" "$C_RESET" "$*"; }
warn() { printf '  %s!%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
die()  { printf '\n%serror:%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; exit 1; }

# run CMD... — echo under --dry-run, execute otherwise
run() {
  if [ "$DRY_RUN" = 1 ]; then
    printf '  %s$ %s%s\n' "$C_DIM" "$*" "$C_RESET"
    return 0
  fi
  "$@"
}

have() { command -v "$1" >/dev/null 2>&1; }

# sudo wrapper: no-op when already root, fails loudly when sudo is missing
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  if have sudo; then SUDO="sudo"; else die "need root or sudo"; fi
fi
sudo_run() { run $SUDO "$@"; }

# link SRC DEST — symlink, backing up any existing non-symlink file
link() {
  local src=$1 dest=$2
  [ -e "$src" ] || die "missing source: $src"
  run mkdir -p "$(dirname "$dest")"

  if [ -L "$dest" ] && [ "$(readlink -f "$dest" 2>/dev/null)" = "$(readlink -f "$src")" ]; then
    skip "$dest (already linked)"
    return 0
  fi

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    local backup="$dest.bak.$BACKUP_STAMP"
    run mv "$dest" "$backup"
    warn "backed up $dest -> $backup"
  fi

  run ln -s "$src" "$dest"
  ok "$dest -> $src"
}

# version_ge A B — true when A >= B (dotted numeric versions)
version_ge() {
  [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]
}
