# NHV Creator Watch

A daily assistant that watches one YouTube creator, pulls their newest videos
(transcripts) and posts, turns them into **concrete advice for the cms4life NHV
project** (`nhv2` order structure + business logic), and emails the result to
admin via the existing `admin2email()` helper.

Runs on **TB16** (auto-mirrored to B14). It needs real network access to
YouTube — it does **not** run in the Claude cloud sandbox (that environment
blocks `youtube.com`, which is why channel resolution is deferred to here).

## How it works

```
cron (daily)
  └─ bin/run-daily.sh
       ├─ bin/resolve-channel.sh   # once: seed URL → channel_id + publish links
       ├─ bin/fetch-updates.sh     # channel RSS + transcripts → new-item .md files
       ├─ claude -p (SKILL.md)      # review each tip vs. nhv2 → German digest
       └─ bin/notify.php            # admin2email($subject, $body)
```

State lives in `state/` (gitignored): `seen.txt` (processed item ids),
`resolved.sh` (channel facts), `work/` (per-run scratch), logs. Items are marked
seen only after a successful email, so a failed run retries next day.

## Requirements

- `bash`, `curl`, `php`, `python3`
- [`yt-dlp`](https://github.com/yt-dlp/yt-dlp) — for transcripts + channel
  resolution (without it you get metadata only, and no `channel_id`)
- `claude` CLI (headless) — for the review step; optional (degrades to mailing
  raw items)

## Setup (on TB16)

```bash
cd skills/nhv-creator-watch
cp config.example.sh config.sh
$EDITOR config.sh          # set CW_PROJECT_ROOT, CW_ADMIN_MAIL_INCLUDE, etc.

bash bin/resolve-channel.sh   # resolves the channel from CW_SEED_URL
bash bin/run-daily.sh         # dry first run; check state/ and the email
bash bin/install-cron.sh      # schedule daily at CW_CRON_HOUR
```

## Configuration

All knobs live in `config.sh` (copied from `config.example.sh`). The important
ones:

| Variable | What |
|----------|------|
| `CW_SEED_URL` | A video/short URL from the creator (channel is derived from it) |
| `CW_PROJECT_ROOT` | Root of the nhv2/cms4life tree to review against |
| `CW_PROJECT_FOCUS` | Sub-paths weighted first (order structure + business logic) |
| `CW_ADMIN_MAIL_INCLUDE` | PHP file in `remote/common` defining the mail helper |
| `CW_ADMIN_MAIL_FUNC` | Helper name (default `admin2email`) |
| `CW_ADMIN_FALLBACK_TO` | Recipient if the helper can't be loaded (uses `mail()`) |
| `CW_CRON_HOUR` | Hour (0–23) for the daily run |

> `notify.php` assumes `admin2email($subject, $body)`. If your helper's
> signature differs, adjust the one call in `bin/notify.php`.

## Channel resolution — how it's done (reproducible)

`resolve-channel.sh` derives the channel from a single video URL so you never
hand-copy IDs:

1. `yt-dlp --dump-single-json <seed>` → `channel`, `channel_id`, `channel_url`,
   `uploader_id`, and the description.
2. Outbound `http(s)` links in the description (minus youtube.com) become
   candidate `CW_EXTRA_FEEDS` — that's the "where else do they publish"
   discovery.
3. Fallback without yt-dlp: the YouTube **oEmbed** endpoint gives author name +
   channel URL (but not `channel_id`, so install yt-dlp for the RSS feed).

Results are written to `state/resolved.sh`. Re-run with `--force` to refresh.

## Manual / interactive use

The same logic is a Claude Code skill (`SKILL.md`): say `creator watch`,
`kreator check`, or `nhv watch` in an interactive session pointed at the nhv2
project to run a review on demand.
