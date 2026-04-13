# Workflows

Task-oriented playbooks. Each playbook is a recipe Claude can follow when
the user expresses a particular intent. Read this lazily, only when the
user's request matches one.

## Setup playbooks

### "I just installed oryx-bench, what do I do first?"

1. `oryx-bench setup` — verify the toolchain
2. Ask the user: do they have an existing Oryx layout, or starting fresh?
   - If existing: `oryx-bench init --hash <hash from oryx URL>`
   - If fresh: `oryx-bench init --blank --geometry voyager`
3. `oryx-bench skill install` (project-local Claude Code skill)
4. `oryx-bench show` to verify the project is healthy
5. `oryx-bench lint` to surface any pre-existing issues

### "Project not found" error

The CLI can't find a `kb.toml` in the current directory or any ancestor.

1. Ask: do they want to create a new project, or `cd` into an existing one?
2. If new: prompt for hash (Oryx mode) or geometry (local mode), then run
   `oryx-bench init` accordingly
3. **Don't auto-init.** Always confirm.

## Diagnostic playbooks

### "Audit my layout for issues"

1. `oryx-bench status` — what mode is this project in, what's the sync state
2. `oryx-bench show` for each layer (or all)
3. `oryx-bench lint` — group findings into "must fix" (errors), "should
   consider" (warnings), "stylistic" (info)
4. For each finding, propose either a Path A or Path B fix and let the
   user pick which to apply

### "Why is this layer empty?" or "What does layer X do?"

1. `oryx-bench show <layer-name>`
2. If many positions show as `KC_NO` or blank, run `oryx-bench lint` —
   likely `unreachable-layer` or `kc-no-in-overlay`
3. If the layer has no `activated_by` (no MO/TG/etc anywhere referencing
   it), it's dead code. Path A — either remove it or add an activation
   key in Oryx (or `layout.toml` in local mode).

### "Where is X bound?"

```bash
oryx-bench find KC_X            # by keycode
oryx-bench find layer:Main      # by layer
oryx-bench find hold:LSHIFT     # by hold action
oryx-bench find anti:lt-on-high-freq    # by anti-pattern
```

## Path B (behavior) playbooks

### "Fix the LT-on-Backspace misfire"

The user reports backspace (or space, enter, delete) misfires when
typing fast.

1. Confirm via `oryx-bench lint`. Look for `lt-on-high-freq`. If absent,
   the issue is something else — switch to "Tune tap-hold timing".
2. The right fix is **achordion**, not moving the key in Oryx. Open
   `reference/overlay-cookbook.md#achordion` for the full recipe.
3. Read `overlay/features.toml`. If achordion is already enabled, just
   add a `[[achordion.timeout]]` for the problematic key. If not enabled,
   add the whole `[achordion]` section per the cookbook.
4. `oryx-bench lint && oryx-bench build`
5. Show diff, ask for approval, then `oryx-bench flash`

The fix changes the *behavior* of the existing visual binding without
touching the visual layout. Oryx still shows the same `LT(N, KC_BSPC)`
on the right thumb; the overlay makes it actually work.

### "Add Shift+Backspace → Delete" (key override)

1. Read `overlay/features.toml`. If a `[[key_overrides]]` section exists,
   add the new override. If not, create the first one — see
   `reference/overlay-cookbook.md#key-overrides`.
2. Verify `[features] key_overrides = true` is set
3. Lint, build, diff, ask for approval, flash

Common requests in this category:
- Shift+Backspace → Delete
- Shift+Esc → ~ (US keyboard)
- GUI+Backspace → Delete
- Ctrl+; → :

### "Type my email with one key"

1. **In `features.toml`**: add a `[[macros]]` block:
   ```toml
   [[macros]]
   name  = "CK_EMAIL"
   sends = "you@example.com"
   ```
2. **Path A — bind in Oryx**: tell the user to open Oryx, pick a position,
   set its Code field to the next available `USERnn` slot. The build
   automatically maps `CK_EMAIL` to whichever USERnn slot is unbound.
3. `oryx-bench pull`, lint, build, diff, ship.

If multiple macros all need USERnn slots and the user wants to pick which
goes where, ask them to use `USER01`, `USER02`, etc explicitly in Oryx
and tell you the mapping.

### "Tune tap-hold timing on a specific key"

1. Identify the position via `oryx-bench explain` and the user's
   description
2. Two levers:
   - **Global**: bump `tapping_term_ms` in `[config]` of `features.toml`.
     200 → 220 is a good first try.
   - **Per-key**: if achordion is enabled, add an
     `[[achordion.timeout]]` for the specific binding. If not, add a
     `[[tapping_term_per_key]]` entry.
3. Lint, build, diff, ship
4. Wait for the user to live with the new setting before tuning again

### "Add a state machine / RGB animation / tap dance"

This is Tier 2 — needs procedural Zig code.

