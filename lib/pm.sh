#!/usr/bin/env bash

PM=none
PM_REFRESHED=0

detect_pm() {
  if have apt-get;   then PM=apt;    return; fi
  if have pacman;    then PM=pacman; return; fi
  if have dnf;       then PM=dnf;    return; fi
  if have zypper;    then PM=zypper; return; fi
  if have apk;       then PM=apk;    return; fi
  if have brew;      then PM=brew;   return; fi
  PM=none
}

pm_refresh() {
  [ "$PM_REFRESHED" = 1 ] && return 0
  PM_REFRESHED=1
  case $PM in
    apt)    sudo_run apt-get update ;;
    pacman) sudo_run pacman -Sy --noconfirm ;;
    zypper) sudo_run zypper --non-interactive refresh ;;
    apk)    sudo_run apk update ;;
    brew)   run brew update ;;
    dnf)    : ;;
    none)   : ;;
  esac
}

pm_has() {
  case $PM in
    apt)          dpkg -s "$1" >/dev/null 2>&1 ;;
    pacman)       pacman -Q "$1" >/dev/null 2>&1 ;;
    dnf|zypper)   rpm -q "$1" >/dev/null 2>&1 ;;
    apk)          apk info -e "$1" >/dev/null 2>&1 ;;
    brew)         brew list --versions "$1" >/dev/null 2>&1 ;;
    none)         return 1 ;;
  esac
}

pm_install() {
  [ $# -eq 0 ] && return 0
  pm_refresh
  case $PM in
    apt)    sudo_run env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@" ;;
    pacman) sudo_run pacman -S --needed --noconfirm "$@" ;;
    dnf)    sudo_run dnf install -y "$@" ;;
    zypper) sudo_run zypper --non-interactive install "$@" ;;
    apk)    sudo_run apk add "$@" ;;
    brew)   run brew install "$@" ;;
    none)   die "no supported package manager found" ;;
  esac
}

ensure_packages() {
  local logical names name missing=()
  for logical in "$@"; do
    names=$(pkg_names "$logical")
    for name in $names; do
      pm_has "$name" || missing+=("$name")
    done
  done

  if [ ${#missing[@]} -eq 0 ]; then
    skip "packages present: $*"
    return 0
  fi

  pm_install "${missing[@]}"
  ok "installed: ${missing[*]}"
}
