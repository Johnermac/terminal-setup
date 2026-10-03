#!/usr/bin/env bash

group_ruby() {
  step "rbenv"
  local root="$HOME/.rbenv"

  if [ -d "$root/.git" ]; then
    run git -C "$root" pull --ff-only
  else
    run git clone --depth 1 https://github.com/rbenv/rbenv.git "$root"
  fi

  if [ -d "$root/plugins/ruby-build/.git" ]; then
    run git -C "$root/plugins/ruby-build" pull --ff-only
  else
    run git clone --depth 1 https://github.com/rbenv/ruby-build.git "$root/plugins/ruby-build"
  fi
  ok "rbenv"

  export PATH="$root/bin:$PATH"
  have rbenv || {
    warn "rbenv not on PATH"
    return
  }

  local latest
  latest=$(rbenv install -l 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | tail -1)
  [ -n "$latest" ] || {
    warn "could not resolve latest ruby"
    return
  }

  if rbenv versions --bare 2>/dev/null | grep -qx "$latest"; then
    skip "ruby $latest"
  else
    warn "compiling ruby $latest (several minutes)"
    run rbenv install -s "$latest"
    run rbenv global "$latest"
    ok "ruby $latest"
  fi
}

group_java() {
  step "java"
  ensure_packages java maven
}

group_gcloud() {
  step "gcloud"
  if have gcloud; then
    skip "gcloud"
    return
  fi
  run_sh "curl -fsSL https://sdk.cloud.google.com | bash -s -- --disable-prompts --install-dir='$HOME'"
  ok "gcloud in $HOME/google-cloud-sdk"
}
