---
name: nhv-creator-watch
description: >
  Daily creator-watch assistant. Once per day it fetches the latest videos
  (transcripts) and posts from a tracked YouTube creator, extracts actionable
  tips, and checks each one against the cms4life NHV project (nhv2 order
  structure + business logic): already done / doable / interesting / skip.
  Produces a concise German digest and emails it to admin via admin2email.
  Use when user says "creator watch", "kreator check", "nhv watch",
  "tägliches review", "youtube review", or when invoked by the daily cron.
---

# NHV Creator Watch

Watch one creator. Pull what they publish. Turn it into concrete advice for the
cms4life NHV project. Notify admin. Run once a day.

## Inputs (provided by `bin/run-daily.sh`)

- New items since last run: each is a Markdown file in the work dir with
  `title`, `url`, `published`, `source` (youtube/blog/…) and the full
  transcript or post text.
- Project context: `CW_PROJECT_ROOT` (the nhv2/cms4life tree) and
  `CW_PROJECT_FOCUS` (order structure + business-logic sub-paths to weight).

## What to do per item

1. Read the transcript/post. Pull out **only actionable tips** — concrete
   techniques, patterns, fixes, settings, library/API usage. Drop hype,
   intros, sponsor reads, restating the obvious.
2. For each tip, inspect the project (focus paths first) and classify:

   | Status | Meaning |
   |--------|---------|
   | `DONE` | Already implemented in nhv2. Cite the file. |
   | `DOABLE` | Not present, fits the codebase. Give the concrete change + where. |
   | `INTERESTING` | Worth considering, needs a decision/larger change. Note trade-off. |
   | `SKIP` | Irrelevant to NHV (wrong stack, not applicable). One line why. |

3. Be specific: reference real files/functions under `CW_PROJECT_ROOT`. No
   generic advice. If you can't verify against the code, say so — don't guess.

## Output (the email body)

German. Terse. One block per item, then a short "Heute umsetzbar" shortlist.

```
# Creator-Watch — {date}

## {item title}  ({source}, {published})
{url}

- DOABLE: {tip}. → {file/place}: {concrete change}.
- DONE: {tip}. → bereits in {file}.
- INTERESTING: {tip}. → {trade-off / offene Frage}.
- SKIP: {tip}. → {reason}.

## Heute umsetzbar (Top)
1. {highest-value DOABLE, with file}
2. ...
```

If no new items: one line, `Keine neuen Beiträge seit {last_run}.` — the cron
skips the mail in that case.

## Boundaries

- Never invent file paths or claim something is `DONE` without seeing it.
- Code suggestions: write real code, normal clarity (not caveman).
- Security-relevant tips: flag explicitly, never downplay.
- Read-only against the project. Propose changes; don't apply them here.
