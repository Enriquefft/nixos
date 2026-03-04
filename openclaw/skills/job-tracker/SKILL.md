---
name: job-tracker
description: CRUD operations on the job application tracking store.
user-invocable: false
---

## Usage

```bash
./run.ts list [--status new|applied|followed-up|rejected|offer] [--limit 20]
./run.ts add --title "Role" --company "Co" --url "https://..." [--status new]
./run.ts update <id> --status applied
./run.ts --help
```

## Output

JSON to stdout. `list` returns an array, `add`/`update` return the modified entry.

## State

Job data stored at `~/.local/state/openclaw-cron/job-tracker/jobs.json`
