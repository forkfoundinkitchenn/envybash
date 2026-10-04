#!/bin/bash
envybash_home=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
distros_d=$envybash_home/distros
templates_d=$envybash_home/templates
nvidia_status_path=$envybash_home/status
udev_rules_d=/etc/udev/rules.d
modprobe_d=/etc/modprobe.d
ID=$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
ID_LIKE=$(grep '^ID_LIKE=' /etc/os-release | cut -d= -f2 | tr -d '"')

o_log() {
  echo "[*] $@"
}

e_log() {
  echo "[-] $@" >&2
}

disclaimer() {
  e_log "flags: -i (integrated), -h (hybrid), -q (query)"
  exit 0
}

root_check() {
  if [[ $EUID -ne 0 ]]; then
    e_log "you must be running this command as root"
    exit 1
  fi
}

parse_status() {
  nvidia_status=$(<$nvidia_status_path)
}

if [ ! -f $distros_d/${ID}.sh ]; then
  ID=$ID_LIKE
fi

if [ -f $distros_d/${ID}.sh ]; then
  source "$distros_d/${ID}.sh" "$@"
else
  e_log "couldn't find distro script file, your distro may not be supported"
  exit 1
fi
