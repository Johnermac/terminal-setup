#!/usr/bin/env bash
# Idempotent terminal bootstrap: fish + tmux + starship + fzf/fd/bat/zoxide + lazygit/lazydocker.
# Safe to re-run; existing files are backed up, never silently overwritten.
set -euo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
BACKUP_STAMP=$(date +%Y%m%d%H%M%S)
export BACKUP_STAMP

# shellcheck source=lib/common.sh
. "$REPO_DIR/lib/common.sh"

SKIP_PACKAGES=0
SKIP_CHSH=0
SKIP_PLUGINS=0

usage() {
  cat <<'USAGE'
usage: ./install.sh [options]

  --dry-run         print every command instead of running it
  --skip-packages   don't touch apt / installer scripts (configs only)
  --skip-chsh       don't change the login shell
  --skip-plugins    don't install fisher / TPM plugins
  -h, --help        this text

Re-running is safe. Configs are symlinked from this repo, so `git pull`
updates your live setup with no reinstall.
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)       DRY_RUN=1 ;;
    --skip-packages) SKIP_PACKAGES=1 ;;
    --skip-chsh)     SKIP_CHSH=1 ;;
    --skip-plugins)  SKIP_PLUGINS=1 ;;
    -h|--help)       usage; exit 0 ;;
    *)               usage >&2; die "unknown option: $1" ;;
  esac
  shift
done
export DRY_RUN

# ---------------------------------------------------------------- 1. packages

APT_PACKAGES="fish tmux git curl unzip fzf fd-find bat"

install_packages() {
  step "apt packages"
  if [ "$SKIP_PACKAGES" = 1 ]; then skip "--skip-packages"; return; fi
  have apt-get || die "no apt-get; install $APT_PACKAGES manually then re-run with --skip-packages"

  local missing=()
  for pkg in $APT_PACKAGES; do
    dpkg -s "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
  done

  if [ ${#missing[@]} -eq 0 ]; then
    skip "all present: $APT_PACKAGES"
    return
  fi

  sudo_run apt-get update
  sudo_run apt-get install -y "${missing[@]}"
  ok "installed: ${missing[*]}"
}

# Ubuntu ships fd as `fdfind` and bat as `batcat`. Configs call `fd` + `batcat`,
# so only `fd` needs a shim.
install_fd_shim() {
  step "fd shim"
  if have fd; then skip "fd already on PATH"; return; fi
  have fdfind || { warn "no fdfind; skipping shim"; return; }
  run mkdir -p "$HOME/.local/bin"
  run ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  ok "~/.local/bin/fd -> $(command -v fdfind)"
}

# `fzf --fish` (used by config.fish) landed in 0.48.
FZF_MIN_VERSION=0.48.0

install_fzf() {
  step "fzf >= $FZF_MIN_VERSION"
  if [ "$SKIP_PACKAGES" = 1 ]; then skip "--skip-packages"; return; fi

  local current=""
  have fzf && current=$(fzf --version 2>/dev/null | awk '{print $1}')

  if [ -n "$current" ] && version_ge "$current" "$FZF_MIN_VERSION"; then
    skip "fzf $current"
    return
  fi

  warn "apt fzf is ${current:-absent}; building from source"
  if [ -d "$HOME/.fzf" ]; then
    run git -C "$HOME/.fzf" pull --ff-only
  else
    run git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
  fi
  run "$HOME/.fzf/install" --bin
  sudo_run cp "$HOME/.fzf/bin/fzf" /usr/local/bin/
  ok "fzf installed to /usr/local/bin"
}

install_zoxide() {
  step "zoxide"
  if [ "$SKIP_PACKAGES" = 1 ]; then skip "--skip-packages"; return; fi
  if have zoxide; then skip "$(zoxide --version)"; return; fi
  run sh -c 'curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh'
  ok "zoxide installed"
}

install_starship() {
  step "starship"
  if [ "$SKIP_PACKAGES" = 1 ]; then skip "--skip-packages"; return; fi
  if have starship; then skip "$(starship --version | head -1)"; return; fi
  run sh -c 'curl -sSfL https://starship.rs/install.sh | sh -s -- -y'
  ok "starship installed"
}

install_lazygit() {
  step "lazygit"
  if [ "$SKIP_PACKAGES" = 1 ]; then skip "--skip-packages"; return; fi
  if have lazygit; then skip "$(lazygit --version 2>/dev/null | head -1)"; return; fi

  local arch asset version tmp
  case "$(uname -m)" in
    x86_64)         arch=Linux_x86_64 ;;
    aarch64|arm64)  arch=Linux_arm64 ;;
    *)              warn "unsupported arch $(uname -m); skipping lazygit"; return ;;
  esac

  version=$(curl -sSfL https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
    | grep -Po '"tag_name": *"v\K[^"]*') || { warn "lazygit release lookup failed"; return; }
  asset="https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_${arch}.tar.gz"

  tmp=$(mktemp -d)
  run curl -sSfLo "$tmp/lazygit.tar.gz" "$asset"
  run tar xf "$tmp/lazygit.tar.gz" -C "$tmp" lazygit
  sudo_run install "$tmp/lazygit" -D -t /usr/local/bin/
  run rm -rf "$tmp"
  ok "lazygit $version"
}

