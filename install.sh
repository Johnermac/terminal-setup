#!/usr/bin/env bash
set -euo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
export REPO_DIR

. "$REPO_DIR/lib/common.sh"
. "$REPO_DIR/lib/pm.sh"
. "$REPO_DIR/lib/packages.sh"

for m in "$REPO_DIR"/modules/*.sh; do . "$m"; done

DEFAULT_GROUPS="base shell cli langs cloud sec config"
OPTIONAL_GROUPS="pentest wordlists ruby java gcloud tmux-boxes"
SKIP_CHSH=0
GROUP_LIST=$DEFAULT_GROUPS
WITH=""
WITHOUT=""

usage() {
  cat <<USAGE
usage: ./install.sh [options]

  --dry-run          print commands instead of running them
  --groups a,b,c     run exactly these groups
  --with a,b         add optional groups
  --without a,b      drop groups from the default set
  --skip-chsh        leave the login shell alone
  --list             show groups and exit
  -h, --help         this text

default:  $DEFAULT_GROUPS
optional: $OPTIONAL_GROUPS
USAGE
}

list_groups() {
  cat <<LIST
base      git curl wget unzip jq tree htop vim ripgrep fd bat build toolchain
shell     fish tmux fzf starship zoxide
cli       gh lazygit lazydocker delta yq direnv claude
langs     go node python uv rust
cloud     docker kubectl helm k9s terraform aws
sec       nmap tcpdump dig whois socat openssl trivy grype syft gitleaks
          hadolint cosign semgrep checkov detect-secrets
config    dotfile symlinks, fisher, tpm, default shell

pentest   ffuf gobuster httpx subfinder nuclei katana dnsx assetfinder
          waybackurls sqlmap
wordlists SecLists (~1 GB)
ruby      rbenv, ruby-build, latest stable ruby
java      jdk, maven
gcloud    google cloud sdk
tmux-boxes patched tmux 3.7b with rounded per-pane border boxes
LIST
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --groups)
      GROUP_LIST=$(echo "$2" | tr ',' ' ')
      shift
      ;;
    --with)
      WITH=$(echo "$2" | tr ',' ' ')
      shift
      ;;
    --without)
      WITHOUT=$(echo "$2" | tr ',' ' ')
      shift
      ;;
    --skip-chsh) SKIP_CHSH=1 ;;
    --list)
      list_groups
      exit 0
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      die "unknown option: $1"
      ;;
  esac
  shift
done
export DRY_RUN SKIP_CHSH

resolve_groups() {
  local g out=""
  for g in $GROUP_LIST $WITH; do
    case " $WITHOUT " in *" $g "*) continue ;; esac
    case " $out " in *" $g "*) continue ;; esac
    out="$out $g"
  done
  echo "$out"
}

verify() {
  step "verify"
  local absent="" cmd
  for cmd in fish tmux starship zoxide fzf fd bat git rg jq; do
    have "$cmd" || absent="$absent $cmd"
  done
  if [ -n "$absent" ]; then
    warn "missing:$absent"
  else
    ok "core tools present"
  fi
}

main() {
  [ "$DRY_RUN" = 1 ] && warn "dry run"

  detect_pm
  [ "$PM" = none ] && die "no supported package manager (apt, pacman, dnf, zypper, apk, brew)"
  [ "$(os_name)" = unsupported ] && die "unsupported OS: $(uname -s)"

  local selected
  selected=$(resolve_groups)
  step "$PM on $(os_name)/$(arch_go), groups:$selected"

  local g
  for g in $selected; do
    if ! declare -f "group_$g" >/dev/null; then
      die "unknown group: $g (see --list)"
    fi
    "group_$g"
  done

  verify

  printf '\n%sdone.%s\n\n' "$C_GREEN" "$C_RESET"
  printf 'font: scripts/install-font.sh, then select JetBrainsMono Nerd Font in your terminal emulator\n'
  printf 'start: exec fish && tmux new -s test\n'
}

main "$@"
