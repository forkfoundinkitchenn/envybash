#!/bin/bash

install_user() {
  envybash=~/.local/share/envybash
  if [[ -e $envybash ]]; then
    echo "[-] envybash is already installed"
    exit 1
  fi
  mkdir -p "$envybash"
  git clone https://github.com/forkfoundinkitchenn/envybash.git "$envybash"
  chmod +x $envybash/install.sh
  chmod +x $envybash/main.sh
  ln -s $envybash/main.sh ~/.local/bin/envybash
  if [[ -f /etc/udev/rules.d/99-envybash.rules && -f /etc/modprobe.d/99-envybash.conf ]]; then
    echo "integrated" >$envybash/status
  else
    echo "hybrid" >$envybash/status
  fi
  echo "[*] installed envybash in $envybash"
  echo "[*] make sure you have $HOME/.local/bin in your path"
}

install_root() {
  envybash=/usr/share/envybash
  if [[ -e $envybash ]]; then
    echo "[-] envybash is already installed"
    exit 1
  fi
  mkdir -p "$envybash"
  git clone https://github.com/forkfoundinkitchenn/envybash.git "$envybash"
  chmod +x $envybash/install.sh
  chmod +x $envybash/main.sh
  ln -s $envybash/main.sh /usr/bin/
  if [[ -f /etc/udev/rules.d/99-envybash.rules && -f /etc/modprobe.d/99-envybash.conf ]]; then
    echo "integrated" >$envybash/status
  else
    echo "hybrid" >$envybash/status
  fi
  echo "[*] installed envybash in $envybash"
}

if [[ $EUID -ne 0 ]]; then
  echo "[-] installer wasn't ran as root, installing for the current user"
  install_user
  exit 0
fi

install_root
