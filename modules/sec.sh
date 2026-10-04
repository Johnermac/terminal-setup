#!/usr/bin/env bash

group_info sec "nmap tcpdump dig whois socat openssl trivy grype syft gitleaks hadolint cosign semgrep checkov detect-secrets"

install_trivy() {
  brew_pkg trivy && return
  have trivy && {
    skip "trivy"
    return
  }
  run_sh 'curl -fsSL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin'
  ok "trivy"
}

install_anchore() {
  local tool=$1
  brew_pkg "$tool" && return
  have "$tool" && {
    skip "$tool"
    return
  }
  run_sh "curl -fsSL https://raw.githubusercontent.com/anchore/${tool}/main/install.sh | sudo sh -s -- -b /usr/local/bin"
  ok "$tool"
}

install_uv_tool() {
  local tool=$1
  have "$tool" && {
    skip "$tool"
    return
  }
  have uv || {
    warn "$tool: needs uv (run the langs group first)"
    return
  }
  run uv tool install "$tool"
  ok "$tool"
}

group_sec() {
  step "network and analysis tools"
  ensure_packages nmap tcpdump dnsutils whois socat netcat openssl mtr

  step "supply chain scanners"
  install_trivy
  install_anchore grype
  install_anchore syft

  step "secrets and lint"
  release_bin gitleaks gitleaks/gitleaks x64/arm64 'v{v}/gitleaks_{v}_{os}_{arch}.tar.gz' gitleaks
  release_bin hadolint hadolint/hadolint x86_64/aarch64 'v{v}/hadolint-{Os}-{arch}'
  release_bin cosign sigstore/cosign amd64/arm64 'v{v}/cosign-{os}-{arch}'

  step "python security tooling"
  install_uv_tool semgrep
  install_uv_tool checkov
  install_uv_tool detect-secrets
}
