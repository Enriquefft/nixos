#!/usr/bin/env bun

import { parseArgs } from "util";
import { readdirSync, existsSync } from "fs";
import { join } from "path";

const PROJECTS_DIR = join(process.env.HOME || "~", "Projects");

const { values } = parseArgs({
  args: Bun.argv.slice(2),
  options: {
    help: { type: "boolean", short: "h" },
    since: { type: "string", short: "s" },
    repos: { type: "string", short: "r" },
  },
  allowPositionals: false,
});

if (values.help) {
  console.error(`git-activity — Summarize recent git activity across ~/Projects/

Usage:
  ./run.ts [--since yesterday] [--repos repo1,repo2]

Options:
  --since <when>   Git log --since value (default: yesterday)
  --repos <list>   Comma-separated repo names (default: all in ~/Projects/)
  -h, --help       Show this help

Output: JSON array of { repo, branch, commits: [{ hash, message, author, date }] }
Exit:   0 on success, 1 on error (details on stderr)`);
  process.exit(0);
}

const since = values.since || "yesterday";
const repoFilter = values.repos?.split(",") || null;

interface Commit {
  hash: string;
  message: string;
  author: string;
  date: string;
}

interface RepoActivity {
  repo: string;
  branch: string;
  commits: Commit[];
}

async function getRepoActivity(repoPath: string): Promise<RepoActivity | null> {
  const gitDir = join(repoPath, ".git");
  if (!existsSync(gitDir)) return null;

  try {
    const branchProc = Bun.spawn(["git", "-C", repoPath, "branch", "--show-current"], {
      stdout: "pipe",
      stderr: "pipe",
    });
    const branch = (await new Response(branchProc.stdout).text()).trim();

    const logProc = Bun.spawn(
      [
        "git", "-C", repoPath, "log",
        `--since=${since}`,
        "--format=%H\t%s\t%an\t%aI",
        "--no-merges",
      ],
      { stdout: "pipe", stderr: "pipe" }
    );
    const logOutput = (await new Response(logProc.stdout).text()).trim();

    if (!logOutput) return null;

    const commits: Commit[] = logOutput.split("\n").map((line) => {
      const [hash, message, author, date] = line.split("\t");
      return { hash: hash.slice(0, 8), message, author, date };
    });

    return {
      repo: repoPath.split("/").pop() || "",
      branch,
      commits,
    };
  } catch {
    return null;
  }
}

const dirs = repoFilter
  ? repoFilter.map((r) => join(PROJECTS_DIR, r))
  : readdirSync(PROJECTS_DIR, { withFileTypes: true })
      .filter((d) => d.isDirectory())
      .map((d) => join(PROJECTS_DIR, d.name));

const results: RepoActivity[] = [];
for (const dir of dirs) {
  const activity = await getRepoActivity(dir);
  if (activity && activity.commits.length > 0) {
    results.push(activity);
  }
}

console.log(JSON.stringify(results, null, 2));
