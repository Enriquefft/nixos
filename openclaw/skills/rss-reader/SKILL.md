---
name: rss-reader
description: Fetch and parse RSS/Atom feeds. Returns structured JSON.
user-invocable: false
---

## Usage

```bash
./run.ts [--feeds arxiv-ai,hn,reddit-ml] [--since 24h] [--limit 20] [--new-only] [--group research]
```

## Options

- `--feeds` — comma-separated feed names (default: all configured)
- `--group` — filter by group: `research` | `news`
- `--since` — only items newer than duration: `1h`, `24h`, `7d`, `30d` (default: `24h`)
- `--new-only` — only items not seen in previous runs (dedup; use in crons)
- `--limit <n>` — cap result count

## Feeds

| Key | Source | Group |
|-----|--------|-------|
| `arxiv-ai` | arXiv cs.AI | research |
| `arxiv-ml` | arXiv cs.LG | research |
| `arxiv-cl` | arXiv cs.CL (NLP/LLMs) | research |
| `arxiv-ma` | arXiv cs.MA (Multiagent) | research |
| `huggingface` | HuggingFace Papers | research |
| `hn` | Hacker News frontpage | news |
| `reddit-ml` | r/MachineLearning | news |
| `reddit-localllama` | r/LocalLLaMA | news |
| `reddit-startups` | r/startups | news |

Handles both RSS 2.0 and Atom 1.0 automatically.

## Output

JSON array to stdout:
```json
[{ "title": "...", "url": "...", "source": "...", "published": "...", "summary": "..." }]
```

## Examples

- All research feeds, last 24h: `./run.ts --group research --since 24h`
- arXiv only, 7 days: `./run.ts --feeds arxiv-ai,arxiv-ml,arxiv-cl --since 7d`
- HN + Reddit, new only: `./run.ts --feeds hn,reddit-ml,reddit-localllama --new-only`
- Paper scout cron: `./run.ts --group research --since 7d --new-only --limit 20`

## State

`~/.local/state/openclaw-cron/rss-reader/state.json` — tracks seen URLs for dedup. Capped at 3000 entries.
