#!/usr/bin/env bash

link_dotfiles() {
  if [ -f "$HOME/.config/fish/local.fish" ]; then
    skip "~/.config/fish/local.fish"
  else
    run mkdir -p "$HOME/.config/fish"
    run touch "$HOME/.config/fish/local.fish"
    ok "created ~/.config/fish/local.fish"
  fi

  link "$REPO_DIR/config/fish/config.fish"  "$HOME/.config/fish/config.fish"
  link "$REPO_DIR/config/fish/fish_plugins" "$HOME/.config/fish/fish_plugins"

  local f
  for f in "$REPO_DIR"/config/fish/conf.d/*.fish; do
    link "$f" "$HOME/.config/fish/conf.d/$(basename "$f")"
  done
  for f in "$REPO_DIR"/config/fish/functions/*.fish; do
    link "$f" "$HOME/.config/fish/functions/$(basename "$f")"
  done

  link "$REPO_DIR/config/starship.toml"      "$HOME/.config/starship.toml"
  link "$REPO_DIR/config/tmux/tmux.conf"     "$HOME/.tmux.conf"
  link "$REPO_DIR/config/bin/tmux-git-title" "$HOME/.local/bin/tmux-git-title"
  link "$REPO_DIR/config/git/config.inc"     "$HOME/.config/git/terminal-setup.inc"
  run chmod +x "$REPO_DIR/config/bin/tmux-git-title"
}

link_gitconfig() {
  local inc="$HOME/.config/git/terminal-setup.inc"
  if git config --global --get-all include.path 2>/dev/null | grep -qx "$inc"; then
    skip "git include.path"
  else
    run git config --global --add include.path "$inc"
    ok "git include.path -> $inc"
  fi
}

install_fisher() {
  have fish || { warn "fish not installed"; return; }

  if [ -f "$HOME/.config/fish/functions/fisher.fish" ]; then
    skip "fisher"
  else
    run fish -c 'curl -fsSL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher'
    ok "fisher"
  fi

  run fish -c 'fisher update'
  ok "fish plugins synced"
}

install_tpm() {
  have tmux || { warn "tmux not installed"; return; }

  if [ -d "$HOME/.tmux/plugins/tpm" ]; then
    skip "tpm"
  else
    run git clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    ok "tpm"
  fi

  run tmux new-session -d -s tpm-install
  run tmux run-shell "$HOME/.tmux/plugins/tpm/bindings/install_plugins"
  run tmux kill-session -t tpm-install
  ok "tmux plugins"
}

set_default_shell() {
  [ "$SKIP_CHSH" = 1 ] && { skip "--skip-chsh"; return; }

  local fish_path
  fish_path=$(command -v fish) || { warn "fish not installed"; return; }

  if [ "${SHELL:-}" = "$fish_path" ]; then
    skip "login shell is fish"
    return
  fi

  grep -qxF "$fish_path" /etc/shells 2>/dev/null || \
    sudo_run sh -c "echo '$fish_path' >> /etc/shells"

  if run chsh -s "$fish_path"; then
    ok "login shell set to fish"
  else
    warn "chsh failed; run: chsh -s $fish_path"
  fi
}

group_config() {
  step "dotfiles"
  link_dotfiles
  link_gitconfig
  step "fish plugins"
  install_fisher
  step "tmux plugins"
  install_tpm
  step "default shell"
  set_default_shell
}
