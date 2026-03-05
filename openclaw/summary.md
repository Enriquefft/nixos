  OpenClaw — Architecture Overview

  OpenClaw is a personal AI agent system ("Kiro") that acts as a chief of staff — job search, content creation, research tracking, and task automation, communicating via
  WhatsApp.

  ---
  Structure

  openclaw/
  ├── module.nix              # Home-manager config (services, symlinks, providers)
  ├── CLAUDE.md               # Architecture guide
  ├── cron/jobs/              # 13 YAML-based scheduled agent sessions
  ├── documents/              # Kiro's "brain" — identity, behavior, priorities
  ├── skills/                 # CLI tools invoked by cron prompts
  ├── plugins/system-workflows/ # Workflow enforcement hooks + scaffolding skills
  └── reference/              # Cover letter templates, full profile

  ---
  The 13 Cron Jobs

  All cron sessions are full LLM agent runs — not scripts. The YAML prompt is self-contained instructions.

  ┌────────────────────────┬────────────────────────┬────────────────────────────────────────────────────────────────┐
  │          Job           │        Schedule        │                          What it does                          │
  ├────────────────────────┼────────────────────────┼────────────────────────────────────────────────────────────────┤
  │ Morning Briefing       │ 7 AM M-F               │ Email scan, follow-ups due, git activity, task queue status    │
  ├────────────────────────┼────────────────────────┼────────────────────────────────────────────────────────────────┤
  │ Job Scan AM            │ 8 AM daily             │ Scrape 3 job boards, track top 5 in job-tracker                │
  ├────────────────────────┼────────────────────────┼────────────────────────────────────────────────────────────────┤
  │ Content Scout          │ 8:30 AM daily          │ RSS scan (HN, Reddit), find 3-5 content opportunities          │
  ├────────────────────────┼────────────────────────┼────────────────────────────────────────────────────────────────┤
  │ Skill Scan             │ 9 AM daily             │ 5-axis self-audit: capability gaps, platform changes, research │
  ├────────────────────────┼────────────────────────┼────────────────────────────────────────────────────────────────┤
  │ Paper Scout            │ 9 AM Wed+Sat           │ arXiv/HuggingFace papers on AI agents & LLMs                   │
  ├────────────────────────┼────────────────────────┼────────────────────────────────────────────────────────────────┤
  │ Follow-Up Enforcer     │ 2 PM daily             │ Chase 5-day-old applications, draft follow-ups                 │
  ├────────────────────────┼────────────────────────┼────────────────────────────────────────────────────────────────┤
  │ Build-in-Public        │ 6 PM daily             │ git-activity → draft X/LinkedIn posts                          │
  ├────────────────────────┼────────────────────────┼────────────────────────────────────────────────────────────────┤
  │ Job Scan PM            │ 8 PM daily             │ Same as AM scan for afternoon postings                         │
  ├────────────────────────┼────────────────────────┼────────────────────────────────────────────────────────────────┤
  │ End-of-Day             │ 9 PM daily             │ Recap vs morning goals, report blockers                        │
  ├────────────────────────┼────────────────────────┼────────────────────────────────────────────────────────────────┤
  │ Task Worker            │ 10:30 AM / 3:30 / 7:30 │ Drain task queue (max 2 items/run)                             │
  ├────────────────────────┼────────────────────────┼────────────────────────────────────────────────────────────────┤
  │ Self-Audit             │ 10:30 AM Sunday        │ Weekly review of all systems                                  │
  ├────────────────────────┼────────────────────────┼────────────────────────────────────────────────────────────────┤
  │ Target Company Refresh │ 10 AM Sunday           │ Research + update LORE.md target companies                     │
  └────────────────────────┴────────────────────────┴────────────────────────────────────────────────────────────────┘

  ---
  Skills (CLI tools used by cron)

  ┌───────────────────┬─────────────┬───────────────────────────────────────────────────────────────────┐
  │       Skill       │   Status    │                           What it does                     │
  ├───────────────────┼─────────────┼───────────────────────────────────────────────────────────────────┤
  │ job-scanner       │ Implemented │ RemoteOK, WeWorkRemotely, HN job boards                     │
  ├───────────────────┼─────────────┼───────────────────────────────────────────────────────────────────┤
  │ job-tracker       │ Implemented │ CRUD on job applications (new/applied/followed-up/rejected/offer) │
  ├───────────────────┼─────────────┼───────────────────────────────────────────────────────────────────┤
  │ task-queue        │ Implemented │ Persistent queue: issues, tasks, improvements, follow-ups         │
  ├───────────────────┼─────────────┼───────────────────────────────────────────────────────────────────┤
  │ rss-reader        │ Implemented │ arXiv, HuggingFace, HN, Reddit feeds                     │
  ├───────────────────┼─────────────┼───────────────────────────────────────────────────────────────────┤
  │ git-activity      │ Implemented │ Summarize commits across ~/Projects/                     │
  ├───────────────────┼─────────────┼───────────────────────────────────────────────────────────────────┤
  │ track-price-drops │ Stub        │ BTC/asset price alerts via CoinGecko (not implemented)            │
  ├───────────────────┼─────────────┼───────────────────────────────────────────────────────────────────┤
  │ cron-manager      │ Plugin      │ Create/edit cron YAML + run cron-sync                     │
  ├───────────────────┼─────────────┼───────────────────────────────────────────────────────────────────┤
  │ skill-scaffold    │ Plugin      │ Scaffold new skill with SKILL.md + run.ts                     │
  └───────────────────┴─────────────┴───────────────────────────────────────────────────────────────────┘

  All skills: Bun/TypeScript, JSON stdout, state in ~/.local/state/openclaw-cron/<skill>/.

  ---
  Document Brain (7 files)

  ┌───────────────────────┬──────────────────────────────────────────────────────────────────────────────┐
  │          Doc          │                                   Purpose                      │
  ├───────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
  │ IDENTITY.md           │ Kiro = chief of staff, speaks Spanish casually / English professionally      │
  ├───────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
  │ SOUL.md               │ Personality (sharp, no-nonsense), voice rules, banned words list             │
  ├───────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
  │ AGENTS.md             │ Operational directives: approval gates, system-first routing, priority stack │
  ├───────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
  │ TOOLS.md              │ Inventory of available CLI tools, APIs, capabilities                      │
  ├───────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
  │ USER.md               │ Enrique's profile — contact, skills, job situation, runway                   │
  ├───────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
  │ LORE.md               │ Job search strategy, target companies, products, content pillars, lessons    │
  ├───────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
  │ PROMPTING-EXAMPLES.md │ Concrete before/after examples of correct agent behavior                     │
  └───────────────────────┴──────────────────────────────────────────────────────────────────────────────┘

  ---
  Key Architectural Principles

  1. System-First Rule — every task maps to a system: Cron / Skills / Task Queue /NixOS. Use the right one.
  2. LLM-First Cron — every cron run is a full agent session. Scripts are tools, not the infrastructure.
  3. No ad-hoc automation — cron-manager only, never raw crontab or systemd timers.
  4. Live skill edits — skills symlinked via mkOutOfStoreSymlink, edit and run without rebuilding.
  5. Approval gates — outbound actions (messages, posts, applications) require approval. Internal work doesn't.
  6. Task queue as truth — every issue/task/improvement filed there, never droppedsilently.



  Plugin System

  Plugins are in-process extensions registered via plugin.json. The manifest declares:
  - skills[] — additional skill directories the plugin contributes
  - hooks — path to hooks.json

  // plugin.json
  {
    "name": "system-workflows",
    "skills": ["skills/cron-manager", "skills/skill-scaffold"],
    "hooks": "hooks/hooks.json"
  }

  What plugins can do:
  - Intercept/modify tool calls (before_tool_call, after_tool_call)
  - Intercept messages (inbound before LLM, outbound before delivery)
  - Register tools, CLI commands, services, HTTP endpoints, skills

  What plugins cannot do:
  - Modify the system prompt
  - Add/remove tools mid-session
  - Modify tool call results
  - Override core auth

  The only plugin in openclaw/ is system-workflows, whose sole job is workflow enforcement — making sure the agent never goes rogue with ad-hoc scripts.

  ---
  Hook System

  Two hooks, modeled on the Claude Code hooks API shape (JSON stdin/stdout, exit codes for control):

  Hook 1 — UserPromptSubmit → intent-detector.sh

  Fires on every inbound message. Does keyword matching on the lowercased message text across three intent categories:

  ┌─────────────────┬────────────────────────────────────────────────────────────────────┬──────────────────────────────────────────────────────┐
  │    Category     │                          Example triggers      │                   What it injects                    │
  ├─────────────────┼────────────────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────┤
  │ Scheduling      │ "every morning", "track", "alert me", "price drop", "monitor"      │ Step-by-step plan→build→create workflow instructions │
  ├─────────────────┼────────────────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────┤
  │ Skill creation  │ "create a tool", "automate this", "I always have to", "scaffold a" │ Redirects to skill-scaffold with correct paths       │
  ├─────────────────┼────────────────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────┤
  │ Task assignment │ "today fix", "add to queue", "todo:", "no te olvides", "hoy haz"   │ Forces task-queue add before execution               │
  └─────────────────┴────────────────────────────────────────────────────────────────────┴──────────────────────────────────────────────────────┘

  Output: { "additionalContext": "⚡ SCHEDULING WORKFLOW — ..." } injected into the LLM context before it responds. Exit 0 always (injects, never blocks).

  Hook 2 — PreToolUse (Bash/Write/Edit) → tool-guard.sh

  Fires before any Bash, Write, or Edit tool call. Inspects the command/file path and hard-blocks (exit 2) if the agent is trying to bypass a protected workflow:

  ┌──────────────────────────────────────────────────────────┬───────────────────────────────────────────────────┐
  │                     Blocked pattern                      │               Reason shown to agent               │
  ├──────────────────────────────────────────────────────────┼───────────────────────────────────────────────────┤
  │ Write to jobs.json directly                              │ Use cron-manager create                           │
  ├──────────────────────────────────────────────────────────┼───────────────────────────────────────────────────┤
  │ openclaw cron add/edit/rm                                │ Use cron-manager, keeps YAML in git               │
  ├──────────────────────────────────────────────────────────┼───────────────────────────────────────────────────┤
  │ crontab -e or systemd timer creation                     │ Use cron-manager, cron runs as full agent session │
  ├──────────────────────────────────────────────────────────┼───────────────────────────────────────────────────┤
  │ Python import schedule / apscheduler / while sleep loops │ Use cron-manager                              │
  ├──────────────────────────────────────────────────────────┼───────────────────────────────────────────────────┤
  │ Write to tasks.json directly                             │ Use task-queue add                              │
  ├──────────────────────────────────────────────────────────┼───────────────────────────────────────────────────┤
  │ SKILL.md created outside openclaw/skills/                │ Use skill-scaffold                              │
  └──────────────────────────────────────────────────────────┴───────────────────────────────────────────────────┘

  Whitelist exceptions: cron-sync itself and cron-manager/run.ts are always allowed through.

  The API shape:
  stdin:  { "tool_name": "Bash", "tool_input": { "command": "..." } }
  stdout: { "decision": "allow" } | { "decision": "deny", "reason": "..." }
  exit 0: allow | exit 2: deny

  ---
  Auto-Evolutive / Self-Repair Features

  This is the most interesting part — it's a four-layer self-modification system:

  Layer 1 — Self-Repair Protocol (AGENTS.md)

  When any tool, skill, or config is broken:

  1. File → task-queue add --title "<what's broken>" --type issue ... (immediate, mandatory)
  2. Attempt fix → launch a Claude Code session if code change needed, or edit config directly
  3. Update → task-queue resolve <id> if fixed, leave pending if not
  4. Report → "fixed: [what]" in next WhatsApp summary. No approval needed for internal fixes.
  5. Fall back → proceed manually, task worker retries later

  The key rule: filing is not optional. Every discovered failure goes in the queueas a durable record — not chat history, not memory.

  Layer 2 — Proactive Skill Creation (AGENTS.md)

  "When to create a new skill: if you catch yourself doing the same manual task (web scraping, data formatting, API call) across multiple cron sessions, create a skill
  for it."

  The agent is explicitly instructed to detect its own repetitive patterns and convert them into proper skills, autonomously, without asking.

  Layer 3 — Self-Document Editing (TOOLS.md)

  The agent has write access to its own brain:
  1. Edit files in /etc/nixos/openclaw/documents/
     (IDENTITY.md, SOUL.md, AGENTS.md, USER.md, TOOLS.md, LORE.md, PROMPTING-EXAMPLES.md)
  2. Run `up` to apply
  3. Document-only changes don't trigger a Go rebuild, just a symlink update

  Use cases:
  - Update its own instructions as it learns preferences
  - Add newly discovered tools/capabilities
  - Refine behavior based on feedback

  Caveat: TOOLS.md says "send proposed changes to Enrique for approval before editing" — so self-doc edits have an approval gate, unlike skill self-repair.

  Layer 4 — Proactive Triggers (AGENTS.md)

  Outside scheduled cron hours, the agent can fire on its own if:

  ┌────────────────────────────┬────────────────────────────────────────────────────────┐
  │          Trigger           │                         Action     │
  ├────────────────────────────┼────────────────────────────────────────────────────────┤
  │ Hot job match found        │ Surface immediately, don't wait for next digest     │
  ├────────────────────────────┼────────────────────────────────────────────────────────┤
  │ Topic trending in niche    │ Draft response now     │
  ├────────────────────────────┼────────────────────────────────────────────────────────┤
  │ Task stale 3+ days         │ Nudge Enrique     │
  ├────────────────────────────┼────────────────────────────────────────────────────────┤
  │ Queue >30 pending tasks    │ Send triage request     │
  ├────────────────────────────┼────────────────────────────────────────────────────────┤
  │ Task failed 3 times        │ Escalate with details     │
  ├────────────────────────────┼────────────────────────────────────────────────────────┤
  │ Inbound opportunity        │ Flag immediately     │
  ├────────────────────────────┼────────────────────────────────────────────────────────┤
  │ Config improvement spotted │ Implement it, report what changed (no approval needed) │
  └────────────────────────────┴────────────────────────────────────────────────────────┘

  ---
  How It All Connects

  User message (WhatsApp)
       ↓
  UserPromptSubmit hook → intent-detector.sh
       → detect: scheduling? skill? task?
       → inject workflow instructions into LLM context
       ↓
  LLM generates tool call
       ↓
  PreToolUse hook → tool-guard.sh
       → block: ad-hoc cron/task/skill bypasses
       → allow: legitimate operations
       ↓
  Tool executes
       ↓
  If tool fails → Self-Repair Protocol fires
       → file in task-queue
       → attempt fix via Claude Code
       → report in next summary

  The design goal: the agent cannot accidentally build parallel infrastructure. Every path toward scheduling, skill creation, or task tracking is intercepted and
  redirected to the canonical system. And when something breaks, it files the issue and tries to fix itself before surfacing it to the user.
