#!/bin/bash

install_user() {
  envybash=~/.local/share/envybash
  mkdir -p "$envybash"
  git clone https://github.com/forkfoundinkitchenn/envybash.git $envybash

  ln -s $envybash/main.sh ~/.local/bin/envybash
  echo "[*] installed envybash in $envybash"
  echo "[*] make sure you have $HOME/.local/bin in your path"
}

install_root() {
  envybash=/usr/share/envybash
  mkdir -p "$envybash"
  git clone https://github.com/forkfoundinkitchenn/envybash.git "$envybash"
  ln -s $envybash/main.sh /usr/bin/
  echo "[*] installed envybash in $envybash"
}

if [[ $EUID -ne 0 ]]; then
  echo "[-] installer wasn't ran as root, installing for the current user"
  install_user
  exit 0
fi

install_root
