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
  o_log "this script only works if you installed envybash into the directories from install.sh"
  if_root
  envybash_home={/etc/envybash,$HOME/.local/share/envybash}
  envybash_binary={/usr/bin/envybash,$HOME/.local/bin/envybash}
  rm -rf "$envybash_home"
  o_log "removed $envybash_home"
  rm -f "$envybash_binary"
  o_log "removed $envybash_binary"
  o_log "complete"
}

uninstall
