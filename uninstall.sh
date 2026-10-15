#!/bin/bash
set -euo pipefail
current_directory=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
source $current_directory/helper-functions.sh

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
