---
name: job-scanner
description: Fetch and filter job board listings. Returns structured JSON.
user-invocable: false
---

## Usage

```bash
./run.ts [--boards remoteok,weworkremotely,hackernews] [--remote-only] [--new-only] [--limit 20] [--help]
```

## Options

- `--boards` — comma-separated board names (default: all configured)
- `--remote-only` — only remote-friendly positions
- `--new-only` — only jobs not seen in previous runs (dedup; use in crons)
- `--limit <n>` — cap result count

## Boards

| Board | Data source | Status |
|-------|-------------|--------|
| `remoteok` | JSON API | live |
| `weworkremotely` | RSS feed | live |
| `hackernews` | Algolia HN API (Who's Hiring thread) | live |
| `wellfound` | — | skipped (requires browser) |
| `linkedin` | — | skipped (requires auth) |
| `arcdev` | — | skipped (requires browser) |
| `turing` | — | skipped (requires browser) |
| `ycwork` | — | skipped (requires browser) |

## Output

JSON array to stdout:
```json
[{ "title": "...", "company": "...", "url": "...", "location": "...", "posted": "...", "board": "..." }]
```

## Examples

- Scan live boards, new only: `./run.ts --new-only`
- RemoteOK only, remote: `./run.ts --boards remoteok --remote-only`
- Top 5 results: `./run.ts --limit 5`

## State

`~/.local/state/openclaw-cron/job-scanner/state.json` — tracks seen URLs for dedup. Capped at 2000 entries.
