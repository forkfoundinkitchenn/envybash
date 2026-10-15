#!/bin/bash
set -euo pipefail
o_log() {
  echo "[*] $@"
}

e_log() {
  echo "[-] $@" >&2
}

if_root() {
  if [[ $EUID -ne 0 ]]; then
    e_log "run this command with elevated permissions"
    exit 1
  fi
}

uninstall() {
  if [[ -e /etc/envybash ]]; then
    if_root
    envybash_home=/etc/envybash
    envybash_binary=/usr/bin/envybash
  elif [[ -e $HOME/.local/share/envybash ]]; then
    envybash_home=$HOME/.local/share/envybash
    envybash_binary=$HOME/.local/bin/envybash
  fi

  rm -rf $envybash_home
  o_log "removed $envybash_home"
  rm -f $envybash_binary
  o_log "removed $envybash_binary"
}

uninstall
