---
phase: quick-4
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - /etc/nixos/zeroclaw/reference/full-profile.md
  - /etc/nixos/zeroclaw/reference/reusable-responses.md
  - /etc/nixos/zeroclaw/reference/SUMMARY.md
autonomous: true
requirements: [QUICK-4]

must_haves:
  truths:
    - "Kiro can read full-profile.md and reusable-responses.md from the reference directory"
    - "SUMMARY.md documents both files with when-to-use guidance"
    - "No rebuild required — changes are live immediately via symlink"
  artifacts:
    - path: "/etc/nixos/zeroclaw/reference/full-profile.md"
      provides: "Symlink to openclaw full-profile.md"
    - path: "/etc/nixos/zeroclaw/reference/reusable-responses.md"
      provides: "Symlink to openclaw reusable-responses.md"
    - path: "/etc/nixos/zeroclaw/reference/SUMMARY.md"
      provides: "Updated TOC with openclaw reference entries"
  key_links:
    - from: "/etc/nixos/zeroclaw/reference/full-profile.md"
      to: "/etc/nixos/openclaw/reference/full-profile.md"
      via: "filesystem symlink"
    - from: "/etc/nixos/zeroclaw/reference/reusable-responses.md"
      to: "/etc/nixos/openclaw/reference/reusable-responses.md"
      via: "filesystem symlink"
---

<objective>
Add openclaw reference docs (full-profile.md and reusable-responses.md) to Kiro's reference directory as on-demand symlinks, and update SUMMARY.md to document them.

Purpose: Kiro can read Enrique's full profile and reusable application responses when relevant (job search tasks, application drafting) without these files being auto-loaded into daily context.
Output: Two symlinks in /etc/nixos/zeroclaw/reference/ and an updated SUMMARY.md — no rebuild required.
</objective>

<execution_context>
@/home/hybridz/.claude/get-shit-done/workflows/execute-plan.md
@/home/hybridz/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
The reference directory at /etc/nixos/zeroclaw/reference/ is symlinked from ~/.zeroclaw/reference/ via module.nix (mkOutOfStoreSymlink). Files added here are immediately visible to Kiro — no rebuild needed.

The openclaw source files to link:
- /etc/nixos/openclaw/reference/full-profile.md (8KB — Enrique's profile, resume, job search state)
- /etc/nixos/openclaw/reference/reusable-responses.md (20KB — polished application responses)

Current reference/ contents:
- SUMMARY.md — ZeroClaw upstream docs TOC (keep existing content, append new section)
- upstream-docs/ — symlink to ~/Projects/zeroclaw/docs
</context>

<tasks>

<task type="auto">
  <name>Task 1: Create symlinks and update SUMMARY.md</name>
  <files>
    /etc/nixos/zeroclaw/reference/full-profile.md
    /etc/nixos/zeroclaw/reference/reusable-responses.md
    /etc/nixos/zeroclaw/reference/SUMMARY.md
  </files>
  <action>
    1. Create two symlinks in /etc/nixos/zeroclaw/reference/:
       - ln -s /etc/nixos/openclaw/reference/full-profile.md /etc/nixos/zeroclaw/reference/full-profile.md
       - ln -s /etc/nixos/openclaw/reference/reusable-responses.md /etc/nixos/zeroclaw/reference/reusable-responses.md

    2. Append a new section to /etc/nixos/zeroclaw/reference/SUMMARY.md at the end:

    ```markdown
    ## Personal Reference (On-Demand)

    These files are sourced from the openclaw reference directory. Read them when the task involves job applications, resume review, or application drafting — they are NOT loaded by default.

    - **[full-profile.md](full-profile.md)** — Enrique's full profile and background: resume content, job search state, career narrative, skills. Use when drafting applications or answering profile questions.
    - **[reusable-responses.md](reusable-responses.md)** — Polished application responses to common prompts (cover letters, motivation statements, behavioral questions). Use when writing or improving application materials.
    ```

    Do not modify any existing content in SUMMARY.md — only append.
  </action>
  <verify>
    <automated>
      ls -la /etc/nixos/zeroclaw/reference/ | grep -E "full-profile|reusable-responses" &&
      readlink /etc/nixos/zeroclaw/reference/full-profile.md &&
      readlink /etc/nixos/zeroclaw/reference/reusable-responses.md &&
      grep -q "Personal Reference" /etc/nixos/zeroclaw/reference/SUMMARY.md
    </automated>
  </verify>
  <done>
    Both symlinks resolve to their openclaw source files. SUMMARY.md contains the "Personal Reference (On-Demand)" section documenting both files with when-to-use guidance.
  </done>
</task>

</tasks>

<verification>
After task completion:
- ls -la /etc/nixos/zeroclaw/reference/ shows both symlinks
- cat /etc/nixos/zeroclaw/reference/full-profile.md shows file content (symlink resolves)
- cat /etc/nixos/zeroclaw/reference/reusable-responses.md shows file content (symlink resolves)
- tail -20 /etc/nixos/zeroclaw/reference/SUMMARY.md shows the new Personal Reference section
</verification>

<success_criteria>
- Two symlinks exist in /etc/nixos/zeroclaw/reference/ pointing to openclaw reference files
- SUMMARY.md documents both files with on-demand guidance (when to read them)
- No rebuild performed or required
- Changes committed to git
</success_criteria>

<output>
After completion, create `.planning/quick/4-add-openclaw-reference-docs-to-zeroclaw-/4-SUMMARY.md`
</output>
