#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "[-] installer wasn't ran as root"
  exit 1
fi

envybash=/usr/share/envybash
nvidia_status_path=$envybash/status
udev_rules_d=/etc/udev/rules.d
modprobe_d=/etc/modprobe.d

if [[ -e $envybash && -f /usr/bin/envybash ]]; then
  echo "[-] envybash is already installed, overwriting"
  rm -rf $envybash
  rm /usr/bin/envybash
fi
mkdir -p "$envybash"
git clone https://github.com/forkfoundinkitchenn/envybash.git "$envybash"
chmod +x $envybash/install.sh
chmod +x $envybash/main.sh
ln -s $envybash/main.sh /usr/bin/envybash
# generate the status file if it doesn't exist yet
if [[ ! -f $nvidia_status_path ]]; then
  touch $nvidia_status_path
  if [[ -f $udev_rules_d/99-envybash.rules && -f $modprobe_d/99-envybash.conf ]]; then
    echo "integrated" >$nvidia_status_path
  elif [[ -f $udev_rules_d/99-envybash.rules || -f $modprobe_d/99-envybash.conf ]]; then
    # wipe files in case one is missing and revert to hybrid
    rm -f $udev_rules_d/99-envybash.rules
    rm -f $modprobe_d/99-envybash.rules
    echo "hybrid" >$nvidia_status_path
    e_log "reverted to hybrid because of a synchronization issue"
  else
    echo "hybrid" >$nvidia_status_path
  fi
fi
echo "[*] installed envybash in $envybash"
