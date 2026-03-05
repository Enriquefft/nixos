# Lore

Persistent context that evolves over time. Kiro updates this file (with approval) as new information becomes relevant.

## Job Search Strategy

### Positioning

Enrique is not a junior looking for his first job. He's a CTO/founder who built products with real revenue and scale, choosing to seek employment for financial stability and learning density. Frame every application accordingly.

**Lead with:**
- CTO who built AI edtech serving 500+ teachers with $15K revenue
- One of Peru's fastest 0-to-1 builders (10+ MVPs, 4-day product launch)
- Founded a deeptech incubator (15 startups, S/.200K+ funding)
- Active researcher (paper under peer review, not just an engineer)

**Don't lead with:**
- "Looking for a job" energy. He's choosing where to apply his skills.
- Education status (on break from degree). Let it come up naturally if asked.
- Visa needs upfront. Let application forms handle it.

### Target Paths (in priority order)

1. **Remote-global ($100K+ USD):** No visa needed. Fastest path to income. Companies that hire LATAM talent and pay well.
2. **US visa sponsorship:** H-1B or O-1 sponsors. Longer process but highest upside. O-1 may be viable given: founded incubator, SABF speaker, research, open-source traction.
3. **Relocation:** Countries with accessible work permits. Netherlands (already worked there), Germany, Portugal, Canada, UAE, Singapore, UK.

### Target Roles

In order of fit:
- **Founding engineer / early-stage** - Best fit. He IS this person. 0-to-1 is his superpower.
- **Product engineer** - Strong fit. Thinks product, not just code.
- **AI/ML engineer** - Good fit. Agents, LangChain, RAG, MCP, research background.
- **Fullstack engineer** - Solid fit. Can do everything, might be underselling.
- **Tech lead** - Has done this at Toke and Keepers. Credible.

### Job Boards to Monitor
- Wellfound (AngelList) - startups, founding roles
- RemoteOK - remote-global
- WeWorkRemotely - remote-global
- Arc.dev - vetted remote engineers
- Turing - remote LATAM-friendly
- LinkedIn Jobs - broad, but filter for remote/sponsorship
- HackerNews "Who's Hiring" - monthly thread, first of each month
- Y Combinator Work at a Startup - early-stage roles
- Toptal, Upwork, Contra - freelance/contract for runway extension

### Application Approach

- **Quality over quantity.** Tailored applications only. Never spray and pray.
- **Research the company first.** Reference their product, tech stack, recent news. Show you know them.
- **Cold outreach > ATS.** DM the hiring manager or CTO on LinkedIn/Twitter when possible. Skip the black hole.
- **Follow up after 5 days.** Always. Most people don't. This alone increases response rates.
- **Portfolio is the proof.** Link to Genera, 404TF, the Kapso bridge, research. Let the work speak.

### Resume/CV Notes

- Enrique is working on his portfolio and LinkedIn in parallel
- When drafting cover letters, pull from `/etc/nixos/zeroclaw/reference/full-profile.md` (not yet migrated) for specific metrics and stories
- Tailor the emphasis per role: founding roles get the MVP speed story, AI roles get the research + agent library, product roles get the Genera metrics
- For polished, ready-to-adapt responses by question type, read `/etc/nixos/zeroclaw/reference/reusable-responses.md` (not yet migrated)

### Sensitive Topics

- **No degree (yet).** On break from UTEC. Don't volunteer this. If asked, frame as: "close to completing CS at UTEC, took a break to build Genera full-time." The experience more than compensates.
- **Visa.** Don't mention in outreach or cover letters. Let forms handle it. Only discuss if directly asked.
- **Age.** Enrique is young (~23-24). This is an advantage at startups (energy, speed) but might raise concerns at larger companies. Let the work speak.

## Products

### post-shit-now
- **What:** Claude commands framework for social media automation
- **Pipeline:** Research -> Ideate -> Generate -> Schedule -> Post
- **Status:** Early development, actively building
- **Location:** ~/Projects/post-shit-now
- **Goal:** Solve Enrique's own distribution problem, then productize
- **Why it matters:** Distribution is his self-identified weakness. This is him building the tool he needs.

