#!/usr/bin/env bash

install_gh() {
  have gh && {
    skip "gh"
    return
  }
  local v tmp a
  a=$(arch_go)
  [ "$a" = unsupported ] && {
    warn "gh: unsupported arch"
    return
  }
  v=$(latest_tag cli/cli) || {
    warn "gh: release lookup failed"
    return
  }
  tmp=$(mktmp)
  run_sh "curl -fsSL 'https://github.com/cli/cli/releases/download/v${v}/gh_${v}_$(os_name)_${a}.tar.gz' | tar xz -C '$tmp' --strip-components=1"
  install_bin "$tmp/bin/gh"
  run rm -rf "$tmp"
  ok "gh $v"
}

install_lazygit() {
  have lazygit && {
    skip "lazygit"
    return
  }
  local v tmp a o
  case "$(uname -m)" in
    x86_64 | amd64) a=x86_64 ;;
    aarch64 | arm64) a=arm64 ;;
    *)
      warn "lazygit: unsupported arch"
      return
      ;;
  esac
  case "$(os_name)" in linux) o=Linux ;; darwin) o=Darwin ;; *) return ;; esac
  v=$(latest_tag jesseduffield/lazygit) || {
    warn "lazygit: release lookup failed"
    return
  }
  tmp=$(mktmp)
  run_sh "curl -fsSL 'https://github.com/jesseduffield/lazygit/releases/download/v${v}/lazygit_${v}_${o}_${a}.tar.gz' | tar xz -C '$tmp' lazygit"
  install_bin "$tmp/lazygit"
  run rm -rf "$tmp"
  ok "lazygit $v"
}

install_lazydocker() {
  have lazydocker && {
    skip "lazydocker"
    return
  }
  run_sh 'curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash'
  ok "lazydocker"
}

install_delta() {
  have delta && {
    skip "delta"
    return
  }
  local v tmp a
  a=$(arch_uname)
  [ "$a" = unsupported ] && {
    warn "delta: unsupported arch"
    return
  }
  v=$(latest_tag dandavison/delta) || {
    warn "delta: release lookup failed"
    return
  }
  tmp=$(mktmp)
  run_sh "curl -fsSL 'https://github.com/dandavison/delta/releases/download/${v}/delta-${v}-${a}-unknown-linux-gnu.tar.gz' | tar xz -C '$tmp' --strip-components=1"
  install_bin "$tmp/delta"
  run rm -rf "$tmp"
  ok "delta $v"
}

install_yq() {
  have yq && {
    skip "yq"
    return
  }
  local v a tmp
  a=$(arch_go)
  [ "$a" = unsupported ] && {
    warn "yq: unsupported arch"
    return
  }
  v=$(latest_tag mikefarah/yq) || {
    warn "yq: release lookup failed"
    return
  }
  tmp=$(mktmp)
  run_sh "curl -fsSL -o '$tmp/yq' 'https://github.com/mikefarah/yq/releases/download/v${v}/yq_$(os_name)_${a}'"
  install_bin "$tmp/yq"
  run rm -rf "$tmp"
  ok "yq $v"
}

install_eza() {
  have eza && {
    skip "eza"
    return
  }
  local v a
  a=$(arch_uname)
  [ "$a" = unsupported ] && {
    warn "eza: unsupported arch"
    return
  }
  v=$(latest_tag eza-community/eza) || {
    warn "eza: release lookup failed"
    return
  }
  install_tar_bins "https://github.com/eza-community/eza/releases/download/v${v}/eza_${a}-unknown-linux-gnu.tar.gz" eza
  ok "eza $v"
}

install_xh() {
  have xh && {
    skip "xh"
    return
  }
  local v a
  a=$(arch_uname)
  [ "$a" = unsupported ] && {
    warn "xh: unsupported arch"
    return
  }
  v=$(latest_tag ducaale/xh) || {
    warn "xh: release lookup failed"
    return
  }
  install_tar_bins "https://github.com/ducaale/xh/releases/download/v${v}/xh-v${v}-${a}-unknown-linux-musl.tar.gz" "xh-v${v}-${a}-unknown-linux-musl/xh"
  ok "xh $v"
}

install_fx() {
  have fx && {
    skip "fx"
    return
  }
  local v a tmp
  a=$(arch_go)
  [ "$a" = unsupported ] && {
    warn "fx: unsupported arch"
    return
  }
  v=$(latest_tag antonmedv/fx) || {
    warn "fx: release lookup failed"
    return
  }
  tmp=$(mktmp)
  run_sh "curl -fsSL -o '$tmp/fx' 'https://github.com/antonmedv/fx/releases/download/${v}/fx_$(os_name)_${a}'"
  install_bin "$tmp/fx"
  run rm -rf "$tmp"
  ok "fx $v"
}

install_dust() {
  have dust && {
    skip "dust"
    return
  }
  local v a
  a=$(arch_uname)
  [ "$a" = unsupported ] && {
    warn "dust: unsupported arch"
    return
  }
  v=$(latest_tag bootandy/dust) || {
    warn "dust: release lookup failed"
    return
  }
  install_tar_bins "https://github.com/bootandy/dust/releases/download/v${v}/dust-v${v}-${a}-unknown-linux-musl.tar.gz" "dust-v${v}-${a}-unknown-linux-musl/dust"
  ok "dust $v"
}

install_btop() {
  have btop && {
    skip "btop"
    return
  }
  local v a
  a=$(arch_uname)
  [ "$a" = unsupported ] && {
    warn "btop: unsupported arch"
    return
  }
  v=$(latest_tag aristocratos/btop) || {
    warn "btop: release lookup failed"
    return
  }
  install_tar_bins "https://github.com/aristocratos/btop/releases/download/v${v}/btop-${a}-unknown-linux-musl.tar.gz" btop/bin/btop
  ok "btop $v"
}

install_atuin() {
  atuin --version >/dev/null 2>&1 && {
    skip "atuin"
    return
  }
  local v a
  a=$(arch_uname)
  [ "$a" = unsupported ] && {
    warn "atuin: unsupported arch"
    return
  }
  v=$(latest_tag atuinsh/atuin) || {
    warn "atuin: release lookup failed"
    return
  }
  install_tar_bins "https://github.com/atuinsh/atuin/releases/download/v${v}/atuin-${a}-unknown-linux-musl.tar.gz" "atuin-${a}-unknown-linux-musl/atuin"
  ok "atuin $v"
}

install_claude() {
  have claude && {
    skip "claude"
    return
  }
  run_sh 'curl -fsSL https://claude.ai/install.sh | bash'
  ok "claude"
}

group_cli() {
  step "cli tools"

  if [ "$PM" = brew ]; then
    ensure_packages gh lazygit lazydocker git-delta yq direnv eza xh fx dust btop atuin
    install_claude
    return
  fi

  ensure_packages direnv
  install_gh
  install_lazygit
  install_lazydocker
  install_delta
  install_yq
  install_eza
  install_xh
  install_fx
  install_dust
  install_btop
  install_atuin
  install_claude
}
