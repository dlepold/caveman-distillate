#!/usr/bin/env bash
# Install (or update) the daily cron entry that runs run-daily.sh once a day.
# Idempotent: replaces any prior nhv-creator-watch line. Re-run after changing
# CW_CRON_HOUR. Remove with: install-cron.sh --remove

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/common.sh"
cw::load_config

TAG="# nhv-creator-watch"
RUNNER="$CW_HOME/bin/run-daily.sh"
LOG="$CW_STATE_DIR/cron.log"
HOUR="${CW_CRON_HOUR:-7}"

current="$(crontab -l 2>/dev/null | grep -vF "$TAG" || true)"

if [[ "${1:-}" == "--remove" ]]; then
  printf '%s\n' "$current" | crontab -
  cw::log "removed nhv-creator-watch cron entry."
  exit 0
fi

line="0 $HOUR * * * /usr/bin/env bash $RUNNER >> $LOG 2>&1 $TAG"
{ printf '%s\n' "$current"; printf '%s\n' "$line"; } | crontab -
cw::log "installed: runs daily at ${HOUR}:00 → $RUNNER (log: $LOG)"
crontab -l | grep -F "$TAG"
