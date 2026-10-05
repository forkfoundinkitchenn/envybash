#!/bin/bash
set -euo pipefail
envybash_home=/etc/envybash

o_log() {
  echo "[*] $@"
}
e_log() {
  echo "[-] $@" >&2
}

local_install() {
  o_log "installing for the current user.."
  envybash_home=~/.local/share/envybash

  if [[ -e /etc/envybash/ ]]; then
    e_log "envybash is already installed system-wide"
    exit 1
  elif [[ -e $envybash_home ]]; then
    o_log "envybash is already installed for your user, do you wanna overwrite it?"
    read -p "[Y/n] " answer
    shopt -s nocasematch

    if [[ $answer = "n" ]]; then
      o_log "aborting.."
      exit 1
    fi

    o_log "overwriting"
    rm -rf $envybash_home
    rm -f ~/.local/bin/envybash
  fi

  git clone https://github.com/forkfoundinkitchenn/envybash.git $envybash_home
  chmod +x $envybash_home/main.sh
  ln -s $envybash_home/main.sh ~/.local/bin
  o_log "installed envybash in $envybash_home"
  exit 0
}

global_install() {
  o_log "installing for all users.."

  if [[ -e $envybash_home ]]; then
    o_log "envybash is already installed onto your system, do you wanna overwrite it?"
    read -p "[Y/n] " answer
    shopt -s nocasematch

    if [[ $answer = "n" ]]; then
      o_log "aborting.."
      exit 1
    fi

    o_log "overwriting.."
    rm -rf $envybash_home
    rm -f /usr/bin/envybash
  fi
  git clone https://github.com/forkfoundinkitchenn/envybash.git $envybash_home
  chmod +x $envybash_home/main.sh
  ln -s $envybash_home/main.sh /usr/bin/envybash
  o_log "installed envybash in $envybash_home"
  exit 0
}

if [[ $EUID -ne 0 ]]; then
  local_install
else
  global_install
fi
