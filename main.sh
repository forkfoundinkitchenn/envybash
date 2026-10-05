#!/bin/bash
set -euo pipefail

envybash_home=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
nvidia_status_path=$HOME/.envybash-state
udev_rule=/etc/udev/rules.d/99-envybash.rules
modprobe_conf=/etc/modprobe.d/99-envybash.conf
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
  if [[ $verbose_flag = true ]]; then
    echo "[~] $@" >&2
  fi
}
help_me() {
  echo "envybash usage:
flags: -s (switch), -v (verbose), -q (query), -d (dry run)
modes: integrated, hybrid" >&2
  exit 1
}
root_check() {
  if [[ $EUID -ne 0 ]]; then
    e_log "you must be running this command as root"
    exit 1
  fi
}

# core logic functions
rule_import() {
  echo -e 'ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c0330", ATTR{remove}="1"
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x8c8000", ATTR{remove}="1"
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{remove}="1"
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x03[0-9]*", ATTR{remove}="1"'
}
modprobe_import() {
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
regen_initramfs() {
  v_log "detected distro id: $id"
  case "$id" in
  "void" | "fedora") dracut --force ;;
  "arch") mkinitcpio -P ;;
  *)
    e_log "your distro may not be supported yet, if you think this is a mistake please open an issue in the official github repo"
    exit 1
    ;;
  esac
}

# mode switch functions
integrated_mode() {
  if [[ $dry_run = true ]]; then
    o_log "!! DRY RUN !!"
    o_log "imported rules to $udev_rule"
    o_log "reloaded udev rules"
    o_log "imported config to $modprobe_conf"
    o_log "regenerating initramfs"
    o_log "detected distro id: $id"
    o_log "set to integrated mode"
    exit 0
  fi

  root_check
  if [[ -f $udev_rule && -f $modprobe_conf ]]; then
    e_log "active mode is already set to integrated mode"
    exit 1
  fi

  rule_import >$udev_rule
  v_log "imported rules to $udev_rule"
  udevadm control --reload-rules
  udevadm trigger
  v_log "reloaded udev rules"
  modprobe_import >$modprobe_conf
  v_log "imported config to $modprobe_conf"
  o_log "regenerating initramfs, this may take a while"
  regen_initramfs
  o_log "set to integrated mode, restart your device to apply changes"

  echo "integrated" >$nvidia_status_path
  exit 0
}

hybrid_mode() {
  if [[ $dry_run = true ]]; then
    o_log "!! DRY RUN !!"
    o_log "deleted $udev_rule and $modprobe_conf"
    o_log "reloaded udev rules"
    o_log "regenerating initramfs"
    o_log "detected distro id: $id"
    o_log "set to hybrid mode"
    exit 0
  fi

  root_check
  if [[ ! -f $udev_rule && ! -f $modprobe_conf ]]; then
    e_log "active mode is already set to hybrid mode"
    exit 1
  fi

  rm -f {"$udev_rule","$modprobe_conf"}
  v_log "deleted $udev_rule and $modprobe_conf"
  udevadm control --reload-rules
  udevadm trigger
  v_log "reloaded udev rules"
  o_log "regenerating initramfs, this may take a while"
  regen_initramfs
  o_log "set to hybrid mode, restart your device to apply changes"

  echo "hybrid" >$nvidia_status_path
  exit 0
}

nvidia_mode() {
  e_log "you aren't supposed to be here!"
}

query_mode() {
  if [[ -f $udev_rule && -f $modprobe_conf ]]; then
    v_log "$udev_rule"
    v_log "$modprobe_conf"
    o_log "active mode: integrated"

    echo "integrated" >$nvidia_status_path
  else
    o_log "active mode: hybrid"

    echo "hybrid" >$nvidia_status_path
  fi
}

# this is probably a really bad way to do it but it works for now
if [[ $# -eq 0 ]]; then
  help_me
elif [[ $# -gt 0 && $1 != -* ]]; then
  help_me
elif [[ $# -gt 0 && $1 = -- ]]; then
  help_me
elif [[ $# -gt 0 && $1 = - ]]; then
  help_me
fi

# main
while getopts ":s:vqd" flag; do
  case "$flag" in
  s)
    case "$OPTARG" in
    "integrated" | "i") integrated_mode ;;
    "hybrid" | "h") hybrid_mode ;;
    *) help_me ;;
    esac
    ;;
  v) verbose_flag=true ;;
  q) query_mode ;;
  d) dry_run=true ;;
  *) help_me ;;
  esac
done
