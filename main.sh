#!/bin/bash
set -euo pipefail

readonly envybash_home=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
readonly version='pre-alpha-0.3'
readonly nvidia_status_path=/var/cache/envybash-state
readonly udev_rule=/etc/udev/rules.d/99-envybash-udev.rules
readonly modprobe_conf=/etc/modprobe.d/99-envybash-modprobe.conf
readonly xorg_conf=/etc/X11/xorg.conf.d/99-envybash-xorg.conf
readonly profile_sh=/etc/profile.d/99-envybash-profile.sh
readonly supported_distributions=("void" "fedora" "debian" "ubuntu" "arch")
verbose_flag=false
test_flag=false

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

# logical functions
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

profile_import() {
  case "$vendor_id" in
  "intel")
    cat <<EOF
#!/bin/sh

export VK_DRIVER_FILES=/usr/share/vulkan/icd.d/intel_icd.x86_64.json
EOF
    ;;
  "amd")
    cat <<EOF
#!/bin/sh

export VK_DRIVER_FILES=/usr/share/vulkan/icd.d/radeon_icd.x86_64.json
EOF
    ;;
  esac
}

xorg_import() {
  case "$vendor_id" in
  "intel")
    cat <<EOF
Section "Device"
      Identifier "Intel Graphics"
      Driver "modesetting"
      Option "PrimaryGPU" "yes"
EndSection
EOF
    ;;
  "amd")
    cat <<EOF
Section "Device"
      Identifier "AMD"
      Driver "amdgpu"
      Option "PrimaryGPU" "yes"
EndSection
EOF
    ;;
  esac
}

regen_initramfs() {
  v_log "detected distro id: $distro_id"
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
  *)
    e_log "distro unsupported"
    rm -f $udev_rule
    rm -f $modprobe_conf
    rm -f $xorg_conf
    exit 1
    ;;
  esac
}

switch_power_mode() {
  v_log "checking if root.."
  root_check
  # mode-specific commands
  case "$target_power_mode" in
  "integrated")
    v_log "checking if already using target mode.."
    if [[ -f $modprobe_conf && -f $udev_rule && -f $xorg_conf && -f $profile_sh ]]; then
      e_log "system is already using integrated mode!"
      exit 1
    elif [[ ! -f $modprobe_conf || ! -f $udev_rule || ! -f $xorg_conf || ! -f $profile_sh ]]; then
      e_log "something went wrong, wiping and replacing"
      rm -f $udev_rule
      rm -f $modprobe_conf
      rm -f $xorg_conf
      rm -f $profile_sh
    fi

    o_log "switching to integrated mode.."
    v_log "writing to $modprobe_conf"
    modprobe_import >$modprobe_conf
    v_log "writing to $udev_rule"
    rule_import >$udev_rule
    v_log "writing to $xorg_conf"
    xorg_import >$xorg_conf
    v_log "writing to $profile_sh"
    profile_import >$profile_sh
    echo "integrated" >$nvidia_status_path
    ;;
  "hybrid")
    v_log "checking if already using target mode.."
    if [[ ! -f $modprobe_conf && ! -f $udev_rule && ! -f $xorg_conf && ! -f $profile_sh ]]; then
      e_log "system is already using hybrid mode!"
      exit 1
    fi

    o_log "switching to hybrid mode.."
    rm -f $udev_rule
    rm -f $modprobe_conf
    rm -f $xorg_conf
    rm -f $profile_sh
    echo "hybrid" >$nvidia_status_path
    ;;
  esac

  # main set of commands to run afterwards
  v_log "reloading udev rules using udevadm"
  udevadm control --reload-rules
  udevadm trigger
  v_log "reloaded udev rules"
  o_log "regenerating initramfs, this may take a while. leave this window open."
  regen_initramfs
  o_log "regenerating initramfs"
  o_log "complete, you may either relogin or reboot your system"
}

# miscallaneous functions
query_mode() {
  if [[ -f $udev_rule && -f $modprobe_conf && -f $xorg_conf && -f $profile_sh ]]; then
    v_log "$udev_rule"
    v_log "$modprobe_conf"
    v_log "$xorg_conf"
    v_log "$profile_sh"
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
  if [[ $test_flag = false ]]; then
    exit 1
  fi

  xorg_config >test1
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

# unused for the time being
#for distro in ${supported_distributions[@]}; do
#  if [[ ! $distro = $distro_id ]]; then
#    e_log "hi"
#    echo $distro
#  else
#    o_log "hi"
#    echo $distro
#  fi
#done

case "$vendor_id" in
"GenuineIntel") vendor_id="intel" ;;
"AuthenticAMD") vendor_id="amd" ;;
*) vendor_id="unknown" ;;
esac

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
  p) e_log "what" ;;
  *)
    help_me >&2
    exit 1
    ;;
  esac
done
