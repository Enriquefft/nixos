#!/usr/bin/env bun

import { parseArgs } from "util";
import { existsSync, writeFileSync, mkdirSync, chmodSync } from "fs";
import { join } from "path";

const SKILLS_DIR = "/etc/nixos/openclaw/skills";

const { values, positionals } = parseArgs({
  args: Bun.argv.slice(2),
  options: {
    help: { type: "boolean", short: "h" },
    name: { type: "string", short: "n" },
    description: { type: "string", short: "d" },
  },
  allowPositionals: true,
});

const command = positionals[0];

if (values.help || !command) {
  console.error(`skill-scaffold — Scaffold new OpenClaw skills

Usage:
  ./run.ts create --name "my-tool" --description "What this tool does"

Options:
  --name, -n          Skill name (kebab-case, required)
  --description, -d   Short description (required)
  -h, --help          Show this help

Creates a new skill directory with SKILL.md and run.ts templates.
Exit: 0 on success, 1 on error (details on stderr)`);
  process.exit(values.help ? 0 : 1);
}

function fail(message: string): never {
  console.error(`error: ${message}`);
  process.exit(1);
}

function output(data: Record<string, unknown>): void {
  console.log(JSON.stringify(data, null, 2));
}

function generateSkillMd(name: string, description: string): string {
  return `---
name: ${name}
description: ${description}
user-invocable: false
---

## When to Use

<!-- Add trigger phrases that help the agent know when to use this skill -->

## Usage

\`\`\`bash
./run.ts --help
\`\`\`

## Options

<!-- Document CLI flags here -->

## Output

JSON to stdout:
\`\`\`json
[]
\`\`\`

## Examples

<!-- Add concrete usage examples -->

## State

\`~/.local/state/openclaw-cron/${name}/\` — state directory (create if needed).
`;
}

function generateRunTs(name: string, description: string): string {
  return `#!/usr/bin/env bun

import { parseArgs } from "util";
import { existsSync, readFileSync, writeFileSync, mkdirSync } from "fs";
import { join } from "path";

const STATE_DIR = join(process.env.HOME || "~", ".local/state/openclaw-cron/${name}");

const { values } = parseArgs({
  args: Bun.argv.slice(2),
  options: {
    help: { type: "boolean", short: "h" },
    // Add your options here
  },
  allowPositionals: false,
});

if (values.help) {
  console.error(\`${name} — ${description}

Usage:
  ./run.ts [options]

Options:
  -h, --help    Show this help

Output: JSON to stdout
Exit:   0 on success, 1 on error (details on stderr)\`);
  process.exit(0);
}

// Ensure state directory exists
if (!existsSync(STATE_DIR)) {
  mkdirSync(STATE_DIR, { recursive: true });
}

// --- Implementation ---

// TODO: Implement your skill logic here

const results: unknown[] = [];
console.log(JSON.stringify(results, null, 2));
`;
}

function cmdCreate() {
  const { name, description } = values;
  if (!name) fail("--name is required");
  if (!description) fail("--description is required");

  // Validate name format
  if (!/^[a-z][a-z0-9-]*$/.test(name))
    fail(
      `Invalid name "${name}". Use kebab-case starting with a letter (e.g., "my-tool")`
    );

  const skillDir = join(SKILLS_DIR, name);
  if (existsSync(skillDir))
    fail(`Skill directory already exists: ${skillDir}`);

  mkdirSync(skillDir, { recursive: true });

  const skillMdPath = join(skillDir, "SKILL.md");
  const runTsPath = join(skillDir, "run.ts");

  writeFileSync(skillMdPath, generateSkillMd(name, description));
  writeFileSync(runTsPath, generateRunTs(name, description));
  chmodSync(runTsPath, 0o755);

  const symlinkLine = `  home.file.".openclaw/workspace/skills/${name}".source =\n    config.lib.file.mkOutOfStoreSymlink "/etc/nixos/openclaw/skills/${name}";`;

  output({
    action: "created",
    name,
    path: skillDir,
    files: ["SKILL.md", "run.ts"],
    nextSteps: [
      "Edit SKILL.md — add 'When to use' triggers and examples",
      "Implement logic in run.ts",
      `Add to module.nix:\n${symlinkLine}`,
      "Rebuild: sudo /run/current-system/sw/bin/nixos-rebuild switch --flake /etc/nixos#nixos",
    ],
  });
}

switch (command) {
  case "create":
    cmdCreate();
    break;
  default:
    fail(`Unknown command: ${command}. Run with --help for usage.`);
}