install_lazydocker() {
  step "lazydocker"
  if [ "$SKIP_PACKAGES" = 1 ]; then skip "--skip-packages"; return; fi
  if have lazydocker; then skip "already installed"; return; fi
  run sh -c 'curl -sSfL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash'
  ok "lazydocker installed"
}

# ----------------------------------------------------------------- 2. configs

link_configs() {
  step "config symlinks"

  # Real file, never a symlink: host-specific lines live here, out of git.
  if [ ! -f "$HOME/.config/fish/local.fish" ]; then
    run mkdir -p "$HOME/.config/fish"
    run sh -c "printf '# machine-specific fish config — not tracked in git\\n' > '$HOME/.config/fish/local.fish'"
    ok "created ~/.config/fish/local.fish"
  else
    skip "~/.config/fish/local.fish exists"
  fi

  link "$REPO_DIR/config/fish/config.fish"            "$HOME/.config/fish/config.fish"
  link "$REPO_DIR/config/fish/fish_plugins"           "$HOME/.config/fish/fish_plugins"
  link "$REPO_DIR/config/fish/conf.d/gpg.fish"        "$HOME/.config/fish/conf.d/gpg.fish"

  local fn
  for fn in "$REPO_DIR"/config/fish/functions/*.fish; do
    link "$fn" "$HOME/.config/fish/functions/$(basename "$fn")"
  done

  link "$REPO_DIR/config/starship.toml"     "$HOME/.config/starship.toml"
  link "$REPO_DIR/config/tmux/tmux.conf"    "$HOME/.tmux.conf"
  link "$REPO_DIR/config/bin/tmux-git-title" "$HOME/.local/bin/tmux-git-title"
  run chmod +x "$REPO_DIR/config/bin/tmux-git-title"
}

# ----------------------------------------------------------------- 3. plugins

install_fisher() {
  step "fish plugins (fisher)"
  if [ "$SKIP_PLUGINS" = 1 ]; then skip "--skip-plugins"; return; fi
  have fish || { warn "fish not installed; skipping"; return; }

  if [ ! -f "$HOME/.config/fish/functions/fisher.fish" ]; then
    run fish -c 'curl -sSfL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher'
    ok "fisher installed"
  else
    skip "fisher present"
  fi

  # `fisher update` with no args reconciles against fish_plugins — idempotent.
  run fish -c 'fisher update'
  ok "plugins synced from fish_plugins"
}

install_tpm() {
  step "tmux plugins (TPM)"
  if [ "$SKIP_PLUGINS" = 1 ]; then skip "--skip-plugins"; return; fi
  have tmux || { warn "tmux not installed; skipping"; return; }

  if [ -d "$HOME/.tmux/plugins/tpm" ]; then
    skip "tpm present"
  else
    run git clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    ok "tpm cloned"
  fi

  # TPM's installer needs a live server; use a throwaway session.
  run tmux new-session -d -s tpm-install
  run tmux run-shell "$HOME/.tmux/plugins/tpm/bindings/install_plugins"
  run tmux kill-session -t tpm-install
  ok "tmux plugins installed"
}

# ------------------------------------------------------------------ 4. shell

set_default_shell() {
  step "default shell"
  if [ "$SKIP_CHSH" = 1 ]; then skip "--skip-chsh"; return; fi

  local fish_path
  fish_path=$(command -v fish) || { warn "fish not installed; skipping"; return; }

  if [ "${SHELL:-}" = "$fish_path" ]; then
    skip "already fish"
    return
  fi

  grep -qxF "$fish_path" /etc/shells 2>/dev/null || \
    sudo_run sh -c "echo '$fish_path' >> /etc/shells"

  # chsh prompts for a password; don't let a non-interactive run die on it.
  if run chsh -s "$fish_path"; then
    ok "login shell -> fish (takes effect on next login)"
  else
    warn "chsh failed; run manually: chsh -s $fish_path"
  fi
}

# ------------------------------------------------------------------ 5. verify

verify() {
  step "verify"
  local missing=()
  for cmd in fish tmux starship zoxide fzf lazygit; do
    have "$cmd" && ok "$cmd" || missing+=("$cmd")
  done
  have fd || missing+=("fd")
  have batcat || have bat || missing+=("bat")

  if [ ${#missing[@]} -gt 0 ]; then
    warn "missing: ${missing[*]}"
  fi

  printf '\n%sdone.%s\n' "$C_GREEN" "$C_RESET"
  cat <<'NEXT'
Remaining manual step: install JetBrainsMono Nerd Font on the *host* and select
it in your terminal emulator (Windows Terminal: profile -> font
"JetBrainsMono Nerd Font", size 14). Required for tmux theme glyphs.
  helper: scripts/install-font.sh

Then: exec fish  &&  tmux new -s test
NEXT
}

main() {
  [ "$DRY_RUN" = 1 ] && warn "dry run — nothing will be changed"
  install_packages
  install_fd_shim
  install_fzf
  install_zoxide
  install_starship
  install_lazygit
  install_lazydocker
  link_configs
  install_fisher
  install_tpm
  set_default_shell
  verify
}

main "$@"
