#!/usr/bin/env bash

install_gh() {
  have gh && { skip "gh"; return; }
  local v tmp a
  a=$(arch_go); [ "$a" = unsupported ] && { warn "gh: unsupported arch"; return; }
  v=$(latest_tag cli/cli) || { warn "gh: release lookup failed"; return; }
  tmp=$(mktmp)
  run_sh "curl -fsSL 'https://github.com/cli/cli/releases/download/v${v}/gh_${v}_$(os_name)_${a}.tar.gz' | tar xz -C '$tmp' --strip-components=1"
  install_bin "$tmp/bin/gh"
  run rm -rf "$tmp"
  ok "gh $v"
}

install_lazygit() {
  have lazygit && { skip "lazygit"; return; }
  local v tmp a o
  case "$(uname -m)" in
    x86_64|amd64)  a=x86_64 ;;
    aarch64|arm64) a=arm64 ;;
    *) warn "lazygit: unsupported arch"; return ;;
  esac
  case "$(os_name)" in linux) o=Linux ;; darwin) o=Darwin ;; *) return ;; esac
  v=$(latest_tag jesseduffield/lazygit) || { warn "lazygit: release lookup failed"; return; }
  tmp=$(mktmp)
  run_sh "curl -fsSL 'https://github.com/jesseduffield/lazygit/releases/download/v${v}/lazygit_${v}_${o}_${a}.tar.gz' | tar xz -C '$tmp' lazygit"
  install_bin "$tmp/lazygit"
  run rm -rf "$tmp"
  ok "lazygit $v"
}

install_lazydocker() {
  have lazydocker && { skip "lazydocker"; return; }
  run_sh 'curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash'
  ok "lazydocker"
}

install_delta() {
  have delta && { skip "delta"; return; }
  local v tmp a
  a=$(arch_uname); [ "$a" = unsupported ] && { warn "delta: unsupported arch"; return; }
  v=$(latest_tag dandavison/delta) || { warn "delta: release lookup failed"; return; }
  tmp=$(mktmp)
  run_sh "curl -fsSL 'https://github.com/dandavison/delta/releases/download/${v}/delta-${v}-${a}-unknown-linux-gnu.tar.gz' | tar xz -C '$tmp' --strip-components=1"
  install_bin "$tmp/delta"
  run rm -rf "$tmp"
  ok "delta $v"
}

install_yq() {
  have yq && { skip "yq"; return; }
  local v a tmp
  a=$(arch_go); [ "$a" = unsupported ] && { warn "yq: unsupported arch"; return; }
  v=$(latest_tag mikefarah/yq) || { warn "yq: release lookup failed"; return; }
  tmp=$(mktmp)
  run_sh "curl -fsSL -o '$tmp/yq' 'https://github.com/mikefarah/yq/releases/download/v${v}/yq_$(os_name)_${a}'"
  install_bin "$tmp/yq"
  run rm -rf "$tmp"
  ok "yq $v"
}

install_claude() {
  have claude && { skip "claude"; return; }
  run_sh 'curl -fsSL https://claude.ai/install.sh | bash'
  ok "claude"
}

group_cli() {
  step "cli tools"

  if [ "$PM" = brew ]; then
    ensure_packages gh lazygit lazydocker git-delta yq direnv
    install_claude
    return
  fi

  ensure_packages direnv
  install_gh
  install_lazygit
  install_lazydocker
  install_delta
  install_yq
  install_claude
}
