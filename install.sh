#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "[-] installer wasn't ran as root"
  exit 1
fi

envybash=/usr/share/envybash

if [[ -e $envybash && -f /usr/bin/envybash ]]; then
  echo "[-] envybash is already installed, overwriting"
fi
mkdir -p "$envybash"
git clone https://github.com/forkfoundinkitchenn/envybash.git "$envybash"
chmod +x $envybash/install.sh
chmod +x $envybash/main.sh
ln -s $envybash/main.sh /usr/bin/envybash
echo "[*] installed envybash in $envybash"
