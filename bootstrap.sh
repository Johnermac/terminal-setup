#!/usr/bin/env sh
# One-liner entrypoint:
#   curl -fsSL https://raw.githubusercontent.com/<user>/terminal-setup/main/bootstrap.sh | sh
# Clones (or updates) the repo, then hands off to install.sh. Extra args pass through.
set -eu

REPO_URL=${TERMINAL_SETUP_REPO:-https://github.com/johnermac/terminal-setup.git}
REPO_DIR=${TERMINAL_SETUP_DIR:-$HOME/projects/terminal-setup}

command -v git >/dev/null 2>&1 || {
  echo "installing git..." >&2
  sudo apt-get update && sudo apt-get install -y git
}

if [ -d "$REPO_DIR/.git" ]; then
  echo "==> updating $REPO_DIR"
  git -C "$REPO_DIR" pull --ff-only
else
  echo "==> cloning into $REPO_DIR"
  mkdir -p "$(dirname "$REPO_DIR")"
  git clone "$REPO_URL" "$REPO_DIR"
fi

exec bash "$REPO_DIR/install.sh" "$@"
