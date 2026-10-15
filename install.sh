#!/bin/bash
set -euo pipefail

o_log() {
  echo "[*] $@"
}
e_log() {
  echo "[-] $@" >&2
}

install() {
  if [[ $EUID -ne 0 ]]; then
    envybash_home=$HOME/.local/share/envybash
    envybash_binary=$HOME/.local/bin/envybash
  else
    envybash_home=/etc/envybash
    envybash_binary=/usr/bin/envybash
  fi

  if [[ -e $envybash_home ]]; then
    o_log "envybash appears to already be installed, overwrite?"
    answer=""

    while [ -z $answer ]; do
      read -r -p '[y/n] ' answer
      shopt -s nocasematch
      case "$answer" in
      "n" | "no")
        o_log "aborting"
        exit 1
        ;;
      "y" | "yes")
        answer="yes"
        ;;
      *)
        answer=""
        ;;
      esac
    done
    shopt -u nocasematch
  fi

  git clone /home/juneforkazoid/Projects/envybash $envybash_home
  ln -sf $envybash_home/main.sh $envybash_binary
  o_log "installed envybash into $envybash_home and $envybash_binary"
}

install
