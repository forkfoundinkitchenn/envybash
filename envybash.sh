#!/bin/bash
set -euo pipefail
readonly envybash_home=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
readonly status_cache=/var/cache/envybash-state
readonly version='pre-alpha-0.5'

readonly udev_path=/etc/udev/rules.d/00-nvbash.rules
readonly modprobe_path=/etc/modprobe.d/00-nvbash.conf
declare -r -a supportedDistros=("void" "debian" "fedora" "arch")

verbose=false
test_run=false
supported=false

distro_id=$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')

source $envybash_home/helper-functions.sh

project_info() {
  o_log "version: $version"
  o_log "home: $envybash_home"
  if [[ -f $udev_path ]]; then o_log "udev rule: $udev_path"; fi
  if [[ -f $modprobe_path ]]; then o_log "modprobe config: $modprobe_path"; fi
  o_log "active mode: $(<$status_cache)"
  v_log "detected distro id: $distro_id"
  v_log "verbose: $verbose"
}

help_me() {
  cat <<EOF
usage: envybash [-v] [-i] [-s integrated|hybrid]
EOF
}

importer_func() {
  cat <<EOF >$udev_path
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c0330", ATTR{remove}="1"
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x8c8000", ATTR{remove}="1"
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{remove}="1"
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x03[0-9]*", ATTR{remove}="1"
EOF
  if [[ -f $udev_path ]]; then v_log "concatenated into $udev_path"; fi

  cat <<EOF >$modprobe_path
blacklist nvidia
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
alias nouveau off
EOF
  if [[ -f $modprobe_path ]]; then v_log "concatenated into $modprobe_path"; fi
}

rebuild_initramfs() {
  case "$distro_id" in
  "void" | "fedora")
    v_log "dracut --force"
    dracut --force
    ;;
  "arch")
    v_log "mkinitcpio -P"
    mkinitcpio -P
    ;;
  "debian" | "ubuntu")
    v_log "update-initramfs"
    update-initramfs
    ;;
  esac
}

switch_mode() {
  o_log "switching to $target_mode mode"
  if_root

  case "$target_mode" in
  "integrated")
    if [[ -f $udev_path && -f $modprobe_path ]]; then
      e_log "system is already in integrated mode"
      exit 1
    elif [[ -f $udev_path || -f $modprobe_path ]]; then
      rm -f {$udev_path,$modprobe_path}
      v_log "removed $udev_path and $modprobe_path"
    fi

    importer_func
    echo 'integrated' >$status_cache
    ;;
  "hybrid")
    if [[ ! -f $udev_path && ! -f $udev_path ]]; then
      e_log "system is already in hybrid mode"
      exit 1
    fi
    rm -rf {$udev_path,$modprobe_path}
    v_log "removed $udev_path and $modprobe_path"

    echo 'hybrid' >$status_cache
    ;;
  esac
  v_log "$(<$status_cache)"

  udevadm control --reload-rules
  udevadm trigger
  rebuild_initramfs
  o_log "done, would you like to restart now?"
  answer=""
  shopt -s nocasematch
  while [[ -z $answer ]]; do
    read -r -p "[y/n] " answer
    case "$answer" in
    "y" | "yes")
      answer="y"
      ;;
    "n" | "no")
      answer="n"
      ;;
    *)
      answer=""
      ;;
    esac
  done
  shopt -u nocasematch

  if [[ $answer = "y" ]]; then reboot; fi
}

if [[ $# -eq 0 ]]; then
  help_me
  exit 1
elif [[ $# -ge 0 && $1 != -* ]]; then
  help_me
  exit 1
fi

while getopts ":vis:" flag; do
  case $flag in
  v) verbose=true ;;
  i) project_info ;;
  s)
    case "$OPTARG" in
    "integrated" | "i")
      target_mode='integrated'
      ;;
    "hybrid" | "h")
      target_mode='hybrid'
      ;;
    *)
      e_log "invalid mode"
      help_me
      exit 1
      ;;
    esac
    switch_mode
    ;;
  *)
    help_me
    exit 1
    ;;
  esac
done
