#!/usr/bin/env bash

group_info cli "gh lazygit lazydocker delta yq direnv claude eza xh fx dust btop atuin"

install_lazydocker() {
  brew_pkg lazydocker && return
  have lazydocker && {
    skip "lazydocker"
    return
  }
  run_sh 'curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash'
  ok "lazydocker"
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
  ensure_packages direnv
  release_bin gh cli/cli amd64/arm64 'v{v}/gh_{v}_{os}_{arch}.tar.gz' 'gh_{v}_{os}_{arch}/bin/gh'
  release_bin lazygit jesseduffield/lazygit x86_64/arm64 'v{v}/lazygit_{v}_{Os}_{arch}.tar.gz' lazygit
  install_lazydocker
  release_bin delta dandavison/delta x86_64/aarch64 '{v}/delta-{v}-{arch}-unknown-linux-gnu.tar.gz' 'delta-{v}-{arch}-unknown-linux-gnu/delta'
  release_bin yq mikefarah/yq amd64/arm64 'v{v}/yq_{os}_{arch}'
  release_bin eza eza-community/eza x86_64/aarch64 'v{v}/eza_{arch}-unknown-linux-gnu.tar.gz' eza
  release_bin xh ducaale/xh x86_64/aarch64 'v{v}/xh-v{v}-{arch}-unknown-linux-musl.tar.gz' 'xh-v{v}-{arch}-unknown-linux-musl/xh'
  release_bin fx antonmedv/fx amd64/arm64 '{v}/fx_{os}_{arch}'
  release_bin dust bootandy/dust x86_64/aarch64 'v{v}/dust-v{v}-{arch}-unknown-linux-musl.tar.gz' 'dust-v{v}-{arch}-unknown-linux-musl/dust'
  release_bin btop aristocratos/btop x86_64/aarch64 'v{v}/btop-{arch}-unknown-linux-musl.tar.gz' btop/bin/btop
  release_bin --check-runs atuin atuinsh/atuin x86_64/aarch64 'v{v}/atuin-{arch}-unknown-linux-musl.tar.gz' 'atuin-{arch}-unknown-linux-musl/atuin'
  install_claude
}
