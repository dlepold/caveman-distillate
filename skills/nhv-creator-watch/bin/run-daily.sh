#!/usr/bin/env bash
# Daily orchestrator for nhv-creator-watch. Wire this into cron (install-cron.sh).
#
# Flow: resolve channel (once) → fetch new items → review each against the
# cms4life NHV project with the headless Claude CLI → email admin → mark seen.
#
# Degraded mode: if the Claude CLI is missing/fails, the raw new items are
# mailed so nothing is silently lost.

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/common.sh"
cw::load_config

BIN_DIR="$CW_HOME/bin"
TODAY="$(date '+%Y-%m-%d')"

# 1. Resolve channel once (no-op if already resolved).
if [[ -z "${CW_CHANNEL_ID:-}" && -z "${CW_CHANNEL_HANDLE:-}" ]]; then
  cw::log "resolving channel from seed URL…"
  bash "$BIN_DIR/resolve-channel.sh" || cw::log "WARN: channel resolution failed; continuing."
  cw::load_config   # pick up state/resolved.sh
fi

# 2. Fetch new items.
mapfile -t NEW < <(bash "$BIN_DIR/fetch-updates.sh")
if [[ ${#NEW[@]} -eq 0 ]]; then
  cw::log "no new items — nothing to mail."
  exit 0
fi
cw::log "found ${#NEW[@]} new item(s)."

# 3. Build the review prompt: SKILL.md body + project context + items.
PROMPT="$CW_WORK_DIR/prompt-$TODAY.md"
{
  # SKILL.md body without YAML front-matter.
  awk 'NR==1 && /^---[[:space:]]*$/{fm=1;next} fm && /^---[[:space:]]*$/{fm=0;next} !fm' "$CW_HOME/SKILL.md"
  echo
  echo "## Project context"
  echo "CW_PROJECT_ROOT: ${CW_PROJECT_ROOT:-unset}"
  echo "CW_PROJECT_FOCUS: ${CW_PROJECT_FOCUS:-unset}"
  echo "Inspect that tree (read-only) to classify each tip. Today: $TODAY."
  echo
  echo "## New items to review"
  for f in "${NEW[@]}"; do
    echo; echo "### FILE: $f"; echo '```'; cat "$f"; echo '```'
  done
  echo
  echo "Produce the email body exactly as specified in the Output section above."
} > "$PROMPT"

# 4. Review with headless Claude (working dir = project root so it can read code).
DIGEST="$CW_WORK_DIR/digest-$TODAY.md"
if cw::have "${CW_CLAUDE_BIN:-claude}"; then
  cw::log "running review via ${CW_CLAUDE_BIN}…"
  if ( cd "${CW_PROJECT_ROOT:-$CW_HOME}" \
        && "${CW_CLAUDE_BIN}" -p "$(cat "$PROMPT")" \
             --permission-mode plan > "$DIGEST" 2>>"$CW_STATE_DIR/claude.err" ) \
       && [[ -s "$DIGEST" ]]; then
    cw::log "review done."
  else
    cw::log "WARN: Claude review failed — mailing raw items (see state/claude.err)."
    : > "$DIGEST"
  fi
else
  cw::log "WARN: ${CW_CLAUDE_BIN} not found — mailing raw items."
  : > "$DIGEST"
fi

if [[ ! -s "$DIGEST" ]]; then
  {
    echo "# Creator-Watch — $TODAY (Rohdaten, kein Review)"
    for f in "${NEW[@]}"; do echo; echo "## $f"; cat "$f"; done
  } > "$DIGEST"
fi

# 5. Email admin.
SUBJECT="Creator-Watch $TODAY — ${#NEW[@]} neue(r) Beitrag/Beiträge"
export CW_ADMIN_MAIL_INCLUDE CW_ADMIN_MAIL_FUNC CW_ADMIN_FALLBACK_TO
if php "$BIN_DIR/notify.php" "$SUBJECT" < "$DIGEST"; then
  cw::log "notified admin."
  # 6. Mark items seen only after a successful send.
  for f in "${NEW[@]}"; do
    id="$(sed -n 's/^id: //p' "$f" | head -n1)"
    [[ -n "$id" ]] && cw::mark_seen "$id"
    rm -f "$f"
  done
else
  cw::die "notify.php failed — items NOT marked seen; will retry next run."
fi

cw::log "done."
