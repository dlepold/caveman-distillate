#!/usr/bin/env bash
# Fetch the creator's newest items and write one Markdown file per NEW item into
# the work dir. Prints the paths of new item files on stdout (one per line).
#
# Sources:
#   - YouTube channel RSS (no API key): feeds/videos.xml?channel_id=...
#   - Transcripts via yt-dlp auto/uploaded subtitles (CW_SUB_LANGS).
#   - Extra RSS/Atom feeds in CW_EXTRA_FEEDS / CW_DISCOVERED_LINKS.
#
# Runs on TB16 (needs YouTube access). Idempotent: items in state/seen.txt are
# skipped; seen-marking happens in run-daily.sh AFTER a successful review.

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/common.sh"
cw::load_config

cw::have yt-dlp || cw::log "WARN: yt-dlp missing — transcripts will be empty (metadata only)."
cw::have curl   || cw::die "curl is required."

slug() { printf '%s' "$1" | tr -cs 'A-Za-z0-9' '-' | sed 's/^-//; s/-$//' | cut -c1-60; }

# --- YouTube videos via channel RSS -----------------------------------------
emit_youtube() {
  local cid="${CW_CHANNEL_ID:-}"
  if [[ -z "$cid" ]]; then
    cw::log "no CW_CHANNEL_ID — run resolve-channel.sh first; skipping YouTube."
    return 0
  fi
  local feed; feed="$(curl -fsS "https://www.youtube.com/feeds/videos.xml?channel_id=$cid")" \
    || { cw::log "WARN: channel RSS fetch failed."; return 0; }

  # Extract video IDs in feed order, newest first; cap at CW_LOOKBACK.
  local ids; ids="$(printf '%s\n' "$feed" | grep -oE '<yt:videoId>[^<]+' \
    | sed 's/<yt:videoId>//' | head -n "${CW_LOOKBACK:-6}")"

  local vid title pub url out sub
  while IFS= read -r vid; do
    [[ -n "$vid" ]] || continue
    cw::seen "yt:$vid" && continue
    url="https://www.youtube.com/watch?v=$vid"
    # Title + publish date from the feed entry.
    title="$(printf '%s\n' "$feed" | awk -v id="$vid" '
      $0 ~ "<yt:videoId>"id"</yt:videoId>" {f=1}
      f && /<title>/ {gsub(/.*<title>|<\/title>.*/,""); print; exit}')"
    pub="$(printf '%s\n' "$feed" | awk -v id="$vid" '
      $0 ~ "<yt:videoId>"id"</yt:videoId>" {f=1}
      f && /<published>/ {gsub(/.*<published>|<\/published>.*/,""); print; exit}')"

    sub=""
    if cw::have yt-dlp; then
      ( cd "$CW_WORK_DIR" && yt-dlp --no-warnings --skip-download \
          --write-auto-subs --write-subs --sub-langs "${CW_SUB_LANGS:-de.*,en.*}" \
          --convert-subs srt -o "%(id)s.%(ext)s" "$url" >/dev/null 2>&1 ) || true
      # Pick the first matching srt, strip timecodes/indices to plain text.
      local srtfile; srtfile="$(ls "$CW_WORK_DIR/$vid".*.srt 2>/dev/null | head -n1 || true)"
      if [[ -n "$srtfile" ]]; then
        sub="$(grep -vE '^[0-9]+$|-->|^$' "$srtfile" | sed 's/<[^>]*>//g' | tr '\n' ' ' \
               | tr -s ' ')"
        rm -f "$CW_WORK_DIR/$vid".*.srt
      fi
    fi

    out="$CW_WORK_DIR/yt-$vid.md"
    {
      echo "title: ${title:-$vid}"
      echo "url: $url"
      echo "published: ${pub:-unknown}"
      echo "source: youtube"
      echo "id: yt:$vid"
      echo "---"
      echo "${sub:-[no transcript available]}"
    } > "$out"
    echo "$out"
  done <<< "$ids"
}

# --- Extra feeds (blog/Substack/etc.) ---------------------------------------
emit_feeds() {
  local feeds="${CW_EXTRA_FEEDS:-} ${CW_DISCOVERED_LINKS:-}"
  local f xml link title pub gid out
  for f in $feeds; do
    [[ "$f" =~ ^https?:// ]] || continue
    xml="$(curl -fsSL "$f" 2>/dev/null)" || { cw::log "WARN: feed fetch failed: $f"; continue; }
    # Grab the newest entry only (RSS <item> or Atom <entry>).
    link="$(printf '%s\n' "$xml" | grep -oE '<link[^>]*href="[^"]+"|<link>[^<]+' \
            | head -n2 | tail -n1 | grep -oE 'https?://[^"<]+' | head -n1)"
    [[ -n "$link" ]] || continue
    gid="feed:$link"
    cw::seen "$gid" && continue
    title="$(printf '%s\n' "$xml" | grep -oE '<title>[^<]+' | sed -n '2p' | sed 's/<title>//')"
    pub="$(printf '%s\n' "$xml" | grep -oiE '<(pubDate|published|updated)>[^<]+' | head -n1 \
           | sed 's/<[^>]*>//')"
    out="$CW_WORK_DIR/feed-$(slug "$link").md"
    {
      echo "title: ${title:-$link}"
      echo "url: $link"
      echo "published: ${pub:-unknown}"
      echo "source: blog"
      echo "id: $gid"
      echo "---"
      echo "[open the post to read full text: $link]"
    } > "$out"
    echo "$out"
  done
}

emit_youtube
emit_feeds
