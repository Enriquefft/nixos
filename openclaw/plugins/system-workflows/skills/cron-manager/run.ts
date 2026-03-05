#!/usr/bin/env bun

import { parseArgs } from "util";
import {
  existsSync,
  readFileSync,
  writeFileSync,
  unlinkSync,
  readdirSync,
  mkdirSync,
} from "fs";
import { join, basename } from "path";
import { execSync } from "child_process";

const CRON_DIR = "/etc/nixos/openclaw/cron";
const JOBS_DIR = join(CRON_DIR, "jobs");
const DEFAULTS_FILE = join(CRON_DIR, "defaults.yaml");
const JOBS_JSON = join(
  process.env.HOME || "~",
  ".openclaw/cron/jobs.json"
);
const ENV_FILE = "/run/secrets/rendered/openclaw.env";

// --- CLI ---

const { values, positionals } = parseArgs({
  args: Bun.argv.slice(2),
  options: {
    help: { type: "boolean", short: "h" },
    name: { type: "string", short: "n" },
    schedule: { type: "string", short: "s" },
    prompt: { type: "string", short: "p" },
    task: { type: "string", short: "t" },
    requires: { type: "string", short: "r" },
    session: { type: "string" },
    verbose: { type: "boolean", short: "v" },
  },
  allowPositionals: true,
});

const command = positionals[0];

if (values.help || !command) {
  console.error(`cron-manager — Manage OpenClaw cron jobs via YAML + cron-sync

Usage:
  ./run.ts plan --task "Track BTC price, alert on 5% drop" --schedule "*/15 * * * *"
  ./run.ts create --name "Name" --schedule "0 8 * * *" --prompt "Instructions" [--requires skill1,skill2]
  ./run.ts edit --name "Name" [--schedule "..."] [--prompt "..."] [--session main|isolated]
  ./run.ts remove --name "Name"
  ./run.ts list [--verbose]
  ./run.ts test --name "Name"

Workflow: plan → build skill if needed → create → verify

Options:
  --task, -t       Task description in natural language (for plan)
  --name, -n       Job name (required for create/edit/remove/test)
  --schedule, -s   Cron expression (required for create/plan)
  --prompt, -p     Agent prompt (required for create)
  --requires, -r   Comma-separated skill names that must exist (for create)
  --session        Session type: main (default) or isolated
  --verbose, -v    Show full prompt in list output
  -h, --help       Show this help

Each cron job runs as a full AI agent session with all tools.
All jobs are version-controlled YAML in /etc/nixos/openclaw/cron/jobs/.
Exit: 0 on success, 1 on error (details on stderr)`);
  process.exit(values.help ? 0 : 1);
}

// --- Helpers ---

