#!/bin/bash
set -euo pipefail

envybash_home=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
version='pre-alpha-0.2'
nvidia_status_path=$/var/cache/envybash-state
udev_rule=/etc/udev/rules.d/99-envybash.rules
modprobe_conf=/etc/modprobe.d/99-envybash.conf
verbose_flag=false
dry_run=false

distro_id=$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
vendor_id=$(grep -m 1 'vendor_id' /proc/cpuinfo | awk '{print $3}')

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
  flags: -s (switch), -v (verbose), -q (query), -i (debug info)
modes: integrated, hybrid"
}
root_check() {
  if [[ $EUID -ne 0 ]]; then
    e_log "you must be running this command as root"
    exit 1
  fi
}

# core logic functions
rule_import() {
  cat <<EOF
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c0330", ATTR{remove}="1"
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x8c8000", ATTR{remove}="1"
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{remove}="1"
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x03[0-9]*", ATTR{remove}="1"
EOF
}

modprobe_import() {
  cat <<EOF
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
}

regen_initramfs() {
  v_log "detected distro id: $distro_id"
  case "$distro_id" in
  "void" | "fedora")
    dracut --force
    v_log "dracut --force"
    ;;
  "arch")
    mkinitcpio -P
    v_log "mkinitcpio -P"
    ;;
  "debian" | "ubuntu")
    update-initramfs
    v_log "update-initramfs"
    ;;
  *)
    e_log "distro unsupported"
    exit 1
    ;;
  esac
}

switch_power_mode() {
  case "$target_power_mode" in
  "integrated")
    o_log "switching to integrated mode.."

    v_log "checking if run as root"
    root_check
    v_log "checking if system is already in integrated mode"
    if [[ -f $udev_rule && -f modprobe_conf ]]; then
      e_log "system is already in integrated mode!"
      exit 1
    elif [[ ! -f $udev_rule || ! -f $modprobe_conf ]]; then
      e_log "something bad happened, wiping and replacing.."
      rm -f $udev_rule
      rm -f $modprobe_conf
    fi
    v_log "writing to $udev_rule.."
    rule_import >$udev_rule
    v_log "wrote to $udev_rule successfully"
    v_log "telling udevadm to reload udev rules"
    udevadm control --reload-rules
    udevadm trigger
    v_log "reloaded rules successfully"
    v_log "writing to $modprobe_conf"
    modprobe_import >$modprobe_conf
    v_log "wrote to $modprobe_conf successfully"
    o_log "regenerating initramfs, this may take a while"
    v_log "running regen_initramfs"
    regen_initramfs
    o_log "regenerated initramfs, you may now reboot your system"
    v_log "writing to $nvidia_status_path"
    echo "integrated" >$nvidia_status_path
    ;;
  "hybrid")
    o_log "switching to hybrid mode.."

    v_log "checking if run as root"
    root_check
    v_log "checking if system is already in hybrid mode"
    if [[ ! -f $udev_rule && ! -f $modprobe_conf ]]; then
      e_log "system is already in hybrid mode!"
      exit 1
    fi

    v_log "wiping $udev_rule.."
    rm -f $udev_rule
    v_log "wiped $udev_rule successfully"
    v_log "telling udevadm to reload udev rules"
    udevadm control --reload-rules
    udevadm trigger
    v_log "reloaded rules successfully"
    v_log "wiping $modprobe_conf.."
    rm -f $modprobe_conf
    v_log "wiped $modprobe_conf successfully"
    o_log "regenerating initramfs, this may take a while"
    v_log "running regen_initramfs"
    regen_initramfs
    o_log "regenerated initramfs, you may now reboot your system"
    v_log "writing to $nvidia_status_path"
    echo "hybrid" >$nvidia_status_path
    ;;
  "nvidia") e_log "you aren't supposed to be here!" ;;
  esac
}

query_mode() {
  if [[ -f $udev_rule && -f $modprobe_conf ]]; then
    v_log "$udev_rule"
    v_log "$modprobe_conf"
    o_log "active mode: integrated"
  else
    o_log "active mode: hybrid"
  fi
}

debug_info() {
  o_log "current version: $version"
  o_log "git lives in: $envybash_home"
  o_log "shell script lives in: $0"
  o_log "distro id: $distro_id"
  o_log "vendor id: $vendor_id"
}

test_run() {
  rule_import >test1
  modprobe_import >test2
  exit 0
}

# this is probably a really bad way to do it but it works for now
if [[ $# -eq 0 ]]; then
  help_me >&2
  exit 1
elif [[ $# -gt 0 && $1 != -* ]]; then
  help_me >&2
  exit 1
elif [[ $# -gt 0 && $1 = '--' ]]; then
  help_me >&2
  exit 1
elif [[ $# -gt 0 && $1 = - ]]; then
  help_me >&2
  exit 1
fi

# main
while getopts ":s:vqdi" flag; do
  case "$flag" in
  s)
    case "$OPTARG" in
    "integrated" | "i")
      target_power_mode="integrated"
      switch_power_mode
      ;;
    "hybrid" | "h")
      target_power_mode="hybrid"
      switch_power_mode
      ;;
    *)
      help_me >&2
      exit 1
      ;;
    esac
    ;;
  v)
    o_log "verbose logging enabled for this instance"
    verbose_flag=true
    ;;
  q) query_mode ;;
  i) debug_info ;;
  d) test_run ;;
  *)
    help_me >&2
    exit 1
    ;;
  esac
done
