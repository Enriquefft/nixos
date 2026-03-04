---
name: job-scanner
description: Fetch and filter job board listings. Returns structured JSON.
user-invocable: false
---

## Usage

```bash
./run.ts [--boards linkedin,indeed,weworkremotely] [--remote-only] [--limit 20] [--help]
```

## Output

JSON array to stdout:
```json
[{ "title": "...", "company": "...", "url": "...", "location": "...", "posted": "..." }]
```

## Examples

- Scan all configured boards: `./run.ts`
- LinkedIn only, remote: `./run.ts --boards linkedin --remote-only`
- Limit results: `./run.ts --limit 5`

## State

State files stored at `~/.local/state/openclaw-cron/job-scanner/`