function slugify(name: string): string {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

function yq(expression: string, file: string): string {
  return execSync(`yq -r '${expression}' "${file}"`, {
    encoding: "utf-8",
  }).trim();
}

function findYamlByName(name: string): string | null {
  const files = readdirSync(JOBS_DIR).filter((f) => f.endsWith(".yaml"));
  for (const file of files) {
    const filePath = join(JOBS_DIR, file);
    const jobName = yq(".name", filePath);
    if (jobName === name) return filePath;
  }
  return null;
}

function runCronSync(extraArgs: string = ""): string {
  const cmd = `cron-sync ${extraArgs}`.trim();
  return execSync(cmd, { encoding: "utf-8", timeout: 30_000 }).trim();
}

function loadDefaults(): { timezone: string; session: string } {
  return {
    timezone: yq(".timezone", DEFAULTS_FILE),
    session: yq(".session", DEFAULTS_FILE),
  };
}

function validateCronExpr(expr: string): boolean {
  const parts = expr.split(/\s+/);
  return parts.length === 5;
}

const SKILLS_DIR = "/etc/nixos/openclaw/skills";

function estimateRunsPerDay(schedule: string): number {
  const parts = schedule.split(/\s+/);
  if (parts.length !== 5) return -1;
  const [minute, hour, dayOfMonth, month, dayOfWeek] = parts;

  // Step-based minute: */N
  const stepMatch = minute.match(/^\*\/(\d+)$/);
  if (stepMatch) {
    const interval = parseInt(stepMatch[1]);
    const runsPerHour = Math.floor(60 / interval);
    if (hour === "*") return runsPerHour * 24;
    // specific hours
    const hours = countCronField(hour, 24);
    return runsPerHour * hours;
  }

  // Hourly: minute is fixed, hour is *
  if (hour === "*") return 24;

  // Specific hours
  const hours = countCronField(hour, 24);
  const minutes = countCronField(minute, 60);

  let daysPerWeek = 7;
  if (dayOfWeek !== "*") {
    daysPerWeek = countCronField(dayOfWeek, 7);
  }

  const runsPerDay = hours * minutes;
  if (daysPerWeek < 7) {
    return Math.round((runsPerDay * daysPerWeek) / 7 * 10) / 10;
  }
  return runsPerDay;
}

function countCronField(field: string, max: number): number {
  if (field === "*") return max;
  // comma-separated: 1,5,10
  if (field.includes(",")) return field.split(",").length;
  // range: 1-5
  const rangeMatch = field.match(/^(\d+)-(\d+)$/);
  if (rangeMatch) return parseInt(rangeMatch[2]) - parseInt(rangeMatch[1]) + 1;
  // step: */N
  const stepMatch = field.match(/^\*\/(\d+)$/);
  if (stepMatch) return Math.floor(max / parseInt(stepMatch[1]));
  // single value
  return 1;
}

type Tier = "script-only" | "script-agent" | "agent-only";

const MONITORING_KEYWORDS = [
  "monitor", "track", "alert", "price", "check", "watch",
  "detect", "threshold", "uptime", "ping", "notify if",
  "notify when", "drops", "rises", "changes",
];
const DIGEST_KEYWORDS = [
  "scan", "digest", "summarize", "report", "compile",
  "list", "fetch", "scout", "briefing", "overview",
];
const REASONING_KEYWORDS = [
  "review", "audit", "draft", "research", "compare",
  "analyze", "propose", "evaluate", "improve", "reflect",
];

function classifyTier(task: string, runsPerDay: number): { tier: Tier; reason: string } {
  const lower = task.toLowerCase();
  const isMonitoring = MONITORING_KEYWORDS.some((k) => lower.includes(k));
  const isDigest = DIGEST_KEYWORDS.some((k) => lower.includes(k));
  const isReasoning = REASONING_KEYWORDS.some((k) => lower.includes(k));

  // High frequency + monitoring = must be script-only
  if (runsPerDay > 4 && isMonitoring) {
    return {
      tier: "script-only",
      reason: `High-frequency monitoring (${runsPerDay} runs/day). A skill should handle the check; agent only fires on exceptions.`,
    };
  }
  if (isMonitoring && !isReasoning) {
    return {
      tier: "script-only",
      reason: "Monitoring/alerting task. Deterministic checks should be code, agent only handles notifications.",
    };
  }
  if (isDigest && !isReasoning) {
    return {
      tier: "script-agent",
      reason: "Data gathering + digest. Skill fetches structured data, agent interprets and drafts human-readable output.",
    };
  }
  if (isDigest && isReasoning) {
    return {
      tier: "script-agent",
      reason: "Mixed data + reasoning. Skill handles data collection, agent handles analysis and drafting.",
    };
  }
  if (isReasoning) {
    return {
      tier: "agent-only",
      reason: "Reasoning-heavy task requiring judgment, browsing, or document analysis. Full agent session appropriate.",
    };
  }
  // Default: if high frequency, lean toward script
  if (runsPerDay > 4) {
    return {
      tier: "script-agent",
      reason: `Runs ${runsPerDay}x/day. Consider a backing skill to reduce per-session cost.`,
    };
  }
  return {
    tier: "agent-only",
    reason: "General task with low frequency. Full agent session is acceptable.",
  };
}

function generateSkillSpec(task: string): Record<string, unknown> | null {
  const lower = task.toLowerCase();

  // Extract action keywords for naming
  const actionWords = lower
    .replace(/[^a-z0-9\s]/g, "")
    .split(/\s+/)
    .filter((w) => w.length > 3)
    .filter((w) => !["the", "and", "for", "from", "with", "that", "this", "when", "then", "more", "than", "alert", "tell", "want", "every", "hour", "minute", "daily"].includes(w))
    .slice(0, 3);

  const suggestedName = actionWords.join("-") || "custom-checker";

  return {
    needed: true,
    suggestedName,
    description: `Automation skill for: ${task.slice(0, 100)}`,
    suggestedInterface: `./run.ts check [relevant flags]`,
    outputContract: `{ "result": "...", "alert": boolean, "data": {} }`,
    notes: "Implement with direct API calls or lightweight data fetching. Avoid web scraping when APIs exist.",
  };
}

function generateSuggestedPrompt(
  tier: Tier,
  task: string,
  skillSpec: Record<string, unknown> | null
): string {
  const skillName = skillSpec?.suggestedName || "skill-name";

  if (tier === "script-only") {
    return [
      `Run \`${skillName} check\`. Read the JSON result.`,
      `If result shows no action needed (alert: false), end session silently.`,
      `If result shows action needed (alert: true), send the details to Enrique via WhatsApp.`,
    ].join("\n");
  }

  if (tier === "script-agent") {
    return [
      `Run \`${skillName}\` to fetch structured data. Parse the JSON output.`,
      `Analyze and filter the results based on relevance.`,
      `Draft a concise digest/summary for Enrique.`,
      `Send to Enrique via WhatsApp. Approval required before sending.`,
    ].join("\n");
  }

  // agent-only: return the task as-is, it's meant for full reasoning
  return task;
}

function getCostWarning(runsPerDay: number): string | null {
  if (runsPerDay > 24) {
    return `${runsPerDay} agent sessions/day is very expensive. A backing skill is REQUIRED to keep sessions minimal. Consider reducing frequency too.`;
  }
  if (runsPerDay > 4) {
    return `${runsPerDay} agent sessions/day is moderate. A backing skill is recommended to reduce per-session token usage.`;
  }
  return null;
}

function skillExists(name: string): boolean {
  return existsSync(join(SKILLS_DIR, name));
}

function output(data: Record<string, unknown>): void {
  console.log(JSON.stringify(data, null, 2));
}

function fail(message: string): never {
  console.error(`error: ${message}`);
  process.exit(1);
}

// --- Commands ---

function cmdPlan() {
  const { task, schedule } = values;
  if (!task) fail("--task is required");
  if (!schedule) fail("--schedule is required");
  if (!validateCronExpr(schedule))
    fail(`Invalid cron expression: "${schedule}" (expected 5 fields)`);

  const runsPerDay = estimateRunsPerDay(schedule);
  const { tier, reason } = classifyTier(task, runsPerDay);
  const costWarning = getCostWarning(runsPerDay);

  const needsSkill = tier === "script-only" || tier === "script-agent";
  const skillSpec = needsSkill ? generateSkillSpec(task) : null;
  const suggestedPrompt = generateSuggestedPrompt(tier, task, skillSpec);

  // Check if suggested skill already exists
  if (skillSpec) {
    const name = skillSpec.suggestedName as string;
    if (skillExists(name)) {
      (skillSpec as any).needed = false;
      (skillSpec as any).exists = true;
      (skillSpec as any).notes = `Skill '${name}' already exists. Use it in the prompt.`;
    }
  }

  const approvalGate =
    task.toLowerCase().includes("send") ||
    task.toLowerCase().includes("message") ||
    task.toLowerCase().includes("whatsapp") ||
    task.toLowerCase().includes("post") ||
    task.toLowerCase().includes("alert");

  output({
    action: "plan",
    tier,
    tierReason: reason,
    schedule: { expr: schedule, runsPerDay },
    ...(costWarning ? { costWarning } : {}),
    ...(skillSpec ? { skillSpec } : {}),
    suggestedPrompt,
    approvalGate,
    workflow: needsSkill && skillSpec && (skillSpec as any).needed
      ? [
          `1. Create skill: skill-scaffold create --name "${(skillSpec as any).suggestedName}" --description "${(skillSpec as any).description}"`,
          `2. Implement the skill logic in skills/${(skillSpec as any).suggestedName}/run.ts`,
          `3. Test: ./skills/${(skillSpec as any).suggestedName}/run.ts --help`,
          `4. Add symlink to module.nix, rebuild`,
          `5. Create cron job: cron-manager create --name "..." --schedule "${schedule}" --requires ${(skillSpec as any).suggestedName} --prompt "..."`,
        ]
      : [
          `1. Create cron job: cron-manager create --name "..." --schedule "${schedule}" --prompt "..."`,
        ],
  });
}

function cmdCreate() {
  const { name, schedule, prompt, session } = values;
  const requires = values.requires;
  if (!name) fail("--name is required");
  if (!schedule) fail("--schedule is required");
  if (!prompt) fail("--prompt is required");
  if (!validateCronExpr(schedule))
    fail(`Invalid cron expression: "${schedule}" (expected 5 fields)`);

  // Validate required skills exist
  if (requires) {
    const skills = requires.split(",").map((s) => s.trim()).filter(Boolean);
    for (const skill of skills) {
      if (!skillExists(skill)) {
        fail(
          `Required skill '${skill}' not found in ${SKILLS_DIR}/. ` +
          `Create it first: skill-scaffold create --name "${skill}" --description "..."`
        );
      }
    }
  }
  const existing = findYamlByName(name);
  if (existing) fail(`Job "${name}" already exists at ${basename(existing)}`);

  const defaults = loadDefaults();
  const sessionType = session || defaults.session;
  const slug = slugify(name);
  const fileName = `${slug}.yaml`;
  const filePath = join(JOBS_DIR, fileName);

  const yaml = [
    `name: "${name}"`,
    `schedule: "${schedule}"`,
    ...(sessionType !== defaults.session
      ? [`session: ${sessionType}`]
      : []),
    "",
    "prompt: |",
    ...prompt.split("\n").map((line) => `  ${line}`),
    "",
  ].join("\n");

  writeFileSync(filePath, yaml);

  let syncResult: string;
  try {
    syncResult = runCronSync();
  } catch (e: any) {
    // Sync failed — remove the YAML we just created to avoid orphans
    unlinkSync(filePath);
    fail(`cron-sync failed: ${e.message}`);
  }

  // Stage the new YAML in git
  try {
    execSync(`git -C "${CRON_DIR}" add "jobs/${fileName}"`, { encoding: "utf-8" });
  } catch {
    // Non-fatal: git-add failure shouldn't block cron creation
    console.error(`warning: git add failed for ${fileName}`);
  }

  output({
    action: "created",
    name,
    file: fileName,
    schedule,
    session: sessionType,
    ...(requires ? { requires: requires.split(",").map((s) => s.trim()) } : {}),
    syncResult,
  });
}

function cmdEdit() {
  const { name, schedule, prompt, session } = values;
  if (!name) fail("--name is required");

  const filePath = findYamlByName(name);
  if (!filePath) fail(`Job "${name}" not found in ${JOBS_DIR}`);

  if (!schedule && !prompt && !session)
    fail("At least one of --schedule, --prompt, or --session is required");

  if (schedule && !validateCronExpr(schedule))
    fail(`Invalid cron expression: "${schedule}" (expected 5 fields)`);

  let content = readFileSync(filePath, "utf-8");
  const changes: string[] = [];

  if (schedule) {
    content = content.replace(
      /^schedule:\s*"[^"]*"/m,
      `schedule: "${schedule}"`
    );
    changes.push(`schedule → ${schedule}`);
  }

  if (session) {
    if (content.match(/^session:/m)) {
      content = content.replace(/^session:\s*\S+/m, `session: ${session}`);
    } else {
      // Insert session after schedule line
      content = content.replace(
        /^(schedule:.*\n)/m,
        `$1session: ${session}\n`
      );
    }
    changes.push(`session → ${session}`);
  }

  if (prompt) {
    // Replace everything from "prompt: |" to end of file
    const promptYaml = prompt
      .split("\n")
      .map((line) => `  ${line}`)
      .join("\n");
    content = content.replace(
      /^prompt:\s*\|[\s\S]*$/m,
      `prompt: |\n${promptYaml}\n`
    );
    changes.push("prompt updated");
  }

  writeFileSync(filePath, content);

  let syncResult: string;
  try {
    syncResult = runCronSync();
  } catch (e: any) {
    fail(`cron-sync failed after edit: ${e.message}`);
  }

  output({
    action: "updated",
    name,
    file: basename(filePath),
    changes,
    syncResult,
  });
}

