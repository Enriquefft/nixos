#!/usr/bin/env bun

import { parseArgs } from "util";
import { existsSync, readFileSync, writeFileSync, mkdirSync } from "fs";
import { join } from "path";

const STATE_DIR = join(process.env.HOME || "/tmp", ".local/state/openclaw-cron/track-price-drops");
const STATE_FILE = join(STATE_DIR, "price_history.json");
const COINGECKO_API = "https://api.coingecko.com/api/v3";

const { values, positionals } = parseArgs({
  args: Bun.argv.slice(2),
  options: {
    help: { type: "boolean", short: "h" },
    asset: { type: "string", default: "bitcoin" },
    threshold: { type: "string", default: "5" },
    window: { type: "string", default: "1h" },
  },
  allowPositionals: true,
});

if (values.help) {
  console.error(`track-price-drops — Track asset prices and alert on percentage drops.

Usage:
  ./run.ts check [options]
  ./run.ts history [options]

Commands:
  check     Fetch current price, compare with history, output alert status
  history   Show recent price history

Options:
  --asset <id>      CoinGecko asset ID (default: bitcoin)
  --threshold <n>   Alert if price drops more than N% (default: 5)
  --window <w>      Time window: 15m, 30m, 1h, 2h, 4h, 24h (default: 1h)

Output: JSON to stdout
Exit:   0 on success, 1 on error`);
  process.exit(0);
}

const command = positionals[0] || "check";

// Parse window to milliseconds
function parseWindow(window: string): number {
  const match = window.match(/^(\d+)(m|h|d)$/);
  if (!match) return 60 * 60 * 1000; // default 1h
  const [, num, unit] = match;
  const n = parseInt(num);
  switch (unit) {
    case "m": return n * 60 * 1000;
    case "h": return n * 60 * 60 * 1000;
    case "d": return n * 24 * 60 * 60 * 1000;
    default: return 60 * 60 * 1000;
  }
}

// Ensure state directory exists
if (!existsSync(STATE_DIR)) {
  mkdirSync(STATE_DIR, { recursive: true });
}

interface PricePoint {
  timestamp: number;
  price: number;
  asset: string;
}

interface State {
  history: PricePoint[];
}

function loadState(): State {
  if (!existsSync(STATE_FILE)) {
    return { history: [] };
  }
  try {
    return JSON.parse(readFileSync(STATE_FILE, "utf-8"));
  } catch {
    return { history: [] };
  }
}

function saveState(state: State): void {
  // Keep only last 24 hours of data
  const cutoff = Date.now() - 24 * 60 * 60 * 1000;
  state.history = state.history.filter(p => p.timestamp > cutoff);
  writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
}

async function fetchPrice(asset: string): Promise<number> {
  const url = `${COINGECKO_API}/simple/price?ids=${asset}&vs_currencies=usd`;
  const response = await fetch(url);
  
  if (!response.ok) {
    throw new Error(`CoinGecko API error: ${response.status}`);
  }
  
  const data = await response.json() as Record<string, { usd: number }>;
  
  if (!data[asset] || typeof data[asset].usd !== "number") {
    throw new Error(`Invalid response for asset: ${asset}`);
  }
  
  return data[asset].usd;
}

async function check() {
  const asset = values.asset!;
  const threshold = parseFloat(values.threshold!) || 5;
  const windowMs = parseWindow(values.window!);
  
  const state = loadState();
  const now = Date.now();
  
  let currentPrice: number;
  try {
    currentPrice = await fetchPrice(asset);
  } catch (err) {
    const result = {
      success: false,
      error: err instanceof Error ? err.message : "Failed to fetch price",
      asset,
      alert: false
    };
    console.log(JSON.stringify(result, null, 2));
    process.exit(1);
  }
  
  // Record current price
  state.history.push({
    timestamp: now,
    price: currentPrice,
    asset
  });
  
  // Find price from approximately window ago
  const windowAgo = now - windowMs;
  const candidates = state.history.filter(p => 
    p.asset === asset && 
    p.timestamp <= windowAgo &&
    p.timestamp > windowAgo - 15 * 60 * 1000 // within 15 min of target
  );
  
  let alert = false;
  let priceChange = 0;
  let oldPrice: number | null = null;
  let timeDiff = 0;
  
  if (candidates.length > 0) {
    // Use the most recent candidate
    const oldPoint = candidates[candidates.length - 1];
    oldPrice = oldPoint.price;
    timeDiff = now - oldPoint.timestamp;
    priceChange = ((currentPrice - oldPrice) / oldPrice) * 100;
    
    alert = priceChange <= -threshold;
  }
  
  saveState(state);
  
  const result = {
    success: true,
    asset,
    alert,
    currentPrice,
    oldPrice,
    priceChange: Math.round(priceChange * 100) / 100,
    threshold,
    timeDiffMinutes: Math.round(timeDiff / 60000),
    timestamp: new Date().toISOString()
  };
  
  console.log(JSON.stringify(result, null, 2));
}

function history() {
  const state = loadState();
  const asset = values.asset!;
  
  const filtered = state.history
    .filter(p => p.asset === asset)
    .sort((a, b) => b.timestamp - a.timestamp)
    .slice(0, 20);
  
  console.log(JSON.stringify({
    asset,
    count: filtered.length,
    history: filtered.map(p => ({
      price: p.price,
      time: new Date(p.timestamp).toISOString()
    }))
  }, null, 2));
}

// Run command
switch (command) {
  case "check":
    check().catch(err => {
      console.error("Error:", err.message);
      process.exit(1);
    });
    break;
  case "history":
    history();
    break;
  default:
    console.error(`Unknown command: ${command}`);
    process.exit(1);
}
