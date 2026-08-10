#!/usr/bin/env bash

install_go() {
  local want a tmp
  a=$(arch_go); [ "$a" = unsupported ] && { warn "go: unsupported arch"; return; }
  local raw
  raw=$(fetch 'https://go.dev/VERSION?m=text') || { warn "go: version lookup failed"; return; }
  want=$(printf '%s\n' "$raw" | head -1)
  [ -n "$want" ] || { warn "go: version lookup failed"; return; }

  if have go && [ "$(go version | awk '{print $3}')" = "$want" ]; then
    skip "$want"
    return
  fi

  tmp=$(mktmp)
  run_sh "curl -fsSL -o '$tmp/go.tar.gz' 'https://go.dev/dl/${want}.$(os_name)-${a}.tar.gz'"
  sudo_run rm -rf /usr/local/go
  sudo_run tar -C /usr/local -xzf "$tmp/go.tar.gz"
  run rm -rf "$tmp"
  ok "$want in /usr/local/go"
}

install_node() {
  local want a tmp
  case "$(uname -m)" in
    x86_64|amd64)  a=x64 ;;
    aarch64|arm64) a=arm64 ;;
    *) warn "node: unsupported arch"; return ;;
  esac

  local index
  index=$(fetch https://nodejs.org/dist/index.json) || { warn "node: version lookup failed"; return; }
  if have jq; then
    want=$(printf '%s' "$index" | jq -r '[.[] | select(.lts != false)][0].version')
  else
    want=$(printf '%s' "$index" | sed -n 's/.*"version":"\([^"]*\)".*/\1/p' | head -1)
  fi
  [ -n "$want" ] && [ "$want" != null ] || { warn "node: version lookup failed"; return; }

  if have node && [ "$(node --version)" = "$want" ]; then
    skip "node $want"
    return
  fi

  tmp=$(mktmp)
  run_sh "curl -fsSL -o '$tmp/node.tar.xz' 'https://nodejs.org/dist/${want}/node-${want}-$(os_name)-${a}.tar.xz'"
  sudo_run rm -rf /usr/local/lib/nodejs
  sudo_run mkdir -p /usr/local/lib/nodejs
  sudo_run tar -xJf "$tmp/node.tar.xz" -C /usr/local/lib/nodejs --strip-components=1
  local b
  for b in node npm npx corepack; do
    sudo_run ln -sf "/usr/local/lib/nodejs/bin/$b" "/usr/local/bin/$b"
  done
  run rm -rf "$tmp"
  ok "node $want"
}

install_python() {
  ensure_packages python
  if have uv; then
    skip "uv"
  else
    run_sh 'curl -fsSL https://astral.sh/uv/install.sh | sh'
    ok "uv"
  fi
}

install_rust() {
  if have rustup || have cargo; then
    skip "rust"
    return
  fi
  run_sh 'curl -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path'
  ok "rust"
}

group_langs() {
  step "go"
  install_go
  step "node"
  install_node
  step "python"
  install_python
  step "rust"
  install_rust
}
