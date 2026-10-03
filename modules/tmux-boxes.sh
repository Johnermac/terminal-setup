#!/usr/bin/env bash

TMUX_BOXES_TAG=3.7b

install_tmux_boxes() {
  local patch="$REPO_DIR/patches/tmux-$TMUX_BOXES_TAG-border-boxes.patch"
  local stamp="$HOME/.local/share/terminal-setup/tmux-boxes.stamp"
  local want src
  want="$TMUX_BOXES_TAG $(git hash-object "$patch")"

  if [ -x "$HOME/.local/bin/tmux" ] && [ "$(cat "$stamp" 2>/dev/null)" = "$want" ]; then
    skip "tmux $TMUX_BOXES_TAG with border boxes"
    return
  fi

  warn "compiling tmux $TMUX_BOXES_TAG (about a minute)"
  src=$(mktmp)
  run git clone --depth 1 --branch "$TMUX_BOXES_TAG" https://github.com/tmux/tmux.git "$src/tmux"
  run git -C "$src/tmux" apply "$patch"
  run sh -c "cd '$src/tmux' && sh autogen.sh && ./configure --prefix='$HOME/.local' && make -j$(getconf _NPROCESSORS_ONLN) && make install"
  run mkdir -p "$(dirname "$stamp")"
  run sh -c "echo '$want' > '$stamp'"
  run rm -rf "$src"
  ok "tmux $TMUX_BOXES_TAG with border boxes -> ~/.local/bin/tmux"
}

group_tmux-boxes() {
  step "tmux border boxes"
  ensure_packages build autoconf automake bison pkg-config libevent ncurses
  install_tmux_boxes
}
