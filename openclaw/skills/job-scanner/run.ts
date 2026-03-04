#!/usr/bin/env bun

import { parseArgs } from "util";

const { values } = parseArgs({
  args: Bun.argv.slice(2),
  options: {
    help: { type: "boolean", short: "h" },
    boards: { type: "string", short: "b" },
    "remote-only": { type: "boolean" },
    limit: { type: "string", short: "l" },
  },
  allowPositionals: false,
});

if (values.help) {
  console.error(`job-scanner — Fetch and filter job board listings

Usage:
  ./run.ts [--boards linkedin,indeed] [--remote-only] [--limit 20]

Options:
  --boards <list>   Comma-separated board names (default: all configured)
  --remote-only     Only include remote-friendly positions
  --limit <n>       Max results to return (default: 20)
  -h, --help        Show this help

Output: JSON array of { title, company, url, location, posted } to stdout
Exit:   0 on success, 1 on error (details on stderr)`);
  process.exit(0);
}

// TODO: Implement actual board scanning
// This stub returns an empty array. The agent will build out
// the implementation as specific boards are configured.
const results: object[] = [];
console.log(JSON.stringify(results, null, 2));
