#!/usr/bin/env bun

import { parseArgs } from "util";
import { mkdirSync, existsSync, readFileSync, writeFileSync } from "fs";
import { join } from "path";
import { randomUUID } from "crypto";

const STATE_DIR = join(
  process.env.HOME || "~",
  ".local/state/openclaw-cron/task-queue"
);
const STATE_FILE = join(STATE_DIR, "tasks.json");

const MAX_ACTIVE = 50;
const MAX_ARCHIVE = 100;
const MAX_ATTEMPTS = 3;
const STALE_DAYS = 3;

type TaskType = "issue" | "task" | "improvement" | "followup";
type TaskStatus = "pending" | "in_progress" | "blocked" | "resolved" | "wontfix";

interface Task {
  id: string;
  title: string;
  description: string;
  type: TaskType;
  priority: number;
  status: TaskStatus;
  source: string;
  createdAt: string;
  updatedAt: string;
  dueBy?: string;
  resolution?: string;
  attempts: number;
  lastAttemptAt?: string;
  tags?: string[];
}

interface TaskStore {
  version: 1;
  tasks: Task[];
  archive: Task[];
}

const TYPE_PRIORITY: Record<TaskType, number> = {
  task: 1,
  issue: 2,
  followup: 3,
  improvement: 4,
};

const VALID_TYPES: TaskType[] = ["issue", "task", "improvement", "followup"];
const VALID_STATUSES: TaskStatus[] = ["pending", "in_progress", "blocked", "resolved", "wontfix"];

function loadStore(): TaskStore {
  if (!existsSync(STATE_FILE)) return { version: 1, tasks: [], archive: [] };
  try {
    return JSON.parse(readFileSync(STATE_FILE, "utf-8"));
  } catch {
    return { version: 1, tasks: [], archive: [] };
  }
}

function saveStore(store: TaskStore): void {
  store.archive = store.archive.slice(-MAX_ARCHIVE);
  mkdirSync(STATE_DIR, { recursive: true });
  writeFileSync(STATE_FILE, JSON.stringify(store, null, 2));
}

function isStale(task: Task): boolean {
  const age = Date.now() - new Date(task.createdAt).getTime();
  return age > STALE_DAYS * 24 * 60 * 60 * 1000 && task.attempts === 0;
}

function todayStart(): Date {
  const d = new Date();
  d.setHours(0, 0, 0, 0);
  return d;
}

function weekStart(): Date {
  const d = new Date();
  d.setDate(d.getDate() - d.getDay());
  d.setHours(0, 0, 0, 0);
  return d;
}

// --- Commands ---

const args = Bun.argv.slice(2);
const command = args[0];

if (!command || command === "--help" || command === "-h") {
  console.error(`task-queue — Persistent task queue for OpenClaw

Usage:
  ./run.ts add --title "..." --type issue --source "morning-briefing" [--description "..."] [--priority 2] [--due-by "..."] [--tags infra,api]
  ./run.ts list [--status pending] [--type issue] [--limit 10]
  ./run.ts next
  ./run.ts update <id> --status in_progress [--priority 1] [--description "..."]
  ./run.ts resolve <id> --resolution "Fixed by..."
  ./run.ts wontfix <id> --resolution "Not needed"
  ./run.ts stats

Types: issue, task, improvement, followup
Priorities: 1=critical, 2=high, 3=normal, 4=low
Statuses: pending, in_progress, blocked, resolved, wontfix

State: ${STATE_FILE}`);
  process.exit(0);
}

