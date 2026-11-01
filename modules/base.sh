#!/usr/bin/env bash

group_info base "git ssh curl wget unzip jq tree htop neovim ripgrep fd build toolchain"

enable_paccache() {
  [ "$PM" = pacman ] || return 0
  ensure_packages pacman-contrib
  if [ ! -d /run/systemd/system ]; then
    warn "no systemd; clean the package cache with: paccache -r"
  elif systemctl is-enabled --quiet paccache.timer 2>/dev/null; then
    skip "paccache.timer"
  else
    sudo_run systemctl enable --now paccache.timer
    ok "paccache.timer"
  fi
}

group_base() {
  step "base packages"
  ensure_packages git curl wget unzip tar zstd ca-certificates gnupg less ssh \
    jq tree htop neovim build cmake ripgrep fd

  step "command shims"
  run mkdir -p "$HOME/.local/bin"

  if have fd; then
    skip "fd"
  elif have fdfind; then
    run ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    ok "fd -> fdfind"
  else
    warn "fd not installed"
  fi

  step "package cache cleanup"
  enable_paccache
}