function cmdRemove() {
  const { name } = values;
  if (!name) fail("--name is required");

  const filePath = findYamlByName(name);
  if (!filePath) fail(`Job "${name}" not found in ${JOBS_DIR}`);

  const fileName = basename(filePath);
  unlinkSync(filePath);

  let syncResult: string;
  try {
    syncResult = runCronSync("--remove-missing");
  } catch (e: any) {
    fail(`cron-sync --remove-missing failed: ${e.message}`);
  }

  output({ action: "removed", name, file: fileName, syncResult });
}

function cmdList() {
  const files = readdirSync(JOBS_DIR).filter((f) => f.endsWith(".yaml"));
  const jobs = files.map((file) => {
    const filePath = join(JOBS_DIR, file);
    const name = yq(".name", filePath);
    const schedule = yq(".schedule", filePath);
    const session = yq('.session // "default"', filePath);
    const prompt = yq(".prompt", filePath);

    const entry: Record<string, string> = {
      name,
      schedule,
      session,
      file,
    };
    if (values.verbose) {
      entry.prompt = prompt;
    } else {
      entry.prompt =
        prompt.length > 80 ? prompt.substring(0, 80) + "..." : prompt;
    }
    return entry;
  });

  output({ action: "list", count: jobs.length, jobs });
}

