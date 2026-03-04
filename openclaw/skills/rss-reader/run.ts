#!/usr/bin/env bun

import { parseArgs } from "util";

const { values } = parseArgs({
  args: Bun.argv.slice(2),
  options: {
    help: { type: "boolean", short: "h" },
    feeds: { type: "string", short: "f" },
    since: { type: "string", short: "s" },
    limit: { type: "string", short: "l" },
  },
  allowPositionals: false,
});

if (values.help) {
  console.error(`rss-reader — Fetch and parse RSS/Atom feeds

Usage:
  ./run.ts [--feeds arxiv,hn,reddit] [--since 24h] [--limit 20]

Options:
  --feeds <list>   Comma-separated feed names (default: all configured)
  --since <dur>    Only include items newer than duration (e.g., 24h, 7d)
  --limit <n>      Max results to return (default: 20)
  -h, --help       Show this help

Output: JSON array of { title, url, source, published, summary } to stdout
Exit:   0 on success, 1 on error (details on stderr)`);
  process.exit(0);
}

// TODO: Implement RSS/Atom feed fetching and parsing
const results: object[] = [];
console.log(JSON.stringify(results, null, 2));
