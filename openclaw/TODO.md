# OpenClaw TODO

## In Progress

### OpenClaw / Kiro
- Calendar-aware scheduling — Kiro can accept commitments/meetings on Enrique's behalf if beneficial, but must verify via Google Calendar first. Configure unavailable times. Ask if meeting > 20min. Consider prep time needed.

## To Do

### Claude Code (config / rebuild session)
- [ ] Update AGENTS.md to relax "never accept commitments" hard limit with calendar-gated rules
- [ ] Update TOOLS.md to document new bundled plugins (summarize, gogcli)
- [ ] Restructure daily skill scan into a daily self-improvement scan: skills, new tech, things that could make Kiro better
- [ ] Improve daily scan cron job prompt to cover self-improvement scope (not just skills)

### OpenClaw / Kiro (autonomous or cron-driven)
- [ ] Scan ClawHub for popular/high-rated skills — evaluate usefulness, quality vs marketing, decide: install, build custom, or skip
- [ ] Test gogcli OAuth flow — run gogcli once to authenticate, verify calendar access works
- [ ] Test summarize plugin — try summarizing a URL and a YouTube video, confirm it works end-to-end

## Done
- [x] Check bundled plugins catalog — enabled `summarize` and `gogcli`
