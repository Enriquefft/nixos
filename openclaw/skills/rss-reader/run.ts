#!/usr/bin/env bun

import { parseArgs } from "util";
import { existsSync, readFileSync, writeFileSync, mkdirSync } from "fs";
import { join } from "path";

// --- Types ---

interface FeedItem {
  title: string;
  url: string;
  source: string;
  published: string;
  summary: string;
}

interface State {
  seen: string[]; // dedup by URL
  lastRun: string;
}

// --- CLI ---

const { values } = parseArgs({
  args: Bun.argv.slice(2),
  options: {
    help: { type: "boolean", short: "h" },
    feeds: { type: "string", short: "f" },
    since: { type: "string", short: "s" },
    limit: { type: "string", short: "l" },
    "new-only": { type: "boolean" },
    group: { type: "string", short: "g" }, // filter by group: research | news
  },
  allowPositionals: false,
});

if (values.help) {
  console.error(`rss-reader — Fetch and parse RSS/Atom feeds

Usage:
  ./run.ts [--feeds arxiv-ai,hn,reddit-ml] [--since 24h] [--limit 20] [--new-only] [--group research]

Options:
  --feeds <list>    Comma-separated feed names (default: all configured)
  --group <name>    Filter by group: research | news
  --since <dur>     Only items newer than duration: 1h, 24h, 7d, 30d (default: 24h)
  --new-only        Only items not seen in previous runs (dedup)
  --limit <n>       Max results (default: 30)
  -h, --help        Show this help

Feeds: arxiv-ai, arxiv-ml, arxiv-cl, arxiv-ma, huggingface, hn, reddit-ml, reddit-localllama, reddit-startups

Output: JSON array of { title, url, source, published, summary } to stdout
State:  ~/.local/state/openclaw-cron/rss-reader/state.json
Exit:   0 on success, 1 on error (details on stderr)`);
  process.exit(0);
}

// --- Config ---

const configPath = join(import.meta.dir, "config.json");
if (!existsSync(configPath)) {
  console.error("Error: config.json not found");
  process.exit(1);
}
const config = JSON.parse(readFileSync(configPath, "utf-8"));
const UA: string = config.defaults?.user_agent ?? "RSSReader/1.0";
const TIMEOUT: number = config.defaults?.timeout_ms ?? 15000;

// --- State ---

const STATE_DIR = join(process.env.HOME ?? "/tmp", ".local/state/openclaw-cron/rss-reader");
const STATE_PATH = join(STATE_DIR, "state.json");

function loadState(): State {
  if (!existsSync(STATE_PATH)) return { seen: [], lastRun: "" };
  try {
    return JSON.parse(readFileSync(STATE_PATH, "utf-8"));
  } catch {
    return { seen: [], lastRun: "" };
  }
}

function saveState(state: State): void {
  mkdirSync(STATE_DIR, { recursive: true });
  writeFileSync(STATE_PATH, JSON.stringify(state, null, 2));
}

// --- Duration parsing ---

function parseDuration(s: string): number {
  const m = /^(\d+(?:\.\d+)?)(m|h|d|w)$/.exec(s.trim().toLowerCase());
  if (!m) return 24 * 3600 * 1000; // default 24h
  const n = parseFloat(m[1]);
  switch (m[2]) {
    case "m": return n * 60 * 1000;
    case "h": return n * 3600 * 1000;
    case "d": return n * 86400 * 1000;
    case "w": return n * 7 * 86400 * 1000;
    default:  return 24 * 3600 * 1000;
  }
}

// --- XML helpers ---

function xmlField(xml: string, tag: string): string {
  // CDATA: <tag><![CDATA[...]]></tag>
  const cdata = new RegExp(`<${tag}[^>]*><!\\[CDATA\\[([\\s\\S]*?)\\]\\]><\\/${tag}>`, "i").exec(xml);
  if (cdata) return cdata[1].trim();
  // Plain: <tag ...>...</tag>
  const plain = new RegExp(`<${tag}[^>]*>([\\s\\S]*?)<\\/${tag}>`, "i").exec(xml);
  return plain ? plain[1].trim() : "";
}

function xmlAttr(xml: string, tag: string, attr: string): string {
  // <tag ... attr="value" ...>
  const re = new RegExp(`<${tag}[^>]*\\s${attr}=["']([^"']*)["'][^>]*>`, "i").exec(xml);
  return re ? re[1].trim() : "";
}

