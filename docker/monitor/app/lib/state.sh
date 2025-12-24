#!/usr/bin/env bash
set -euo pipefail

state_file_for() {
  local state_dir="$1"
  local key="$2"
  echo "${state_dir}/${key}.state"
}

get_state() {
  local f="$1"
  if [ -f "$f" ]; then cat "$f"; else echo "unknown"; fi
}

set_state() {
  local f="$1"
  local v="$2"
  echo "$v" > "$f"
}
