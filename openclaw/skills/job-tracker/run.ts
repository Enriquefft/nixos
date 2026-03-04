#!/usr/bin/env bun

import { parseArgs } from "util";
import { mkdirSync, existsSync, readFileSync, writeFileSync } from "fs";
import { join } from "path";
import { randomUUID } from "crypto";

const STATE_DIR = join(
  process.env.HOME || "~",
  ".local/state/openclaw-cron/job-tracker"
);
const DB_PATH = join(STATE_DIR, "jobs.json");

interface Job {
  id: string;
  title: string;
  company: string;
  url: string;
  status: string;
  addedAt: string;
  updatedAt: string;
}

function loadJobs(): Job[] {
  if (!existsSync(DB_PATH)) return [];
  return JSON.parse(readFileSync(DB_PATH, "utf-8"));
}

function saveJobs(jobs: Job[]): void {
  mkdirSync(STATE_DIR, { recursive: true });
  writeFileSync(DB_PATH, JSON.stringify(jobs, null, 2));
}

const args = Bun.argv.slice(2);
const command = args[0];

if (!command || command === "--help" || command === "-h") {
  console.error(`job-tracker — CRUD operations on job application tracking store

Usage:
  ./run.ts list [--status <status>] [--limit <n>]
  ./run.ts add --title "Role" --company "Co" --url "https://..."
  ./run.ts update <id> --status <status>

Statuses: new, applied, followed-up, rejected, offer, interviewing

Output: JSON to stdout
State:  ${DB_PATH}`);
  process.exit(0);
}

if (command === "list") {
  const { values } = parseArgs({
    args: args.slice(1),
    options: {
      status: { type: "string" },
      limit: { type: "string", short: "l" },
    },
    allowPositionals: false,
  });

  let jobs = loadJobs();
  if (values.status) jobs = jobs.filter((j) => j.status === values.status);
  if (values.limit) jobs = jobs.slice(0, parseInt(values.limit));
  console.log(JSON.stringify(jobs, null, 2));
} else if (command === "add") {
  const { values } = parseArgs({
    args: args.slice(1),
    options: {
      title: { type: "string" },
      company: { type: "string" },
      url: { type: "string" },
      status: { type: "string" },
    },
    allowPositionals: false,
  });

  if (!values.title || !values.company || !values.url) {
    console.error("Error: --title, --company, and --url are required");
    process.exit(1);
  }

  const jobs = loadJobs();
  const job: Job = {
    id: randomUUID(),
    title: values.title,
    company: values.company,
    url: values.url,
    status: values.status || "new",
    addedAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };
  jobs.push(job);
  saveJobs(jobs);
  console.log(JSON.stringify(job, null, 2));
} else if (command === "update") {
  const id = args[1];
  if (!id) {
    console.error("Error: job ID required");
    process.exit(1);
  }

  const { values } = parseArgs({
    args: args.slice(2),
    options: {
      status: { type: "string" },
      title: { type: "string" },
      company: { type: "string" },
      url: { type: "string" },
    },
    allowPositionals: false,
  });

  const jobs = loadJobs();
  const job = jobs.find((j) => j.id === id);
  if (!job) {
    console.error(`Error: job '${id}' not found`);
    process.exit(1);
  }

  if (values.status) job.status = values.status;
  if (values.title) job.title = values.title;
  if (values.company) job.company = values.company;
  if (values.url) job.url = values.url;
  job.updatedAt = new Date().toISOString();

  saveJobs(jobs);
  console.log(JSON.stringify(job, null, 2));
} else {
  console.error(`Unknown command: ${command}. Run --help for usage.`);
  process.exit(1);
}