function cmdTest() {
  const { name } = values;
  if (!name) fail("--name is required");

  if (!existsSync(JOBS_JSON))
    fail(`jobs.json not found at ${JOBS_JSON}. Has cron-sync been run?`);

  const jobsData = JSON.parse(readFileSync(JOBS_JSON, "utf-8"));
  const job = jobsData.jobs?.find(
    (j: any) => j.name === name
  );
  if (!job) fail(`Job "${name}" not found in runtime state. Run cron-sync first.`);

  if (!existsSync(ENV_FILE))
    fail(`Secrets file not found at ${ENV_FILE}`);

  try {
    const result = execSync(
      `bash -c 'export $(cat ${ENV_FILE} | xargs) && openclaw cron run ${job.id}'`,
      { encoding: "utf-8", timeout: 60_000 }
    );
    output({ action: "tested", name, jobId: job.id, result: result.trim() });
  } catch (e: any) {
    fail(`Test run failed: ${e.message}`);
  }
}

// --- Dispatch ---

switch (command) {
  case "plan":
    cmdPlan();
    break;
  case "create":
    cmdCreate();
    break;
  case "edit":
    cmdEdit();
    break;
  case "remove":
    cmdRemove();
    break;
  case "list":
    cmdList();
    break;
  case "test":
    cmdTest();
    break;
  default:
    fail(`Unknown command: ${command}. Run with --help for usage.`);
}
