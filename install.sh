#!/bin/bash
set -euo pipefail
envybash_git_location=https://github.com/forkfoundinkitchenn/envybash.git

o_log() {
  echo "[*] $@"
}
e_log() {
  echo "[-] $@" >&2
}

while getopts ":l:" flag; do
  case "$flag" in
    l)
      if [[ ! -z $OPTARG ]]; then
        envybash_git_location=$OPTARG
      fi
      ;;
  esac
done

if [[ $# -ge 0 ]]; then
fi

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
    answer="null"

    while [[ $answer = "null" ]]; do
      read -r -p '[Y/n] ' answer
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
        if [[ -z $answer ]]; then
          break
        else
          answer="null"
        fi
        ;;
      esac
    done
    shopt -u nocasematch
  fi

  rm -rf $envybash_home
  rm -f $envybash_binary

  git clone $envybash_git_location $envybash_home
  ln -sf $envybash_home/main.sh $envybash_binary
  o_log "installed envybash into $envybash_home and $envybash_binary"
}

install
