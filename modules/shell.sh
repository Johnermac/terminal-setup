#!/usr/bin/env bash

group_info shell "fish tmux fzf starship zoxide"

FZF_MIN_VERSION=0.48.0

group_shell() {
  step "fish + tmux"
  ensure_packages fish tmux

  step "fzf >= $FZF_MIN_VERSION"
  local current=""
  have fzf && current=$(fzf --version 2>/dev/null | awk '{print $1}')

  if [ -n "$current" ] && version_ge "$current" "$FZF_MIN_VERSION"; then
    skip "fzf $current"
  else
    ensure_packages fzf
    current=$(fzf --version 2>/dev/null | awk '{print $1}' || echo 0)
    if ! version_ge "${current:-0}" "$FZF_MIN_VERSION"; then
      warn "packaged fzf is ${current:-absent}; building from source"
      if [ -d "$HOME/.fzf" ]; then
        run git -C "$HOME/.fzf" pull --ff-only
      else
        run git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
      fi
      run "$HOME/.fzf/install" --bin
      sudo_run cp "$HOME/.fzf/bin/fzf" /usr/local/bin/
      ok "fzf built from source"
    fi
  fi

  step "starship"
  if have starship; then
    skip "$(starship --version 2>/dev/null | head -1)"
  else
    run_sh 'curl -fsSL https://starship.rs/install.sh | sh -s -- -y'
    ok "starship"
  fi

  step "zoxide"
  if have zoxide; then
    skip "$(zoxide --version 2>/dev/null)"
  else
    run_sh 'curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh'
    ok "zoxide"
  fi
}
