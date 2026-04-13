---
name: oryx-bench
description: Manage ZSA keyboard layouts via the oryx-bench CLI. Use when discussing keyboard layouts, key bindings, layer changes, achordion, tap-hold, custom keycodes, key overrides, combos, ZSA, Oryx, Keymapp, QMK, or the ZSA Voyager. v0.1 supports the Voyager geometry only — Moonlander/Ergodox are tracked for a future release. Supports both Oryx-mode (visual editor + local code) and local-only mode (no cloud dependency).
---

# oryx-bench

You are working with a ZSA keyboard layout managed via the `oryx-bench` CLI.
There are multiple authoring surfaces; the user picks which combination
works for them. Your job is to read the project state, propose changes,
edit the right files, and ship clean firmware.

This skill is **project-local**. It loaded because there is an
`oryx-bench` project at the current working directory (or an ancestor).

## Mental model — read this every time

The tool is built around **source-of-truth factoring by concern**. Each
concern lives in exactly one place. The build deterministically merges
them.

| Concern | Source of truth | You edit it via |
|---|---|---|
| Visual layout (which key sends what) | `pulled/revision.json` (Oryx mode) **or** `layout.toml` (local mode) | Tell user to click in Oryx (Oryx mode) **or** edit `layout.toml` directly (local mode) |
| Declarative QMK features (achordion, key overrides, macros, combos, config) | `overlay/features.toml` | Edit directly |
| Procedural code (state machines, RGB animations, custom keycodes with state) | `overlay/*.zig` | Edit directly |
| Vendored upstream C libraries | `overlay/*.c` | Paste-only, do not modify |
| Project config | `kb.toml` | Edit directly |

The build is the deterministic merge of all of the above.

**Run `oryx-bench status` first** to find out which mode the current
project is in (Oryx or local) and the sync state. You'll need this before
you can give correct instructions for a layout change.

## Always start by reading state

Before answering any question about the layout, run **`status` first,
then `show`, then `lint`**:

```bash
oryx-bench status            # cheap; tells you mode, sync state, build cache state
oryx-bench show              # rendered grid for the active layer
oryx-bench lint              # flagged anti-patterns
```

`status` is critical because it tells you whether you're in Oryx mode or
local mode (which determines whether visual layout edits go through Oryx
or `layout.toml`). It also tells you if Oryx has updates the local cache
hasn't picked up (auto-pull will handle this on the next read command).

For deeper inspection:

```bash
oryx-bench explain L_pinky_home    # cross-layer view of one position
oryx-bench find KC_BSPC            # find every place a code appears
oryx-bench find anti:lt-on-high-freq    # find every instance of a lint anti-pattern
```

## Two paths for any change — always classify first

When the user asks for a change, **classify it before responding**:

### Path A — Visual layout change (you cannot do this directly)

Examples:
- "Move backspace to a different position"
- "Swap Q and ;"
- "Change the symbol layer's number row"
- "Add a new layer"
- "Bind LGUI to the right thumb"
- "Change which letter is on the home row"

Do this:

1. **Verify the position name** with `oryx-bench explain <position>` if
   you're going to reference a specific spot. Use the names the CLI
   actually uses; don't make them up.
