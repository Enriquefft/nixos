---
name: git-activity
description: Summarize recent git activity across ~/Projects/ repositories.
user-invocable: false
---

## Usage

```bash
./run.ts [--since yesterday] [--repos repo1,repo2] [--help]
```

## Output

JSON to stdout:
```json
[{ "repo": "...", "branch": "...", "commits": [{ "hash": "...", "message": "...", "author": "...", "date": "..." }] }]
```

## Examples

- Activity since yesterday: `./run.ts --since yesterday`
- Specific repos: `./run.ts --repos post-shit-now,openclaw-kapso-whatsapp`
- Last week: `./run.ts --since "7 days ago"`