### Genera
- AI-powered SaaS for teachers in Peru
- Still active (CTO role), cofounders managing operations
- Building second product: Tiza (MCP integration for Google Classroom)
- 500+ teachers, 15K+ students, $15K revenue, <5% churn

### ZeroClaw + Nix Automation (Kiro)
- Personal project, fulltime focus
- Super-automation of personal workflow
- This system (Kiro) is the product

### Agent Orchestration System
- Automating PRD -> functional app in <24 hours
- Built over Claude Code
- Systematizing freelance MVP expertise into tooling

### Kapso WhatsApp Bridge
- Open-source Go daemon
- 100 GitHub stars
- Endorsed by Kapso/Platanus founder
- This is running Kiro's WhatsApp connection right now

## Distribution Strategy

### Narrative
AI engineer and CTO/founder with a 2-month runway, automating his entire job search and content pipeline with ZeroClaw on NixOS, building in the open. This story is inherently compelling because it's real, high-stakes, and technical.

### Content Pillars
1. **Build in public:** What I shipped, what broke, what I learned. Daily updates.
2. **AI/agent engineering:** Technical insights from building agents, ZeroClaw setup, automation
3. **Job hunt transparency:** The real process, numbers, rejections, wins
4. **Startup/founder perspective:** Lessons from Genera, 404TF, 10+ MVPs
5. **Research:** Accessible versions of paper findings, interesting results

### Platform Strategy
- **X/Twitter:** Short, punchy, opinionated. Technical hot takes. Build-in-public updates.
- **LinkedIn:** Longer posts, professional framing. Job search content. Founder stories.
- **Reddit:** Technical depth in relevant subreddits. Not promotional. Genuinely helpful.
- **HackerNews:** Only for genuinely interesting technical content. Don't force it.

### The Flywheel
Content builds audience -> audience creates inbound job opportunities -> job hunt content IS the content -> repeat. Distribution solves both the job problem and the product problem simultaneously.

## Research

### Active (Primary Focus)
1. **"Who Gets Missed?"** - Algorithmic fairness audit of Peru's dropout prediction system. Under peer review. 5 model families, 150K records, SHAP analysis.
2. **LLM AIR for Climate Events** - RAG + reasoning over historical ENSO data. Approved proposal. Co-authoring.

### Active (Secondary)
3. **LLM Gladiators** - Adversarial game environment for LLM agent evaluation. POC stage. Hytale-based.

### Research Interests
- Multi-agent systems in adversarial environments
- Algorithmic fairness in public systems
- LLM reasoning over structured data
- Compilers + LLMs
- Spec-driven development (PRD to app automation)

## Target Companies

(Kiro builds and maintains this via weekly company-refresh cron. Start empty, populate through research.)

### Remote-Global
- TBD

### US Sponsors (H-1B / O-1)
- TBD

### Relocation-Friendly
- TBD (Netherlands is strong given existing Keepers experience)

## Application Tracker

Maintained at `~/zeroclaw-data/job-tracker.json`

Format:
```json
{
  "company": "",
  "role": "",
  "url": "",
  "status": "new|applied|interview|offer|rejected|ghosted",
  "date_applied": "",
  "follow_up_date": "",
  "contact_person": "",
  "outreach_channel": "email|linkedin|twitter|ats",
  "notes": ""
}
```

## Freelance Tracker

Same location: `~/zeroclaw-data/freelance-tracker.json`
For Upwork/Toptal/Contra gigs that extend runway.

## Lessons Learned

(Kiro updates this as patterns emerge)

- What types of applications get responses
- What content performs well on which platform
- What times of day get best engagement
- What companies ghost vs respond
- What cover letter approaches work
- What outreach channels convert best (cold DM vs ATS vs email)

## Key Stories for Content & Outreach

Reference `/etc/nixos/zeroclaw/reference/full-profile.md` (not yet migrated) for full versions. Quick index:

- **Origin story:** Automated boss's workflow at 17 without being asked
- **Genera sacrifice:** Refused to eat to protect startup runway
- **PainPoint speed:** 0 to product with LATAM client demos in 4 days
- **Synbio learning:** Cell biology from scratch in 1 month for iGEM
- **Esports leadership:** Austrian Clash of Clans team, world top 32, never met teammates IRL
- **Teaching roots:** 300+ students since age 16-17, family had a school
