#!/usr/bin/env bash

group_info base "git curl wget unzip jq tree htop vim ripgrep fd build toolchain"

group_base() {
  step "base packages"
  ensure_packages git curl wget unzip tar ca-certificates gnupg less \
    jq tree htop vim build cmake ripgrep fd

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
}
