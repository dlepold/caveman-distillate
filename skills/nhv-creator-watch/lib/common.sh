#!/usr/bin/env bash
# Shared helpers for nhv-creator-watch. Source this; don't execute it.
# shellcheck shell=bash

set -euo pipefail

CW_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CW_STATE_DIR="$CW_HOME/state"
CW_WORK_DIR="$CW_STATE_DIR/work"
CW_SEEN_FILE="$CW_STATE_DIR/seen.txt"
CW_RESOLVED_FILE="$CW_STATE_DIR/resolved.sh"

cw::log()  { printf '[creator-watch %s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2; }
cw::die()  { cw::log "ERROR: $*"; exit 1; }
cw::have() { command -v "$1" >/dev/null 2>&1; }

# Load config.sh (falls back to config.example.sh with a warning) and any
# previously resolved channel facts.
cw::load_config() {
  if [[ -f "$CW_HOME/config.sh" ]]; then
    # shellcheck source=/dev/null
    source "$CW_HOME/config.sh"
  elif [[ -f "$CW_HOME/config.example.sh" ]]; then
    cw::log "WARN: config.sh not found — using config.example.sh defaults."
    # shellcheck source=/dev/null
    source "$CW_HOME/config.example.sh"
  else
    cw::die "no config.sh or config.example.sh in $CW_HOME"
  fi
  if [[ -f "$CW_RESOLVED_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CW_RESOLVED_FILE"
  fi
  mkdir -p "$CW_STATE_DIR" "$CW_WORK_DIR"
  touch "$CW_SEEN_FILE"
}

cw::seen()      { grep -qxF "$1" "$CW_SEEN_FILE" 2>/dev/null; }
cw::mark_seen() { grep -qxF "$1" "$CW_SEEN_FILE" 2>/dev/null || echo "$1" >> "$CW_SEEN_FILE"; }
