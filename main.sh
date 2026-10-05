#!/bin/bash
envybash_home=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
nvidia_status_path=$envybash_home/status
udev_rules_d=/etc/udev/rules.d
modprobe_d=/etc/modprobe.d
id=$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
verbose_flag=false
dry_run=false

# helper functions
o_log() {
  echo "[*] $@"
}
e_log() {
  echo "[-] $@" >&2
}
v_log() {
  if [[ verbose_flag = true ]]; then
    echo "[~] $@" >&2
  fi
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

# core logic functions

rules_d_import() {
  echo -e "ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c0330", ATTR{remove}="1"
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x8c8000", ATTR{remove}="1"
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{remove}="1"
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x03[0-9]*", ATTR{remove}="1""
}

modprobe_d_import() {
  echo -e "blacklist nvidia
blacklist nvidia_drm
blacklist nvidia_uvm
blacklist nvidia_modeset
blacklist nvidia_current
blacklist nvidia_current_drm
blacklist nvidia_current_uvm 
blacklist nvidia_current_modeset
blacklist i2c_nvidia_gpu
blacklist nova_core
blacklist nova_drm 
blacklist nouveau
alias nvidia off
alias nvidia_drm off
alias nvidia_uvm off
alias nvidia_modeset off
alias nvidia_current off
alias nvidia_current_drm off
alias nvidia_current_uvm off
alias nvidia_current_modeset off
alias i2c_nvidia_gpu off
alias nova_core off
alias nova_drm off
alias nouveau off"
}
