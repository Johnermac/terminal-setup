#!/usr/bin/env sh
set -eu

REPO_URL=${TERMINAL_SETUP_REPO:-https://github.com/johnermac/terminal-setup.git}
REPO_DIR=${TERMINAL_SETUP_DIR:-$HOME/projects/terminal-setup}

if ! command -v git >/dev/null 2>&1; then
  for pm in "apt-get install -y git" "pacman -S --noconfirm git" "dnf install -y git" \
    "zypper --non-interactive install git" "apk add git"; do
    # shellcheck disable=SC2086
    set -- $pm
    command -v "$1" >/dev/null 2>&1 || continue
    sudo "$@" && break
  done
fi
command -v git >/dev/null 2>&1 || {
  echo "git required" >&2
  exit 1
}

if [ -d "$REPO_DIR/.git" ]; then
  git -C "$REPO_DIR" pull --ff-only
else
  mkdir -p "$(dirname "$REPO_DIR")"
  git clone "$REPO_URL" "$REPO_DIR"
fi

exec bash "$REPO_DIR/install.sh" "$@"
