# Job Scanner Improvements

## Principle
No solo ejecutar, mejorar proactivamente. Cada gap identificado es una oportunidad de crecimiento.

---

## Active Improvements

### G1: Wellfound Browser Automation
**Problem:** Wellfound has Cloudflare/bot protection that blocks headless browsers. Page loads only ~1500 bytes.

**Solution:**
1. ✅ Install Playwright (done via bun)
2. ✅ Configure to use system Chrome (done)
3. ✅ NixOS rebuild (done - can call `sudo /run/current-system/sw/bin/nixos-rebuild switch` directly)
4. ⏸️ Headless still blocked by Cloudflare
5. 📋 NEXT: Try stealth mode OR use non-headless OR browser puppet OR alternative endpoints

**Implementation Plan:**
- [ ] Try playwright-stealth plugin
- [ ] Try non-headless mode with virtual display (xvfb)
- [ ] Fallback: Return URLs for manual browser enrichment via Kiro's browser tool
- [ ] OR: Research alternative endpoints (RSS, API)

**Code Location:** `run.ts` → `fetchWellfound()`

**Status:** Playwright installed and configured, but Wellfound still blocks headless. Requires stealth mode or alternative approach.

---

### G2: LinkedIn Integration
**Problem:** LinkedIn requires logged-in session + anti-scraping
**Solution:** 
- Option A: Use browser with pre-authenticated session
- Option B: Use LinkedIn API (requires partnership)
- Option C: Use third-party enrichment

**Status:** Research needed. Lower priority due to complexity.

---

### G3: Arc.dev Integration
**Problem:** API endpoint not accessible without auth
**Solution:** 
- Research if there's a public API
- Fallback: scrape the HTML job listing page

**Status:** Research needed.

---

### G4: Full Listing Parsing
**Problem:** Current output is title/company/url only
**Solution:** For each job URL:
1. Fetch full page content
2. Extract: salary, requirements, location details, tech stack
3. Store as enriched fields in output

**Impact:** Better filtering, better matching, more actionable output

---

### G5: Profile-Based Scoring
**Problem:** No intelligent filtering based on Enrique's profile
**Solution:**
1. Load full-profile.md on scanner init
2. Score each job against profile:
   - Role match (founding/product/AI engineer)
   - Location match (remote-global, LATAM, sponsorship)
   - Stack match (Next.js, Python, AI/ML)
   - Stage match (early-stage, 0→1)
3. Output includes match score + reasoning

**Impact:** Top 10 automatically curated, no manual review needed

---

### G6: Application Tracking Integration
**Problem:** Jobs found but not tracked
**Solution:**
1. New jobs → auto-add to job-tracker
2. Track: found_date, board, status=new
3. Integration with job-tracker skill

---

## Completed Improvements

| Date | Improvement | Result |
|------|-------------|--------|
| 2026-03-03 | Added Arc.dev + YC Work fetchers | Arc.dev API failed, YC needs testing |
| 2026-03-03 | Added Wellfound fetcher | Failed with 403, needs browser |

---

## Technical Debt

- [ ] Add proper error types
- [ ] Add retry logic with exponential backoff
- [ ] Add rate limiting per board
- [ ] Add caching for repeated runs
- [ ] Add tests for each board fetcher

---

## How to Contribute

When you identify a gap:
1. Add it to this file under "Active Improvements"
2. Create implementation plan
3. Execute
4. Move to "Completed" with result
