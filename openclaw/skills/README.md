# Skills

Utility CLI tools as OpenClaw native skills. Symlinked via `mkOutOfStoreSymlink`
in `module.nix` — live edits, no rebuild for content changes.

## Skill structure

```
skills/<name>/
├── SKILL.md        # OpenClaw skill discovery + usage docs
└── run.ts          # #!/usr/bin/env bun — executable CLI
```

## CLI contract

All skills follow a standard interface:
- **stdout** = structured JSON data
- **stderr** = diagnostics/errors
- **exit 0** = success, non-zero = error
- **`--help`** = self-documenting usage
- **No interactive input**

## Available skills

| Skill | Purpose | State |
|-------|---------|-------|
| `job-scanner` | Fetch/filter job board listings | stub (TODO) |
| `rss-reader` | Fetch/parse RSS/Atom feeds | stub (TODO) |
| `job-tracker` | CRUD on job tracking store | implemented |
| `git-activity` | Summarize git commits across ~/Projects/ | implemented |

State files: `~/.local/state/openclaw-cron/<skill-name>/`
