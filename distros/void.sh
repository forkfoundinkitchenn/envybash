#!/bin/bash

## DO NOT RUN THIS FILE BY ITSELF. IT WILL NOT WORK.
set -euo pipefail

integrated_mode() {
  root_check
  parse_status
  if [ "$nvidia_status" = "integrated" ]; then
    e_log "already using integrated mode!"
    exit 1
  fi

  rm -f "$udev_rules_d/99-envybash.rules"
  rm -f "$modprobe_d/99-envybash.conf"
  cp "$templates_d/99-envybash.conf" "$modprobe_d"
  cp "$templates_d/99-envybash.rules" "$udev_rules_d"
  udevadm control --reload-rules
  udevadm trigger
  xbps-reconfigure --force linux$(uname -r | grep -o "^[0-9]\+\.[0-9]\+")
  echo "integrated" >"$nvidia_status_path"
  o_log "set to integrated mode, you can now restart your computer"
  exit 0
}

hybrid_mode() {
  root_check
  parse_status
  if [ "$nvidia_status" = "hybrid" ]; then
    e_log "already using hybrid mode!"
    exit 1
  fi

  rm -f "$udev_rules_d/99-envybash.rules"
  rm -f "$modprobe_d/99-envybash.conf"
  udevadm control --reload-rules
  udevadm trigger
  xbps-reconfigure --force linux$(uname -r | grep -o "^[0-9]\+\.[0-9]\+")
  echo "hybrid" >"$nvidia_status_path"
  o_log "set to hybrid mode, you may now restart your computer"
  exit 0
}

query_mode() {
  parse_status
  o_log "current mode: $nvidia_status"
  exit 0
}

OPTIND=1
while getopts "ihq" opt; do
  case "$opt" in
  i) integrated_mode ;;
  h) hybrid_mode ;;
  q) query_mode ;;
  *)
    disclaimer
    exit 1
    ;;
  esac
done

disclaimer
exit 1
