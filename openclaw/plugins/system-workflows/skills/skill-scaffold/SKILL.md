---
name: skill-scaffold
description: Scaffold new OpenClaw skills with correct directory structure, SKILL.md, and run.ts template.
user-invocable: false
---

## When to Use

Use this skill when:
- You need to create a new reusable CLI tool / skill
- You find yourself doing the same manual task repeatedly across sessions
- You want to automate something that should be a standalone skill
- You need to build a utility that cron jobs or the agent can invoke

## When NOT to Use

**NEVER do any of these instead of using this skill:**
- Create scripts in random directories (workspace, /tmp, home)
- Write automation scripts without SKILL.md documentation
- Skip the CLI contract (JSON stdout, stderr diagnostics, --help, exit codes)
- Create tools outside `/etc/nixos/openclaw/skills/`

## Usage

```bash
./run.ts create --name "my-tool" --description "What this tool does"
./run.ts --help
```

## What It Creates

```
/etc/nixos/openclaw/skills/<name>/
├── SKILL.md    # Discovery doc (edit triggers and examples after scaffolding)
└── run.ts      # Executable CLI template (implement your logic here)
```

## After Scaffolding

1. Edit `SKILL.md` — add "When to use" triggers, examples, output format
2. Implement logic in `run.ts` — the template has parseArgs, help, JSON output ready
3. Add a symlink in `module.nix` (the skill tells you the exact line to add)
4. Run `bun install` if the skill needs external packages (add a `package.json`)
5. Rebuild: `sudo /run/current-system/sw/bin/nixos-rebuild switch --flake /etc/nixos#nixos`

## Output

```json
{ "action": "created", "name": "my-tool", "path": "/etc/nixos/openclaw/skills/my-tool", "files": ["SKILL.md", "run.ts"], "nextSteps": ["Edit SKILL.md with triggers and examples", "Implement logic in run.ts", "Add symlink to module.nix"] }
```
