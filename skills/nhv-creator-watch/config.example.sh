# nhv-creator-watch — configuration
# Copy to config.sh (gitignored) and adjust. Lives on TB16 (mirrored to B14).
# shellcheck shell=bash disable=SC2034

# --- Creator / sources -------------------------------------------------------

# A representative video/short URL from the creator. The resolver derives the
# channel from this on first run when CW_CHANNEL_ID is empty.
CW_SEED_URL="https://youtube.com/shorts/AW1ori0KpYQ"

# Filled by bin/resolve-channel.sh on first run (written to state/resolved.sh).
# You can also set CW_CHANNEL_ID manually (e.g. "UCxxxxxxxxxxxxxxxxxxxxxx") or
# CW_CHANNEL_HANDLE (e.g. "@somehandle") to skip resolution.
CW_CHANNEL_ID=""
CW_CHANNEL_HANDLE=""

# Extra places the creator publishes (blog/Substack/RSS), space-separated URLs.
# resolve-channel.sh appends discovered links here (state/resolved.sh); you may
# also pre-seed known feeds.
CW_EXTRA_FEEDS=""

# --- Project under review: cms4life NHV --------------------------------------

# Root of the nhv2/cms4life project on this machine.
CW_PROJECT_ROOT="/srv/www/nhv2"                         # ADJUST

# Sub-paths that matter most (order structure + business logic), relative to
# CW_PROJECT_ROOT, space-separated. The review weights these first.
CW_PROJECT_FOCUS="includes/order includes/business"     # ADJUST

# --- Notification: existing admin2email() ------------------------------------

# PHP file in remote/common that defines the admin mail helper.
CW_ADMIN_MAIL_INCLUDE="/srv/www/nhv2/remote/common/mail.php"   # ADJUST
# Function to call. Assumed signature: admin2email($subject, $body).
CW_ADMIN_MAIL_FUNC="admin2email"
# Fallback recipient (plain PHP mail()) if the function can't be loaded.
CW_ADMIN_FALLBACK_TO="admin@cms4life.local"             # ADJUST

# --- Runtime -----------------------------------------------------------------

# How many latest uploads to look back over each run.
CW_LOOKBACK="6"
# Subtitle languages to prefer, in order (yt-dlp --sub-langs syntax).
CW_SUB_LANGS="de.*,en.*"
# Headless Claude Code CLI used for the review reasoning. If missing, the cron
# still mails the raw new items (degraded mode).
CW_CLAUDE_BIN="claude"
# Hour of day (0–23, local time) for the daily cron.
CW_CRON_HOUR="7"
