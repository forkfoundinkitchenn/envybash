#!/bin/bash
envybash_home=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
distros_d=$envybash_home/distros
templates_d=$envybash_home/templates
nvidia_status_path=$envybash_home/status
udev_rules_d=/etc/udev/rules.d
modprobe_d=/etc/modprobe.d
id=$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
verbose_flag=false

o_log() {
  echo "[*] $@"
}

e_log() {
  echo "[-] $@" >&2
}

help_me() {
  e_log "flags: -i (integrated), -h (hybrid), -q (query)"
  exit 1
}

root_check() {
  if [[ $EUID -ne 0 ]]; then
    e_log "you must be running this command as root"
    exit 1
  fi
}

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

parse_status() {
  nvidia_status=$(<$nvidia_status_path)
}

if [[ ! -f $distros_d/${id}.sh ]]; then
  e_log "couldn't find distro script file, your distro may not be supported"
  exit 1
fi

source "$distros_d/${id}.sh" "$@"