2. **Determine the project's mode** from `oryx-bench status`:
   - **Oryx mode**: tell the user *exactly what to click* in Oryx
     ("In the Main layer, click position `R_thumb_outer` and change the
     Tap action to plain Backspace, then save")
   - **Local mode**: edit `layout.toml` directly with the `Edit` tool
3. **If the change touches multiple positions, batch all the click
   instructions into a single message** so the user can do them in one
   Oryx session, rather than back-and-forth per key.
4. **Wait for the user to confirm** they made the change (Oryx mode)
5. Run `oryx-bench show` to verify (auto-pull will fetch the new state)
6. Run `oryx-bench lint` to check for new issues

### Path B — Behavior change (you do this directly)

Examples:
- "Fix the LT-on-Backspace misfire" → drop achordion in `features.toml`
- "Make Shift+Backspace send Delete" → key override in `features.toml`
- "Add a custom keycode that types my email" → macro in `features.toml`
- "Tune the tap-hold timing on the right thumb" → achordion timeout in `features.toml`
- "Add a tap dance" → procedural code in `overlay/*.zig`
- "Make the LEDs light up when I'm in Sym+Num" → RGB code in `overlay/*.zig`

Do this:

1. **Read `overlay/README.md`** to see what already exists
2. **Read the relevant existing overlay files** (`features.toml`, any
   `*.zig`, etc.)
3. Decide which tier the change belongs in:
   - **Tier 1** (`features.toml`): if it's declarative configuration
     (the same template every user fills in) → edit `features.toml`
   - **Tier 2** (`*.zig`): if it needs procedural logic, state, or
     event-by-event handling → edit a Zig file (create one if needed)
   - **Tier 2′** (`*.c`): only when vendoring an upstream library
     unmodified
4. Edit the file directly with the `Edit` tool
5. Run `oryx-bench lint` to catch issues
6. Run `oryx-bench build` to verify it compiles
7. Run `oryx-bench diff` to show the user what changed
8. **Wait for explicit user approval** before running `oryx-bench flash`

### Mixed requests

When a user request contains multiple changes, **classify each
independently** and propose both paths in one reply. Example: "I want
Shift+Backspace to send Delete AND I want to move the underscore key" is
Path B (key override → edit `features.toml`) + Path A (move key → tell
user to click in Oryx).

Do the Path B work while the user is in Oryx doing the Path A clicks.
Don't flash until both have landed and `lint` is clean.

## When in doubt, ask

If a request is ambiguous (e.g., "smoother", "faster", "better") run
`oryx-bench status`, `lint`, and `show` first, **then ask the user for a
concrete symptom** before proposing a fix:

- "Which layer/key are you noticing the issue on?"
- "What do you observe — misfires, lag, visual jumpiness?"

Don't guess at interpretation. Keyboard tuning is personal and a wrong
fix can be worse than no fix.

## Anti-patterns you must recognize

Lint catches all of these automatically. When you see them in
`oryx-bench lint` output:

| Lint rule | What it means | Recommended fix |
|---|---|---|
| `lt-on-high-freq` | Layer-tap on Backspace/Space/Enter/Delete/Tab/Esc — causes misfires | **Usually not by moving the key**. Add achordion in `features.toml`. See `reference/overlay-cookbook.md#achordion`. (If the user explicitly asks to move the key, that's Path A and fine.) |
| `unreachable-layer` | A layer with no MO/TG/TO/TT/DF/LT pointing to it | Path A — add an entry from another layer in Oryx, or remove the dead layer |
| `kc-no-in-overlay` | `KC_NO` (dead key) where `KC_TRANSPARENT` was probably intended | Path A — change KC_NO to KC_TRNS in Oryx |
| `orphaned-mod-tap` | Mod-tap with `tap: null` — leftover from a cleared mod-tap | Path A — convert to a plain modifier in Oryx |
| `mod-tap-on-vowel` | Home-row mod on a vowel — known misfire pattern | Either accept (info-level), or move via Oryx (Path A) |
| `tt-too-short` | `TAPPING_TERM` < 150ms with mod-taps in use | Set `tapping_term_ms` in `features.toml [config]` |
| `oryx-newer-than-build` | Oryx state changed since the last build | Run `oryx-bench build` |
| `overlay-dangling-position` | `features.toml` references a position name that doesn't exist in the visual layout | Either fix the position name, or update Oryx to add the binding |
| `process-record-user-collision` | Two overlay files both define `process_record_user` | Tier 2 code should implement `process_record_user_overlay` instead — see `reference/overlay-cookbook.md` |

For the full rule reference (severity, why-bad, examples), see
`reference/lint-rules.md`.

## Safety rules

These are non-negotiable:

1. **Never run `oryx-bench flash` without explicit user approval.** Always
   show `oryx-bench diff` and the `flash --dry-run` output, then ask "ship
   this?" before flashing. "Just flash it" or "yes go" from the user IS
   sufficient approval — once given, you don't need to re-ask every turn.
2. **Never edit anything under `pulled/`.** That entire directory is
   overwritten on every `oryx-bench pull`, including `revision.json` and
   any generated files. All visual-layout changes go through Oryx (Path A)
   or `layout.toml` (local mode).
3. **`oryx-bench build` must succeed before any `flash`.** If build fails,
   stop and surface the error.
4. **`oryx-bench lint` should show zero new errors after your edit.** New
   warnings are OK if you can justify them or the user accepts them; new
   errors are not.
5. **Never push to Oryx.** There is no API for it. If you find yourself
   wanting to, you've misclassified a Path A change as Path B. Re-read
   the classification.
6. **Before using a position name in instructions to the user, verify it
   with `oryx-bench explain <position>`.** Don't invent position names —
   the CLI's naming is canonical.

### Build-failure iteration

If `oryx-bench build` fails after your edit:

- **If the error is in code you just wrote** (a `*.zig` you authored or a
  `features.toml` you edited): attempt up to two fixes based on the error
  message. If you can't resolve in two tries, stop and surface the error
  + your attempted fixes to the user. **Don't spiral.**
- **If the error is in vendored code** (`overlay/*.c` from upstream) or
  in *generated* files (anything under `pulled/` or in the build dir):
  stop immediately, do not touch, report to the user. You did not write
  those bytes.

### Don't be preachy about flashing

The user knows it's their keyboard. Don't lecture. Once they've given
approval, run the command. Use `oryx-bench flash --yes` for non-interactive
contexts (agent loops); the `--yes` flag bypasses the CLI's own
confirmation prompt but does NOT replace the in-conversation approval.

## When to run `pull`

Auto-pull (`auto_pull = "on_read"`) handles most cases automatically, so
you usually don't need to run `pull` explicitly. Run it manually when:

- The user explicitly says they edited in Oryx and you want to be sure
- `oryx-bench status` reports "oryx newer than last pull" and you want to
  fetch immediately rather than waiting for the next read command
- The user reports `show` output is wrong vs. what they see in Oryx (very
  rare, suggests a sync edge case worth investigating)

In **local mode** there is no `pull`. The setting is a no-op.

## Project-not-found case

If any `oryx-bench` command returns "no project found" (no `kb.toml` in
the current directory or any ancestor):

- You're not in a project directory
- **Don't auto-`init`** — ask the user whether they want to:
  - `cd` into an existing project, or
  - run `oryx-bench init --hash <H>` (Oryx mode) or
    `oryx-bench init --blank --geometry voyager` (local mode) to create
    a new one

Ask which they want; don't guess.

## Not in scope

Things this tool does **not** do — say so and redirect:

- **Cloud builds** — use Oryx's own download for that
- **Remote flashing** — you have to be at the keyboard
- **Layout sharing/publishing** — that's Oryx URLs
- **Account management** — manage Oryx accounts in your browser
- **Pushing local edits back to Oryx** — there's no public write API.
  After `oryx-bench detach` you cannot go back to Oryx mode without
  `oryx-bench attach`, which **overwrites** your local layout
- **Non-ZSA keyboards** — out of scope; we're scoped to ZSA boards
- **Editing `pulled/revision.json` or any generated files** — these are
  derived; edits are overwritten

## Modes you might be in

The project is in one of two modes (check `oryx-bench status` to find out):

- **Oryx mode**: visual layout lives in Oryx, fetched into
  `pulled/revision.json`. Path A changes happen in Oryx; you tell the user
  to click. Auto-pull handles sync.
- **Local mode**: visual layout lives in `layout.toml` in the project.
  Path A changes happen in `layout.toml` directly via the `Edit` tool. No
  Oryx involvement.

The Path B behavior is identical in both modes — you always edit
`overlay/features.toml`, `overlay/*.zig`, etc.

## Geometries supported

The CLI is the source of truth for which geometries (Voyager / Moonlander
/ Ergodox) are supported. **Don't hard-code expectations** — run
`oryx-bench init --help` if the user asks "do you support X?" and read
the actual `--geometry` accepted values. As of v0.1, only Voyager. Adding
new geometries is documented in `CONTRIBUTING.md` if the user wants to
contribute.

## Commands you have

```
oryx-bench setup [--full]         Detect toolchain. Idempotent. --full runs each tool's --version.
oryx-bench init                   Create project skeleton. --hash for Oryx mode, --blank for local mode.
oryx-bench attach --hash <H>      Switch local-mode project to Oryx mode (overwrites local).
oryx-bench detach [--force]       Switch Oryx-mode project to local mode. ONE-WAY.
oryx-bench pull                   Manually fetch from Oryx (auto-pull usually does this).
oryx-bench show [LAYER]           Render layer(s) as ASCII split-grid.
oryx-bench explain POSITION       Cross-layer view of one position.
oryx-bench find QUERY             Search across layers.
oryx-bench lint [--strict]        Static analysis. --strict exits non-zero on warnings too.
oryx-bench status                 One-screen overview — RUN THIS FIRST in any session.
oryx-bench build [--dry-run]      Compile firmware. Cached. Fast on no-op.
oryx-bench diff [REF]             Semantic diff vs git ref. Show user before flashing.
oryx-bench flash [--dry-run] [--yes] [--force]   Flash to keyboard. REQUIRES USER APPROVAL. --force bypasses the build-freshness check.
oryx-bench upgrade-check          Re-run lint after `cargo install --force oryx-bench`. Surfaces uncatalogued keycodes.
oryx-bench skill install          Already done if you're reading this.
```

For detailed flags and examples, see `reference/command-reference.md`
(lazy-loaded when you need it).

## Reference files (lazy-loaded — don't read until needed)

- `reference/workflows.md` — task playbooks for common requests
- `reference/overlay-cookbook.md` — achordion, key overrides, custom
  keycodes, combos, RGB recipes (full TOML and Zig forms)
- `reference/lint-rules.md` — every lint rule with id, severity,
  why-bad, fix
- `reference/command-reference.md` — full CLI surface

Read these on demand, not preemptively.
