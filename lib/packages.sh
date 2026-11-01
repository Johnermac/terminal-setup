#!/usr/bin/env bash

pkg_names() {
  case $1 in
    build)
      case $PM in
        apt) echo build-essential ;;
        pacman) echo base-devel ;;
        apk) echo build-base ;;
        brew) echo ;;
        *) echo gcc gcc-c++ make ;;
      esac
      ;;
    libevent)
      case $PM in
        apt | apk) echo libevent-dev ;;
        dnf | zypper) echo libevent-devel ;;
        *) echo libevent ;;
      esac
      ;;
    ncurses)
      case $PM in
        apt) echo libncurses-dev ;;
        apk) echo ncurses-dev ;;
        dnf | zypper) echo ncurses-devel ;;
        *) echo ncurses ;;
      esac
      ;;
    pkg-config)
      case $PM in
        pacman | apk) echo pkgconf ;;
        dnf) echo pkgconf-pkg-config ;;
        *) echo pkg-config ;;
      esac
      ;;
    fd)
      case $PM in apt | dnf) echo fd-find ;; *) echo fd ;; esac
      ;;
    python)
      case $PM in
        apt) echo python3 python3-pip python3-venv ;;
        pacman) echo python ;;
        apk) echo python3 py3-pip ;;
        brew) echo python ;;
        *) echo python3 python3-pip ;;
      esac
      ;;
    dnsutils)
      case $PM in
        apt) echo dnsutils ;;
        pacman) echo bind ;;
        apk) echo bind-tools ;;
        brew) echo bind ;;
        *) echo bind-utils ;;
      esac
      ;;
    netcat)
      case $PM in
        apt | zypper) echo netcat-openbsd ;;
        pacman) echo openbsd-netcat ;;
        dnf) echo nmap-ncat ;;
        apk) echo netcat-openbsd ;;
        brew) echo netcat ;;
      esac
      ;;
    mtr)
      case $PM in apt) echo mtr-tiny ;; *) echo mtr ;; esac
      ;;
    java)
      case $PM in
        apt) echo default-jdk ;;
        pacman) echo jdk-openjdk ;;
        dnf) echo java-latest-openjdk-devel ;;
        zypper) echo java-openjdk-devel ;;
        apk) echo openjdk21 ;;
        brew) echo openjdk ;;
      esac
      ;;
    ca-certificates)
      case $PM in brew) echo ;; *) echo ca-certificates ;; esac
      ;;
    delta)
      case $PM in brew | pacman) echo git-delta ;; *) echo delta ;; esac
      ;;
    gh)
      case $PM in pacman) echo github-cli ;; *) echo gh ;; esac
      ;;
    yq)
      case $PM in pacman) echo go-yq ;; *) echo yq ;; esac
      ;;
    awscli)
      case $PM in pacman) echo aws-cli-v2 ;; *) echo awscli ;; esac
      ;;
    kubectl)
      case $PM in brew) echo kubernetes-cli ;; *) echo kubectl ;; esac
      ;;
    terraform)
      case $PM in brew) echo ;; *) echo terraform ;; esac
      ;;
    hadolint | granted)
      case $PM in pacman) echo ;; *) echo "$1" ;; esac
      ;;
    *)
      echo "$1"
      ;;
  esac
}
