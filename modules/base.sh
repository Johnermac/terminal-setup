#!/usr/bin/env bash

group_base() {
  step "base packages"
  ensure_packages git curl wget unzip tar ca-certificates gnupg less \
    jq tree htop vim build cmake ripgrep fd bat

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

  if have bat; then
    skip "bat"
  elif have batcat; then
    run ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    ok "bat -> batcat"
  else
    warn "bat not installed"
  fi
}