if (command === "add") {
  const { values } = parseArgs({
    args: args.slice(1),
    options: {
      title: { type: "string" },
      type: { type: "string" },
      source: { type: "string" },
      description: { type: "string" },
      priority: { type: "string" },
      "due-by": { type: "string" },
      tags: { type: "string" },
    },
    allowPositionals: false,
  });

  if (!values.title || !values.type || !values.source) {
    console.error("Error: --title, --type, and --source are required");
    process.exit(1);
  }

  const taskType = values.type as TaskType;
  if (!VALID_TYPES.includes(taskType)) {
    console.error(`Error: --type must be one of: ${VALID_TYPES.join(", ")}`);
    process.exit(1);
  }

  const store = loadStore();

  // Dedup: skip if same title already pending
  const existing = store.tasks.find(
    (t) => t.title === values.title && t.status === "pending"
  );
  if (existing) {
    console.log(JSON.stringify({ action: "duplicate_skipped", task: existing }, null, 2));
    process.exit(0);
  }

  // Cap check
  if (store.tasks.length >= MAX_ACTIVE && taskType === "improvement") {
    console.error(`Error: queue full (${MAX_ACTIVE} active tasks). Cannot add improvement tasks. Resolve existing tasks first.`);
    process.exit(1);
  }

  const priority = values.priority ? parseInt(values.priority) : TYPE_PRIORITY[taskType];
  const now = new Date().toISOString();

  const task: Task = {
    id: randomUUID(),
    title: values.title,
    description: values.description || "",
    type: taskType,
    priority,
    status: "pending",
    source: values.source,
    createdAt: now,
    updatedAt: now,
    attempts: 0,
    ...(values["due-by"] && { dueBy: values["due-by"] }),
    ...(values.tags && { tags: values.tags.split(",").map((t) => t.trim()) }),
  };

  store.tasks.push(task);
  saveStore(store);
  console.log(JSON.stringify({ action: "added", task }, null, 2));
} else if (command === "list") {
  const { values } = parseArgs({
    args: args.slice(1),
    options: {
      status: { type: "string" },
      type: { type: "string" },
      limit: { type: "string", short: "l" },
    },
    allowPositionals: false,
  });

  const store = loadStore();
  let tasks = store.tasks;

  if (values.status) tasks = tasks.filter((t) => t.status === values.status);
  if (values.type) tasks = tasks.filter((t) => t.type === values.type);

  // Sort: priority ASC, then createdAt ASC (oldest first within same priority)
  tasks.sort((a, b) => a.priority - b.priority || new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime());

  if (values.limit) tasks = tasks.slice(0, parseInt(values.limit));

  console.log(JSON.stringify({ action: "list", count: tasks.length, tasks }, null, 2));
} else if (command === "next") {
  const store = loadStore();

  // Find highest-priority pending task with < MAX_ATTEMPTS
  const candidates = store.tasks
    .filter((t) => t.status === "pending" && t.attempts < MAX_ATTEMPTS)
    .sort((a, b) => a.priority - b.priority || new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime());

  const task = candidates[0] || null;
  const reason = task ? undefined : "queue empty";

  console.log(JSON.stringify({ action: "next", task, ...(reason && { reason }) }, null, 2));
} else if (command === "update") {
  const id = args[1];
  if (!id) {
    console.error("Error: task ID required. Usage: ./run.ts update <id> --status <status>");
    process.exit(1);
  }

  const { values } = parseArgs({
    args: args.slice(2),
    options: {
      status: { type: "string" },
      priority: { type: "string" },
      description: { type: "string" },
    },
    allowPositionals: false,
  });

  const store = loadStore();
  const task = store.tasks.find((t) => t.id === id);
  if (!task) {
    console.error(`Error: task '${id}' not found`);
    process.exit(1);
  }

  const now = new Date().toISOString();

  if (values.status) {
    const newStatus = values.status as TaskStatus;
    if (!["pending", "in_progress", "blocked"].includes(newStatus)) {
      console.error("Error: use 'resolve' or 'wontfix' commands for terminal statuses");
      process.exit(1);
    }
    // Increment attempts when transitioning to in_progress
    if (newStatus === "in_progress" && task.status !== "in_progress") {
      task.attempts++;
      task.lastAttemptAt = now;
    }
    task.status = newStatus;
  }

  if (values.priority) task.priority = parseInt(values.priority);
  if (values.description) task.description = values.description;
  task.updatedAt = now;

  saveStore(store);
  console.log(JSON.stringify({ action: "updated", task }, null, 2));
} else if (command === "resolve" || command === "wontfix") {
  const id = args[1];
  if (!id) {
    console.error(`Error: task ID required. Usage: ./run.ts ${command} <id> --resolution "..."`);
    process.exit(1);
  }

  const { values } = parseArgs({
    args: args.slice(2),
    options: {
      resolution: { type: "string" },
    },
    allowPositionals: false,
  });

  if (!values.resolution) {
    console.error("Error: --resolution is required");
    process.exit(1);
  }

  const store = loadStore();
  const idx = store.tasks.findIndex((t) => t.id === id);
  if (idx === -1) {
    console.error(`Error: task '${id}' not found`);
    process.exit(1);
  }

  const task = store.tasks[idx];
  const now = new Date().toISOString();

  task.status = command === "resolve" ? "resolved" : "wontfix";
  task.resolution = values.resolution;
  task.updatedAt = now;

  // Move to archive
  store.tasks.splice(idx, 1);
  store.archive.push(task);

  saveStore(store);
  console.log(JSON.stringify({ action: command, task }, null, 2));
} else if (command === "stats") {
  const store = loadStore();
  const tasks = store.tasks;
  const today = todayStart();
  const week = weekStart();

  const byStatus: Record<string, number> = {};
  const byType: Record<string, number> = {};
  const byPriority: Record<string, number> = {};

  for (const t of tasks) {
    byStatus[t.status] = (byStatus[t.status] || 0) + 1;
    byType[t.type] = (byType[t.type] || 0) + 1;
    byPriority[t.priority] = (byPriority[t.priority] || 0) + 1;
  }

  const resolvedToday = store.archive.filter(
    (t) => new Date(t.updatedAt) >= today
  ).length;
  const resolvedThisWeek = store.archive.filter(
    (t) => new Date(t.updatedAt) >= week
  ).length;

  const pending = tasks.filter((t) => t.status === "pending");
  const oldestPending = pending.length
    ? pending.sort((a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime())[0].createdAt
    : null;

  const staleCount = tasks.filter((t) => t.status === "pending" && isStale(t)).length;
  const stuckCount = tasks.filter((t) => t.attempts >= MAX_ATTEMPTS).length;

  console.log(
    JSON.stringify(
      {
        action: "stats",
        active: {
          total: tasks.length,
          ...byStatus,
        },
        byType,
        byPriority,
        resolvedToday,
        resolvedThisWeek,
        oldestPending,
        staleCount,
        stuckCount,
        archiveSize: store.archive.length,
      },
      null,
      2
    )
  );
} else {
  console.error(`Unknown command: ${command}. Run --help for usage.`);
  process.exit(1);
}