function stripHtml(s: string): string {
  return s
    .replace(/<!--[\s\S]*?-->/g, "")
    .replace(/<br\s*\/?>/gi, " ")
    .replace(/<p[^>]*>/gi, " ")
    .replace(/<[^>]+>/g, "")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#x27;/g, "'")
    .replace(/&#x2F;/g, "/")
    .replace(/&nbsp;/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function truncate(s: string, n: number): string {
  return s.length > n ? s.slice(0, n - 1) + "…" : s;
}

// --- RSS 2.0 parser ---

function parseRSS2(xml: string, sourceName: string): FeedItem[] {
  const items: FeedItem[] = [];
  const itemRe = /<item[^>]*>([\s\S]*?)<\/item>/gi;
  let m;
  while ((m = itemRe.exec(xml)) !== null) {
    const item = m[1];
    const title = stripHtml(xmlField(item, "title"));
    const link = xmlField(item, "link") || xmlField(item, "guid");
    const pubDate = xmlField(item, "pubDate") || xmlField(item, "dc:date") || xmlField(item, "updated");
    const desc = stripHtml(
      xmlField(item, "description") ||
      xmlField(item, "content:encoded") ||
      xmlField(item, "summary")
    );
    if (!title || !link) continue;
    items.push({
      title,
      url: link,
      source: sourceName,
      published: pubDate ? new Date(pubDate).toISOString() : new Date().toISOString(),
      summary: truncate(desc, 300),
    });
  }
  return items;
}

// --- Atom parser ---

function parseAtom(xml: string, sourceName: string): FeedItem[] {
  const items: FeedItem[] = [];
  const entryRe = /<entry[^>]*>([\s\S]*?)<\/entry>/gi;
  let m;
  while ((m = entryRe.exec(xml)) !== null) {
    const entry = m[1];
    const title = stripHtml(xmlField(entry, "title"));

    // <link href="..." rel="alternate"/> or <link href="..."/>
    let link = xmlAttr(entry, "link", "href");
    if (!link) link = xmlField(entry, "link");

    const published =
      xmlField(entry, "published") ||
      xmlField(entry, "updated") ||
      xmlField(entry, "dc:date");

    const summary = stripHtml(
      xmlField(entry, "summary") ||
      xmlField(entry, "content") ||
      xmlField(entry, "description")
    );

    if (!title || !link) continue;
    items.push({
      title,
      url: link,
      source: sourceName,
      published: published ? new Date(published).toISOString() : new Date().toISOString(),
      summary: truncate(summary, 300),
    });
  }
  return items;
}

// --- Feed fetcher ---

async function fetchFeed(feedKey: string, feedCfg: any): Promise<FeedItem[]> {
  const sourceName: string = feedCfg.name ?? feedKey;
  try {
    const res = await fetch(feedCfg.url as string, {
      headers: {
        "User-Agent": UA,
        "Accept": "application/rss+xml, application/atom+xml, application/xml, text/xml, */*",
      },
      signal: AbortSignal.timeout(TIMEOUT),
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const xml = await res.text();

    // Detect format: Atom has <feed> root, RSS has <rss> or <channel>
    const isAtom = /<feed[\s>]/i.test(xml.slice(0, 500));
    return isAtom ? parseAtom(xml, sourceName) : parseRSS2(xml, sourceName);
  } catch (e: any) {
    console.error(`[${feedKey}] ${e.message}`);
    return [];
  }
}

// --- Main ---

async function main() {
  const state = loadState();
  const allFeedKeys = Object.keys(config.feeds);

  // Select feeds
  let selectedKeys = values.feeds
    ? values.feeds.split(",").map(f => f.trim()).filter(f => f in config.feeds)
    : allFeedKeys;

  // Filter by group
  if (values.group) {
    selectedKeys = selectedKeys.filter(k => config.feeds[k]?.group === values.group);
  }

  if (selectedKeys.length === 0) {
    console.error("Error: no valid feeds selected");
    process.exit(1);
  }

  // Parse --since duration
  const sinceDur = parseDuration(values.since ?? config.defaults?.since ?? "24h");
  const sinceDate = new Date(Date.now() - sinceDur);

  // Fetch all in parallel
  const settled = await Promise.allSettled(
    selectedKeys.map(k => fetchFeed(k, config.feeds[k]))
  );
  const allItems: FeedItem[] = settled.flatMap(r =>
    r.status === "fulfilled" ? r.value : []
  );

  // Filter by date
  let output = allItems.filter(item => {
    try {
      return new Date(item.published) >= sinceDate;
    } catch {
      return true; // include if date unparseable
    }
  });

  const seenSet = new Set(state.seen);
  const newUrls = output.filter(i => !seenSet.has(i.url)).map(i => i.url);

  // Dedup filter
  if (values["new-only"]) {
    output = output.filter(i => !seenSet.has(i.url));
  }

  // Sort newest first
  output.sort((a, b) => new Date(b.published).getTime() - new Date(a.published).getTime());

  // Limit
  if (values.limit) {
    const n = parseInt(values.limit, 10);
    if (!isNaN(n)) output = output.slice(0, n);
  }

  // Persist state (cap at 3000)
  const updatedSeen = [...seenSet, ...newUrls].slice(-3000);
  saveState({ seen: updatedSeen, lastRun: new Date().toISOString() });

  console.log(JSON.stringify(output, null, 2));
  process.exit(0);
}

main().catch(e => {
  console.error("Fatal:", e.message);
  process.exit(1);
});
