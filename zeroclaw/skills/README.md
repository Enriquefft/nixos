# Skills — Operational Guide

This guide covers everything needed to create, audit, install, and manage ZeroClaw skills. A skill is a self-contained package that extends Kiro's capabilities — either by injecting knowledge and instructions into the agent system prompt (SKILL.md format) or by registering custom shell tools (SKILL.toml format).

---

## Overview

### Two Supported Formats

| Format | Use When | Location After Install |
|--------|----------|----------------------|
| `SKILL.md` | Knowledge skills, behavioral instructions, prompt injection | `~/.zeroclaw/workspace/skills/<name>/` |
| `SKILL.toml` | Registering custom shell tools the agent can invoke | `~/.zeroclaw/workspace/skills/<name>/` |

**SKILL.md** is the simpler format and is recommended for most of Kiro's skills — any skill that teaches Kiro how to do something, follows a workflow, or injects context into the agent session.

**SKILL.toml** is needed when the skill provides a callable tool (a shell command Kiro can invoke during a session). It includes a `[[tools]]` block that registers the tool name, description, and command.

Both formats are supported simultaneously. A skill directory can include both files if needed.

**Source of truth:** `/etc/nixos/zeroclaw/skills/` — this is where skill source lives and where git tracks it.

**Installed workspace:** `~/.zeroclaw/workspace/skills/` — this is where ZeroClaw runtime reads installed skills. ZeroClaw manages this directory; do not edit it directly.

---

## Directory Structure

```
skills/
└── my-skill/               # skill root — name must be unique
    ├── SKILL.md            # required — frontmatter + markdown instructions
    ├── SKILL.toml          # optional — use when registering shell tools
    ├── scripts/            # optional — executable scripts the skill invokes
    ├── references/         # optional — context documents loaded into agent context
    └── assets/             # optional — templates, icons, static files
```

**Important:** All files inside a skill directory must be **regular files** — no symlinks allowed inside skill packages. The `zeroclaw skills audit` command will reject any skill that contains symlinks, even in subdirectories. Copy files; never symlink them.

Shell script files (`.sh`) also cannot be placed inside skill packages — the `zeroclaw skills audit` security policy rejects them. Scripts invoked by skill tools must live **outside** the skill directory. The established pattern is `/etc/nixos/zeroclaw/bin/<script>.sh`. Reference scripts via absolute path in the SKILL.toml `command` field.

When `zeroclaw skills install` succeeds, ZeroClaw also auto-generates `_meta.json` in the installed copy — this file is managed by ZeroClaw and should not be manually created or edited.

---

## SKILL.md Format

Use SKILL.md when you want to inject instructions, knowledge, or behavioral guidance into the agent system prompt at runtime.

**Full annotated example:**

```markdown
---
name: morning-briefing
description: Runs Kiro's morning briefing session — job scan, task queue triage, overnight summary. Use when morning routine needs to run.
---

# Morning Briefing

Check overnight messages, triage task queue, scan for hot job listings.
Report findings to Enrique via WhatsApp.

## Steps

1. Run `zeroclaw cron list` to confirm cron system is healthy
2. Check task queue for items over 24h old
3. Scan job boards for new high-match listings
4. Compose summary and send via kapso-whatsapp-cli
```

**Frontmatter fields:**

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Unique skill identifier — must match directory name |
| `description` | Yes | One-line description of when and how to use this skill |

The `name` and `description` fields are injected into the agent system prompt at runtime, making the skill discoverable during a session. The markdown body provides the full instructions Kiro follows when activating the skill.

---

## SKILL.toml Format

Use SKILL.toml when the skill provides a callable shell tool the agent can invoke during a session. The `[[tools]]` block registers the tool name, its description (shown to the agent), and the shell command to execute.

**Full annotated example:**

```toml
[skill]
name = "job-scanner"
description = "Fetches and filters job listings from configured boards"
version = "0.1.0"
author = "kiro"
tags = ["job-search", "automation"]

[[tools]]
name = "scan_jobs"
description = "Scan job boards for new listings"
kind = "shell"
command = "node /etc/nixos/zeroclaw/skills/job-scanner/run.js"
```

**[skill] block fields:**

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Unique skill identifier |
| `description` | Yes | What this skill provides |
| `version` | No | Semver string |
| `author` | No | Who authored the skill |
| `tags` | No | Array of category strings |

**[[tools]] block fields:**

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Tool name the agent calls — use underscores, no spaces |
| `description` | Yes | Shown to the agent so it knows when to invoke this tool |
| `kind` | Yes | Always `"shell"` for native tools |
| `command` | Yes | Full shell command to execute when tool is invoked |

Use absolute paths in `command` — relative paths will break after install since the working directory is not guaranteed. A skill directory can include both SKILL.md (for instructions) and SKILL.toml (for tool registration) at the same time.

---

## Workflow — Creating and Installing a Skill

Follow these steps in order:

```bash
# Step 1: Create skill directory in the repo
mkdir -p /etc/nixos/zeroclaw/skills/my-skill

# Step 2: Write SKILL.md (minimum required)
# Edit /etc/nixos/zeroclaw/skills/my-skill/SKILL.md
# Add frontmatter (name, description) and markdown instructions

# Step 3: Add any scripts, references, or assets (optional)
# All files must be regular files — no symlinks

# Step 4: Audit the skill before installing (security check)
cd /etc/nixos/zeroclaw
zeroclaw skills audit ./skills/my-skill

# Step 5: Install into ZeroClaw workspace
zeroclaw skills install ./skills/my-skill

# Step 6: Verify the skill is listed
zeroclaw skills list

# Step 7: Commit to git (source of truth)
git add skills/my-skill/
git commit -m "feat(skills): add my-skill"
```

**What audit checks:** Symlinks inside the skill package, script injection patterns, prompt injection attempts. Always run audit before install — it is non-destructive.

**Where skills live after install:** `~/.zeroclaw/workspace/skills/my-skill/` — this is managed by ZeroClaw. The repo copy at `/etc/nixos/zeroclaw/skills/my-skill/` remains the source of truth.

**To update an installed skill:** Edit the source in the repo, re-run `zeroclaw skills audit` and `zeroclaw skills install` (install overwrites the existing version), then commit the change to git.

---

## CLI Quick Reference

| Command | Description |
|---------|-------------|
| `zeroclaw skills list` | List all installed skills with name, version, description |
| `zeroclaw skills audit <path>` | Security audit a skill before installing (required) |
| `zeroclaw skills install <path>` | Install a skill from a local directory path |
| `zeroclaw skills remove <name>` | Remove an installed skill by name |

**Path format:** Use relative paths from repo root (e.g., `./skills/my-skill`) or absolute paths (e.g., `/etc/nixos/zeroclaw/skills/my-skill`). Git URLs are also supported for installing upstream skills.
