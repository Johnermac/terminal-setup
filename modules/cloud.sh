#!/usr/bin/env bash

install_docker() {
  if have docker; then
    skip "$(docker --version 2>/dev/null)"
  else
    case $PM in
      pacman) ensure_packages docker docker-compose ;;
      apk) ensure_packages docker docker-cli-compose ;;
      brew) run brew install --cask docker ;;
      *) run_sh 'curl -fsSL https://get.docker.com | sh' ;;
    esac
    ok "docker"
  fi

  [ "$(os_name)" = linux ] || return 0

  if id -nG "$USER" 2>/dev/null | tr ' ' '\n' | grep -qx docker; then
    skip "$USER in docker group"
  else
    sudo_run usermod -aG docker "$USER"
    warn "added $USER to docker group; log out and back in to take effect"
  fi

  if [ -d /run/systemd/system ]; then
    sudo_run systemctl enable --now docker
  elif is_wsl; then
    warn "no systemd; start docker with: sudo service docker start"
  fi
}

install_kubectl() {
  have kubectl && {
    skip "kubectl"
    return
  }
  local v a tmp
  a=$(arch_go)
  [ "$a" = unsupported ] && {
    warn "kubectl: unsupported arch"
    return
  }
  v=$(fetch https://dl.k8s.io/release/stable.txt) || {
    warn "kubectl: version lookup failed"
    return
  }
  tmp=$(mktmp)
  run_sh "curl -fsSL -o '$tmp/kubectl' 'https://dl.k8s.io/release/${v}/bin/$(os_name)/${a}/kubectl'"
  install_bin "$tmp/kubectl"
  run rm -rf "$tmp"
  ok "kubectl $v"
}

install_helm() {
  have helm && {
    skip "helm"
    return
  }
  run_sh 'curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash'
  ok "helm"
}

install_k9s() {
  have k9s && {
    skip "k9s"
    return
  }
  local v a o tmp
  case "$(uname -m)" in
    x86_64 | amd64) a=amd64 ;;
    aarch64 | arm64) a=arm64 ;;
    *)
      warn "k9s: unsupported arch"
      return
      ;;
  esac
  case "$(os_name)" in linux) o=Linux ;; darwin) o=Darwin ;; *) return ;; esac
  v=$(latest_tag derailed/k9s) || {
    warn "k9s: release lookup failed"
    return
  }
  tmp=$(mktmp)
  run_sh "curl -fsSL 'https://github.com/derailed/k9s/releases/download/v${v}/k9s_${o}_${a}.tar.gz' | tar xz -C '$tmp' k9s"
  install_bin "$tmp/k9s"
  run rm -rf "$tmp"
  ok "k9s $v"
}

install_terraform() {
  have terraform && {
    skip "terraform"
    return
  }
  local v a tmp
  a=$(arch_go)
  [ "$a" = unsupported ] && {
    warn "terraform: unsupported arch"
    return
  }
  v=$(fetch https://checkpoint-api.hashicorp.com/v1/check/terraform | grep -o '"current_version":"[^"]*"' | cut -d'"' -f4)
  [ -n "$v" ] || {
    warn "terraform: version lookup failed"
    return
  }
  tmp=$(mktmp)
  run_sh "curl -fsSL -o '$tmp/tf.zip' 'https://releases.hashicorp.com/terraform/${v}/terraform_${v}_$(os_name)_${a}.zip'"
  run unzip -qo "$tmp/tf.zip" -d "$tmp"
  install_bin "$tmp/terraform"
  run rm -rf "$tmp"
  ok "terraform $v"
}

install_awscli() {
  have aws && {
    skip "aws"
    return
  }
  if [ "$PM" = brew ]; then
    ensure_packages awscli
    return
  fi
  local a tmp
  a=$(arch_uname)
  [ "$a" = unsupported ] && {
    warn "aws: unsupported arch"
    return
  }
  tmp=$(mktmp)
  run_sh "curl -fsSL -o '$tmp/aws.zip' 'https://awscli.amazonaws.com/awscli-exe-linux-${a}.zip'"
  run unzip -qo "$tmp/aws.zip" -d "$tmp"
  sudo_run "$tmp/aws/install" --update
  run rm -rf "$tmp"
  ok "aws"
}

group_cloud() {
  step "docker"
  install_docker
  step "kubernetes"
  install_kubectl
  install_helm
  install_k9s
  step "infrastructure"
  install_terraform
  install_awscli
}
