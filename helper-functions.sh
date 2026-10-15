o_log() {
  echo "[*] $@"
}

e_log() {
  echo "[-] $@" >&2
}

v_log() {
  if [[ $verbose = true ]]; then
    echo "[~] $@" >&2
  fi
}

if_root() {
  if [[ $EUID -ne 0 ]]; then
    e_log "script must be ran as root"
    exit 1
  fi
}
