#!/usr/bin/env bun

import { parseArgs } from "util";
import { existsSync, readFileSync, writeFileSync, mkdirSync } from "fs";
import { join } from "path";
import { chromium, Browser, Page } from "playwright";

// Set up library paths for Playwright on NixOS
if (!process.env.LD_LIBRARY_PATH) {
  const libPaths = [
    "/run/opengl-driver/lib",
    "/nix/store/2x2rgrz9pkmf0h7bzcgvawhc7mxs8w4b-mesa-25.2.6/lib",
  ].filter(existsSync);

  if (libPaths.length > 0) {
    process.env.LD_LIBRARY_PATH = libPaths.join(":");
  }
}

// --- Types ---

interface JobListing {
  title: string;
  company: string;
  url: string;
  location: string;
  posted: string;
  board: string;
  tags?: string[];
}

interface State {
  seen: string[]; // URLs seen in previous runs (dedup)
  lastRun: string;
}

// --- CLI ---

const { values } = parseArgs({
  args: Bun.argv.slice(2),
  options: {
    help: { type: "boolean", short: "h" },
    boards: { type: "string", short: "b" },
    "remote-only": { type: "boolean" },
    "new-only": { type: "boolean" }, // exclude URLs seen in previous runs
    limit: { type: "string", short: "l" },
  },
  allowPositionals: false,
});

if (values.help) {
  console.error(`job-scanner — Fetch and filter job board listings

Usage:
  ./run.ts [--boards remoteok,weworkremotely,hackernews] [--remote-only] [--new-only] [--limit 20]

Options:
  --boards <list>   Comma-separated board names (default: all configured)
  --remote-only     Only include remote-friendly positions
  --new-only        Only include jobs not seen in previous runs (dedup)
  --limit <n>       Max results to return (default: no limit)
  -h, --help        Show this help

Boards with live data: remoteok, weworkremotely, hackernews
Boards requiring browser/auth (skipped): wellfound, linkedin, arcdev, turing, ycwork

Output: JSON array of { title, company, url, location, posted, board } to stdout
State:  ~/.local/state/openclaw-cron/job-scanner/state.json
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
const UA: string = config.scrape_config?.user_agent ?? "JobScanner/1.0";
const TIMEOUT: number = config.scrape_config?.timeout_ms ?? 30000;

// --- State ---

const STATE_DIR = join(process.env.HOME ?? "/tmp", ".local/state/openclaw-cron/job-scanner");
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

// --- RSS Helpers ---

function rssField(itemXml: string, tag: string): string {
  // CDATA variant: <tag><![CDATA[...]]></tag>
  const cdata = new RegExp(`<${tag}[^>]*><!\\[CDATA\\[([\\s\\S]*?)\\]\\]><\\/${tag}>`, "i").exec(itemXml);
  if (cdata) return cdata[1].trim();
  // Plain: <tag>...</tag>
  const plain = new RegExp(`<${tag}[^>]*>([\\s\\S]*?)<\\/${tag}>`, "i").exec(itemXml);
  return plain ? plain[1].trim() : "";
}

function parseRSSItems(xml: string): { title: string; link: string; pubDate: string }[] {
  const results: { title: string; link: string; pubDate: string }[] = [];
  const itemRe = /<item[^>]*>([\s\S]*?)<\/item>/gi;
  let m;
  while ((m = itemRe.exec(xml)) !== null) {
    const item = m[1];
    const title = rssField(item, "title");
    const link = rssField(item, "link") || rssField(item, "guid");
    const pubDate = rssField(item, "pubDate");
    if (title && link) results.push({ title, link, pubDate });
  }
  return results;
}

// --- Board fetchers ---

async function fetchRemoteOK(): Promise<JobListing[]> {
  try {
    const res = await fetch("https://remoteok.com/api", {
      headers: { "User-Agent": UA, "Accept": "application/json" },
      signal: AbortSignal.timeout(TIMEOUT),
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const data = await res.json() as any[];
    // First element is a legal notice object, skip it
    return data
      .slice(1)
      .filter((j: any) => j.position && j.company)
      .map((j: any) => ({
        title: j.position as string,
        company: j.company as string,
        url: (j.url as string) || `https://remoteok.com/l/${j.slug}`,
        location: (j.location && (j.location as string) !== "") ? j.location as string : "Remote",
        posted: (j.date as string) || new Date().toISOString(),
        board: "remoteok",
        tags: (j.tags as string[]) || [],
      }));
  } catch (e: any) {
    console.error(`[remoteok] ${e.message}`);
    return [];
  }
}

