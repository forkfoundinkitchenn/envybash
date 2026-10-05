#!/bin/bash
set -euo pipefail
envybash_home=/etc/envybash

o_log() {
  echo "[*] $@"
}
e_log() {
  echo "[-] $@" >&2
}

if [[ $EUID -ne 0 ]]; then
  echo "[-] the installer needs to be ran as root, or you can set it up manually by cloning the git repository"
  exit 1
fi

# install
if [[ -e $envybash_home ]]; then
  o_log "$envybash_home already exists on your system, wiping and replacing.."
  rm -rf $envybash_home
  rm -f /usr/bin/envybash
fi

git clone https://github.com/forkfoundinkitchenn/envybash.git $envybash_home
chmod +x $envybash_home/main.sh
ln -s $envybash_home/main.sh /usr/bin/envybash
o_log "installed envybash in $envybash_home"
