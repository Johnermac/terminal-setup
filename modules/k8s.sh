#!/usr/bin/env bash

group_info k8s "kubectl helm k9s"

install_kubectl() {
  native_pkg kubectl && return
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
  native_pkg helm && return
  have helm && {
    skip "helm"
    return
  }
  run_sh 'curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash'
  ok "helm"
}

group_k8s() {
  step "kubernetes"
  install_kubectl
  install_helm
  release_bin k9s derailed/k9s amd64/arm64 'v{v}/k9s_{Os}_{arch}.tar.gz' k9s
}
