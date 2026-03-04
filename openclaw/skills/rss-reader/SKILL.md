---
name: rss-reader
description: Fetch and parse RSS/Atom feeds. Returns structured JSON.
user-invocable: false
---

## Usage

```bash
./run.ts [--feeds arxiv,hn,reddit] [--since 24h] [--limit 20] [--help]
```

## Output

JSON array to stdout:
```json
[{ "title": "...", "url": "...", "source": "...", "published": "...", "summary": "..." }]
```

## Examples

- Fetch all configured feeds: `./run.ts`
- Only arxiv, last 24h: `./run.ts --feeds arxiv --since 24h`
- Limit results: `./run.ts --limit 10`

## State

State files stored at `~/.local/state/openclaw-cron/rss-reader/`