1. Read `reference/overlay-cookbook.md#tap-dance` (or the relevant
   section)
2. Read any existing `*.zig` files in `overlay/`
3. Create a new `.zig` file in `overlay/` with the appropriate hooks
4. **If the file defines `process_record_user`**: rename it to
   `process_record_user_overlay`. The generator's `process_record_user`
   will dispatch to it. See the cookbook's process_record_user collision
   section.
5. Lint, build (will catch any syntax / link issues), diff, ship

### "I want to roll back the last change"

1. `git status` to see what's modified
2. If in `overlay/`: `git checkout HEAD -- overlay/...`
3. If in `pulled/`: you cannot directly revert without re-editing in Oryx.
   `git diff pulled/` shows what changed; the user replicates the reversion
   in Oryx, then `oryx-bench pull` again
4. If in `layout.toml` (local mode): `git checkout HEAD -- layout.toml`
5. Lint, build, diff, ship

## Path A (visual layout) playbooks

### "Move backspace from one position to another"

1. Determine mode via `oryx-bench status`
2. **Oryx mode**: tell user to click — verify position names with
   `oryx-bench explain` first. Wait for confirmation, then `pull`, `show`,
   `lint`.
3. **Local mode**: edit `layout.toml` directly with the `Edit` tool. Move
   the key from one position entry to another.

### "Swap two letters"

Same as above, but two clicks. Batch them in one message.

### "Add a new layer"

1. **Oryx mode**: instruct user to add the layer in Oryx, give it a
   distinctive name, and bind at least one position. Tell them they also
   need to add a `MO` or `TG` to it from another layer (otherwise lint
   will flag it as unreachable). Then `oryx-bench pull`.
2. **Local mode**: add a new `[[layers]]` section to `layout.toml`. Set
   the position to the next integer. Add at least one binding. Add an
   activation entry to another layer.

## Pull / sync playbooks

### "I edited in Oryx but `show` looks the same"

1. `oryx-bench status` first — does it report the local cache as stale?
2. If yes: `oryx-bench pull` (auto-pull may not have triggered yet because
   of the 60s cache). Then `show` again.
3. If no: the user might be looking at the wrong project, or at the wrong
   layer. Verify which layer they think they edited and which one is
   currently the default. Use `oryx-bench show <layer-name>` to render a
   specific layer.

### "Reset everything to what's on Oryx"

This is destructive. Confirm before doing it.

1. `git status` — anything uncommitted in `overlay/`?
2. If yes: ask the user if they want to keep those changes (probably yes)
3. `oryx-bench pull --force` to refresh the visual layout
4. Lint, build, ship if they want to flash the reset version

## Build / flash playbooks

### "Compile and flash"

1. `oryx-bench lint` — must be clean (no errors)
2. `oryx-bench build` — must succeed
3. `oryx-bench diff` — show the user what's about to ship
4. **Wait for explicit approval** ("yes", "ship it", "go", "do it")
5. `oryx-bench flash --dry-run` — print the firmware path, size, sha256
6. `oryx-bench flash` (or `--yes` if running in agent mode)

### "Build failed, what do I do?"

See SKILL.md → "Build-failure iteration" section. Two-attempt rule.

### "Flash didn't work"

1. Check `oryx-bench setup` — is `wally-cli` available? Is `keymapp`?
2. Did the user put the keyboard in bootloader mode? (Press the reset
   button, or use `QK_BOOT` if bound)
3. Did `oryx-bench flash` print "use Keymapp GUI" instructions because
   `wally-cli` wasn't available? If so, walk through the GUI steps.

## Mode switching playbooks

### "Switch from Oryx to local mode"

1. Confirm the user understands this is **one-way** — they cannot easily
   go back. Going back requires `oryx-bench attach` which overwrites
   their local layout with Oryx's current state.
2. `oryx-bench detach` — this converts `pulled/revision.json` to
   `layout.toml` and removes `pulled/`.
3. `oryx-bench show` to verify the conversion is correct
4. Commit the change to git

### "Switch from local mode back to Oryx"

1. **Strong warning**: this overwrites `layout.toml` with whatever Oryx
   currently has. **Local edits to `layout.toml` will be lost** unless
   they were made in Oryx first.
2. Confirm the user has either (a) committed any local-only changes to a
   separate branch first, or (b) doesn't care about local-only changes.
3. `oryx-bench attach --hash <H>` (the user provides the hash from Oryx)
4. The command refuses unless the working tree is clean or `--force` is
   passed.
5. `oryx-bench show` to verify

## When you're stuck

1. `oryx-bench status` — what's the current state?
2. `oryx-bench lint --strict` — anything obviously wrong?
3. Read `overlay/README.md` — what's already there?
4. Look at recent git history of `overlay/` and `pulled/` — what changed
   recently?
5. **Ask the user what symptom they're experiencing** rather than guessing.
