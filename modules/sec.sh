#!/usr/bin/env bash

install_trivy() {
  have trivy && { skip "trivy"; return; }
  run_sh 'curl -fsSL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin'
  ok "trivy"
}

install_anchore() {
  local tool=$1 repo=$2
  have "$tool" && { skip "$tool"; return; }
  run_sh "curl -fsSL https://raw.githubusercontent.com/anchore/${repo}/main/install.sh | sudo sh -s -- -b /usr/local/bin"
  ok "$tool"
}

install_gitleaks() {
  have gitleaks && { skip "gitleaks"; return; }
  local v a o tmp
  case "$(uname -m)" in
    x86_64|amd64)  a=x64 ;;
    aarch64|arm64) a=arm64 ;;
    *) warn "gitleaks: unsupported arch"; return ;;
  esac
  case "$(os_name)" in linux) o=linux ;; darwin) o=darwin ;; *) return ;; esac
  v=$(latest_tag gitleaks/gitleaks) || { warn "gitleaks: release lookup failed"; return; }
  tmp=$(mktmp)
  run_sh "curl -fsSL 'https://github.com/gitleaks/gitleaks/releases/download/v${v}/gitleaks_${v}_${o}_${a}.tar.gz' | tar xz -C '$tmp' gitleaks"
  install_bin "$tmp/gitleaks"
  run rm -rf "$tmp"
  ok "gitleaks $v"
}

install_hadolint() {
  have hadolint && { skip "hadolint"; return; }
  local v a tmp
  a=$(arch_uname); [ "$a" = unsupported ] && { warn "hadolint: unsupported arch"; return; }
  v=$(latest_tag hadolint/hadolint) || { warn "hadolint: release lookup failed"; return; }
  tmp=$(mktmp)
  run_sh "curl -fsSL -o '$tmp/hadolint' 'https://github.com/hadolint/hadolint/releases/download/v${v}/hadolint-$(uname -s)-${a}'"
  install_bin "$tmp/hadolint"
  run rm -rf "$tmp"
  ok "hadolint $v"
}

install_cosign() {
  have cosign && { skip "cosign"; return; }
  local v a tmp
  a=$(arch_go); [ "$a" = unsupported ] && { warn "cosign: unsupported arch"; return; }
  v=$(latest_tag sigstore/cosign) || { warn "cosign: release lookup failed"; return; }
  tmp=$(mktmp)
  run_sh "curl -fsSL -o '$tmp/cosign' 'https://github.com/sigstore/cosign/releases/download/v${v}/cosign-$(os_name)-${a}'"
  install_bin "$tmp/cosign"
  run rm -rf "$tmp"
  ok "cosign $v"
}

install_uv_tool() {
  local tool=$1 pkg=$2
  have "$tool" && { skip "$tool"; return; }
  have uv || { warn "$tool: needs uv (run the langs group first)"; return; }
  run uv tool install "$pkg"
  ok "$tool"
}

group_sec() {
  step "network and analysis tools"
  ensure_packages nmap tcpdump dnsutils whois socat netcat openssl mtr

  if [ "$PM" = brew ]; then
    ensure_packages trivy grype syft gitleaks hadolint cosign
  else
    step "supply chain scanners"
    install_trivy
    install_anchore grype grype
    install_anchore syft syft
    step "secrets and lint"
    install_gitleaks
    install_hadolint
    install_cosign
  fi

  step "python security tooling"
  install_uv_tool semgrep semgrep
  install_uv_tool checkov checkov
  install_uv_tool detect-secrets detect-secrets
}