async function fetchWeWorkRemotely(): Promise<JobListing[]> {
  const feedUrls = [
    "https://weworkremotely.com/remote-jobs.rss",
  ];
  const all: JobListing[] = [];
  for (const url of feedUrls) {
    try {
      const res = await fetch(url, {
        headers: { "User-Agent": UA },
        signal: AbortSignal.timeout(TIMEOUT),
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const xml = await res.text();
      for (const item of parseRSSItems(xml)) {
        // WWR title format: "Section: Company: Role" or "Company: Role"
        const parts = item.title.split(": ");
        // Drop leading category (e.g. "Full-Stack Programming") if > 2 parts
        const company = parts.length >= 2 ? parts[parts.length - 2] : item.title;
        const title = parts.length >= 1 ? parts[parts.length - 1] : item.title;
        all.push({
          title,
          company,
          url: item.link,
          location: "Remote",
          posted: item.pubDate ? new Date(item.pubDate).toISOString() : new Date().toISOString(),
          board: "weworkremotely",
        });
      }
    } catch (e: any) {
      console.error(`[weworkremotely] ${e.message}`);
    }
  }
  return all;
}

async function fetchHackerNews(): Promise<JobListing[]> {
  try {
    // Find current month's "Ask HN: Who is hiring?" thread
    const now = new Date();
    const month = now.toLocaleString("en-US", { month: "long" });
    const year = now.getFullYear();
    const query = encodeURIComponent(`Ask HN: Who is hiring? (${month} ${year})`);

    const searchRes = await fetch(
      `https://hn.algolia.com/api/v1/search?query=${query}&tags=story&restrictSearchableAttributes=title&hitsPerPage=5`,
      { signal: AbortSignal.timeout(15000) }
    );
    if (!searchRes.ok) throw new Error(`search HTTP ${searchRes.status}`);
    const searchData = await searchRes.json() as any;

    // "whoishiring" is the account that posts the official thread
    const thread = (searchData.hits ?? []).find(
      (h: any) => h.author === "whoishiring" || h.title?.includes("Who is hiring")
    );
    if (!thread) {
      console.error(`[hackernews] Could not find Who's Hiring thread for ${month} ${year}`);
      return [];
    }

    const itemRes = await fetch(
      `https://hn.algolia.com/api/v1/items/${thread.objectID}`,
      { signal: AbortSignal.timeout(20000) }
    );
    if (!itemRes.ok) throw new Error(`items HTTP ${itemRes.status}`);
    const itemData = await itemRes.json() as any;

    const jobs: JobListing[] = [];
    for (const comment of (itemData.children ?? []).slice(0, 150)) {
      if (!comment.text || comment.deleted || comment.dead) continue;

      // Strip HTML tags
      const text = (comment.text as string)
        .replace(/<br\s*\/?>/gi, "\n")
        .replace(/<p>/gi, "\n")
        .replace(/<[^>]+>/g, "")
        .replace(/&amp;/g, "&")
        .replace(/&lt;/g, "<")
        .replace(/&gt;/g, ">")
        .replace(/&#x27;/g, "'")
        .replace(/&#x2F;/g, "/")
        .replace(/&#x3A;/g, ":")
        .replace(/&quot;/g, '"')
        .trim();

      const firstLine = text.split("\n").find(l => l.trim()) ?? "";
      if (!firstLine) continue;

      // Standard HN format: "Company | Role | Location | Remote/Onsite | ..."
      // Pipe-separated or free-form
      const parts = firstLine.split("|").map(p => p.trim()).filter(Boolean);
      const company = parts[0] ?? firstLine.slice(0, 60);
      const title = parts[1] ?? "Software Engineer";
      const locationPart = parts.slice(2).join(" ");
      const isRemote = /remote|worldwide|anywhere/i.test(firstLine);
      const location = isRemote
        ? "Remote"
        : locationPart
        ? locationPart.slice(0, 60)
        : "See listing";

      jobs.push({
        title: title.slice(0, 120),
        company: company.slice(0, 80),
        url: `https://news.ycombinator.com/item?id=${comment.id}`,
        location,
        posted: (comment.created_at as string) || new Date().toISOString(),
        board: "hackernews",
      });
    }
    return jobs;
  } catch (e: any) {
    console.error(`[hackernews] ${e.message}`);
    return [];
  }
}

async function fetchWellfound(): Promise<JobListing[]> {
  const searchUrls = [
    "https://wellfound.com/role/founding-engineer?remote=true",
    "https://wellfound.com/role/ai-engineer?remote=true",
    "https://wellfound.com/role/product-engineer?remote=true",
  ];

  const all: JobListing[] = [];
  let browser: Browser | null = null;

  try {
    // On NixOS, use system Chrome which has proper library linkage
    const executablePath = "/run/current-system/sw/bin/google-chrome-stable";

    browser = await chromium.launch({
      headless: true,
      executablePath: existsSync(executablePath) ? executablePath : undefined,
      channel: existsSync(executablePath) ? undefined : "chrome",
      args: [
        "--no-sandbox",
        "--disable-setuid-sandbox",
        "--disable-dev-shm-usage",
        "--disable-gpu",
        "--disable-software-rasterizer",
      ],
    });

    for (const url of searchUrls) {
      try {
        const page = await browser.newPage();
        await page.goto(url, { waitUntil: "domcontentloaded", timeout: 20000 });

        // Wait for job listings to load
        await page.waitForSelector('article', {
          timeout: 10000,
        }).catch(() => {});

        // Debug: take screenshot
        await page.screenshot({ path: `/tmp/wellfound-debug-${Date.now()}.png`, fullPage: false }).catch(() => {});

        // Debug: log page content
        const html = await page.content();
        console.error(`[wellfound] Page HTML length: ${html.length}`);

        // Extract job data
        const jobs = await page.evaluate(() => {
          const results: Array<{ title: string; company: string; url: string; location: string }> = [];

          // Try multiple selectors for job cards
          const cards = document.querySelectorAll('article');

          console.log(`[browser] Found ${cards.length} article elements`);

          cards.forEach((card, idx) => {
            const el = card as HTMLElement;

            // Try to extract data
            const link = el.querySelector('a[href*="/jobs/"]') as HTMLAnchorElement;
            const titleEl = el.querySelector('h3, h2, [class*="title"]');
            const companyEl = el.querySelector('[class*="company"]');
            const locationEl = el.querySelector('[class*="location"]');

            if (idx < 3) {
              console.log(`[browser] Card ${idx}: link=${!!link}, title=${!!titleEl}, company=${!!companyEl}`);
            }

            if (link && titleEl) {
              results.push({
                title: titleEl.textContent?.trim() || "Unknown",
                company: companyEl?.textContent?.trim() || "Unknown",
                url: link.href,
                location: locationEl?.textContent?.trim() || "Remote",
              });
            }
          });

          return results;
        });

        for (const job of jobs.slice(0, 20)) {
          all.push({
            title: job.title,
            company: job.company,
            url: job.url,
            location: job.location,
            posted: new Date().toISOString(),
            board: "wellfound",
          });
        }

        await page.close();
      } catch (e: any) {
        console.error(`[wellfound] Error on ${url}: ${e.message}`);
      }
    }
  } catch (e: any) {
    console.error(`[wellfound] Browser error: ${e.message}`);
  } finally {
    if (browser) {
      await browser.close();
    }
  }

  console.error(`[wellfound] Found ${all.length} jobs via Playwright`);
  return all;
}

async function fetchArcDev(): Promise<JobListing[]> {
  // Arc.dev job search API
  try {
    const res = await fetch("https://api.arc.dev/api/jobs/search", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "User-Agent": UA,
      },
      body: JSON.stringify({
        query: "founding engineer OR product engineer OR AI engineer OR ML engineer",
        remote: true,
        limit: 50,
      }),
      signal: AbortSignal.timeout(TIMEOUT),
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const data = await res.json() as any;

    return (data.jobs ?? []).map((j: any) => ({
      title: j.title as string,
      company: j.company?.name ?? "Unknown",
      url: j.url || `https://arc.dev/jobs/${j.id}`,
      location: j.location || "Remote",
      posted: j.postedAt || new Date().toISOString(),
      board: "arcdev",
      tags: j.skills ?? [],
    }));
  } catch (e: any) {
    // Fallback: scrape the HTML page
    try {
      const res = await fetch("https://arc.dev/remote-jobs", {
        headers: { "User-Agent": UA },
        signal: AbortSignal.timeout(TIMEOUT),
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const html = await res.text();

      // Arc.dev uses Next.js with __NEXT_DATA__
      const dataMatch = /<script id="__NEXT_DATA__"[^>]*>([\s\S]*?)<\/script>/.exec(html);
      if (dataMatch) {
        const data = JSON.parse(dataMatch[1]) as any;
        const jobs = data?.props?.pageProps?.jobs ?? [];
        return jobs.map((j: any) => ({
          title: j.title as string,
          company: j.company?.name ?? "Unknown",
          url: `https://arc.dev/jobs/${j.id}`,
          location: j.location || "Remote",
          posted: j.postedAt || new Date().toISOString(),
          board: "arcdev",
        }));
      }
    } catch (e2: any) {
      console.error(`[arcdev] ${e2.message}`);
    }
    return [];
  }
}

async function fetchYCWor(): Promise<JobListing[]> {
  try {
    // YC Work at a Startup API
    const res = await fetch("https://www.ycombinator.com/jobs", {
      headers: { "User-Agent": UA },
      signal: AbortSignal.timeout(TIMEOUT),
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const html = await res.text();

    // Parse YC jobs page
    const jobs: JobListing[] = [];
    const jobRe = /<a[^>]*class="[^"]*job-listing[^"]*"[^>]*href="([^"]+)"[^>]*>([\s\S]*?)<\/a>/gi;
    let m;
    while ((m = jobRe.exec(html)) !== null) {
      const url = m[1];
      const content = m[2];
      const titleMatch = /<span[^>]*class="[^"]*title[^"]*"[^>]*>([^<]+)<\/span>/.exec(content);
      const companyMatch = /<span[^>]*class="[^"]*company[^"]*"[^>]*>([^<]+)<\/span>/.exec(content);

      if (url && titleMatch) {
        jobs.push({
          title: titleMatch[1].trim(),
          company: companyMatch ? companyMatch[1].trim() : "YC Startup",
          url: url.startsWith("http") ? url : `https://www.ycombinator.com${url}`,
          location: "See listing",
          posted: new Date().toISOString(),
          board: "ycwork",
        });
      }
    }
    return jobs;
  } catch (e: any) {
    console.error(`[ycwork] ${e.message}`);
    return [];
  }
}

function requiresAuth(board: string): JobListing[] {
  console.error(`[${board}] requires logged-in browser session — skipped`);
  return [];
}

// --- Board registry ---

const FETCHERS: Record<string, () => Promise<JobListing[]>> = {
  remoteok: fetchRemoteOK,
  weworkremotely: fetchWeWorkRemotely,
  hackernews: fetchHackerNews,
  wellfound: fetchWellfound,
  arcdev: fetchArcDev,
  ycwork: fetchYCWor,
  linkedin: async () => requiresAuth("linkedin"),
  turing: async () => requiresAuth("turing"),
};

// --- Main ---

async function main() {
  const state = loadState();

  const selectedBoards = values.boards
    ? values.boards.split(",").map(b => b.trim()).filter(b => b in FETCHERS)
    : Object.keys(config.boards).filter(b => b in FETCHERS);

  if (selectedBoards.length === 0) {
    console.error("Error: no valid boards selected");
    process.exit(1);
  }

  // Fetch all boards in parallel
  const settled = await Promise.allSettled(selectedBoards.map(b => FETCHERS[b]()));
  const allJobs: JobListing[] = settled.flatMap(r =>
    r.status === "fulfilled" ? r.value : []
  );

  const seenSet = new Set(state.seen);
  const newUrls = allJobs.filter(j => !seenSet.has(j.url)).map(j => j.url);

  // Filter to new-only if requested
  let output = values["new-only"]
    ? allJobs.filter(j => !seenSet.has(j.url))
    : allJobs;

  // Remote filter
  if (values["remote-only"]) {
    output = output.filter(j => /remote|worldwide|anywhere/i.test(j.location));
  }

  // Sort newest first
  output.sort((a, b) => new Date(b.posted).getTime() - new Date(a.posted).getTime());

  // Limit
  if (values.limit) {
    const n = parseInt(values.limit, 10);
    if (!isNaN(n)) output = output.slice(0, n);
  }

  // Persist state — cap seen list at 2000 to avoid unbounded growth
  const updatedSeen = [...seenSet, ...newUrls].slice(-2000);
  saveState({ seen: updatedSeen, lastRun: new Date().toISOString() });

  console.log(JSON.stringify(output, null, 2));
  process.exit(0);
}

main().catch(e => {
  console.error("Fatal:", e.message);
  process.exit(1);
});
