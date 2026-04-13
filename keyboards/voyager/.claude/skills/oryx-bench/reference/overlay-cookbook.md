# Overlay cookbook

Recipes for the Tier 1 (declarative `features.toml`) and Tier 2
(procedural `*.zig`) authoring surfaces.

This file is the **single source of truth** for cookbook recipes. The
README and example project link here. Do not duplicate.

> **Tier-1-first principle**: if a recipe exists in both Tier 1 (TOML) and
> Tier 2 (Zig) form, **prefer Tier 1**. Less code, less to maintain,
> validates at parse time, generates correct C automatically. Only drop
> to Tier 2 when the feature genuinely needs procedural logic that TOML
> can't capture.

---

## Achordion — fix tap-hold misfires (Tier 1)

### When to use

- `oryx-bench lint` flags `lt-on-high-freq`
- The user reports occasional misfires on a layer-tap key
- You want tighter, more reliable tap-hold disambiguation than vanilla QMK
  offers

### What it does

Vanilla QMK tap-hold resolves "tap" vs "hold" purely by time. This fails
for high-frequency keys (Backspace) where fast bursts cross the threshold
accidentally.

Achordion adds a second condition: a tap-hold key only resolves as
**hold** if the *next* key pressed is on the **opposite half** of the
keyboard. Same-hand follow-ups force a tap. Eliminates the misfire class
on split keyboards.

### Tier 1 form (preferred)

`overlay/features.toml`:

```toml
[achordion]
enabled        = true
chord_strategy = "opposite_hands"

# Tighter timeouts for high-frequency keys
[[achordion.timeout]]
binding = "LT(SymNum, BSPC)"   # symbolic — uses your Oryx layer name
ms      = 600

[[achordion.timeout]]
binding = "LT(System, DEL)"
ms      = 600

# Disable streak-chord for the erase keys (we never want them to chord on streak)
[[achordion.no_streak]]
binding = "LT(SymNum, BSPC)"

# Same-hand chord exceptions (rare; only when your typing pattern needs them)
# [[achordion.same_hand_allow]]
# tap_hold = "LSFT_T(KC_A)"
# other    = "KC_R"
```

`oryx-bench build` automatically:
- Vendors the upstream `achordion.c` library body into the build
- Generates the per-key `achordion_timeout()`, `achordion_chord()`, and
  `achordion_streak_chord_timeout()` callbacks from your TOML
- Hooks `process_achordion()` into `process_record_user`
- Hooks `achordion_task()` into `matrix_scan_user`
- Sets `PERMISSIVE_HOLD` off in `config.h` (achordion is incompatible)

You never write C. You never see C unless you pass `--emit-overlay-c`.

### Caveats

- **Don't enable `permissive_hold`**: lint will catch this conflict
- **Same-hand chords break** unless whitelisted in `[[achordion.same_hand_allow]]`
- **First few hours feel weird**: your fingers learned to compensate for
  vanilla tap-hold misfires. Achordion makes things "too clean" and you'll
  occasionally tap when you meant to hold. Passes within a day.

### See also

- [`examples/voyager-dvorak/overlay/features.toml`](../../../examples/voyager-dvorak/overlay/features.toml)
  has a complete working version with the LT-on-Backspace fix
- [Getreuer's achordion writeup](https://getreuer.info/posts/keyboards/achordion/)

---

## Key overrides — Shift+Backspace → Delete (Tier 1)

### When to use

You want a `(modifier + key)` combo to send a different keystroke. Common:
- `Shift+Backspace → Delete`
- `Shift+Esc → ~` (US convenience)
- `GUI+Backspace → Delete`
- `Shift+. → !`

### Tier 1 form

`overlay/features.toml`:

```toml
[[key_overrides]]
mods  = ["LSHIFT"]     # any combination of LSHIFT, RSHIFT, LCTRL, RCTRL, LALT, RALT, LGUI, RGUI
key   = "BSPC"
sends = "DELETE"

[[key_overrides]]
mods  = ["LSHIFT"]
key   = "ESC"
sends = "S(GRAVE)"     # = ~ on US layout

[[key_overrides]]
mods  = ["LCTRL"]
key   = "SCLN"
sends = "COLN"

# Optional: layer scope
[[key_overrides]]
mods    = ["LSHIFT"]
key     = "DOT"
sends   = "EXLM"
layers  = ["Main"]      # only fires on the Main layer

# Make sure key_overrides feature is enabled
[features]
key_overrides = true
```

The build emits the corresponding `key_override_t` array, the dispatch
function, and the `KEY_OVERRIDE_ENABLE = yes` rules.mk line automatically.

### Caveats

- Order doesn't matter except when two overrides could match the same
  input — be specific with `mods`
- Key overrides do not stack with the original key (Shift+Backspace
  becomes Delete, not Shift+Delete)

---

## Macros — type my email with one key (Tier 1)

### When to use

A single keystroke types a multi-character sequence: email, snippet, code
template.

### Tier 1 form

`overlay/features.toml`:

```toml
[[macros]]
name  = "CK_EMAIL"
sends = "you@example.com"

[[macros]]
name  = "CK_SIG"
sends = "--\nYour Name\nyou@example.com"

[[macros]]
name  = "CK_GIT_STATUS"
sends = "git status\n"
```

### Path A — bind in Oryx

Custom keycodes need to be **bound to a position** in the visual layout.

1. Open Oryx, pick the position
2. In the binding panel, set the Code field to `USER01` (or any unbound
   USERnn slot)
3. The build maps `CK_EMAIL` to whichever USERnn slot is chosen, in order
4. After binding, run `oryx-bench pull`

If you need explicit control over which USERnn each macro uses, set the
`slot` field:

```toml
[[macros]]
name  = "CK_EMAIL"
slot  = "USER01"
sends = "you@example.com"
```

Then bind to `USER01` in Oryx specifically.

### Caveats

- USER01..USER15 is the range Oryx exposes
- `SEND_STRING` is synchronous and briefly blocks matrix scan; for very
  long strings (> 50 chars) consider chunking
- Macros that need conditional behavior (e.g., type different things in
  different layers) are Tier 2 — see "Stateful custom keycodes" below

---

## Combos — Q+W → Esc

### When to use

Multiple keys pressed simultaneously fire a different keystroke.

### Path A first (preferred)

Oryx supports combos in its UI. Use Oryx unless you need something Oryx
can't express:
- Visual binding
- Easy to discover and edit
- No build infrastructure

Tell user: open the layer, click "Add combo", select positions, set
output, save. Then `oryx-bench pull`.

### Tier 1 form (when Path A doesn't suffice)

```toml
[[combos]]
keys       = ["L_index_top", "L_middle_top"]   # symbolic position names
sends      = "ESC"
layer      = "Main"                             # optional: only on this layer
timeout_ms = 30                                 # optional: per-combo timeout

[features]
combos = true
```

The build emits the `combos[]` array, `process_combo_event` if needed,
and the `COMBO_ENABLE = yes` rules.mk line.

### Caveats

- `timeout_ms` < 30ms is aggressive; > 50ms fights with rapid typing
- Lint catches combo collisions (two combos sharing keys)

---

## Per-key tapping term tuning (Tier 1)

```toml
[[tapping_term_per_key]]
binding = "LCTL_T(KC_A)"    # symbolic
ms      = 180

[[tapping_term_per_key]]
binding = "LSFT_T(KC_O)"
ms      = 200
```

The build emits `get_tapping_term()` with the appropriate switch
statement and sets `TAPPING_TERM_PER_KEY` in config.h.

**Don't combine wholesale per-key tuning with achordion.** Achordion is
the better hammer; per-key tuning is the surgical scalpel for one or two
specific keys after achordion.

---

## RGB layer indicators (Tier 2 — needs Zig)

### When to use

LEDs react to layer state, time, or other runtime conditions.

### Why Tier 2

Per-frame logic that runs in `rgb_matrix_indicators_user()`. This isn't
declarative — it's a function body that QMK calls every frame. TOML
can't capture this.

### Tier 2 form

`overlay/rgb_layers.zig`:

```zig
const c = @cImport({
    @cInclude("quantum.h");
    @cInclude("rgb_matrix.h");
});

export fn rgb_matrix_indicators_user() bool {
    const layer = c.get_highest_layer(c.layer_state);
    switch (layer) {
        1 => {  // SymNum
            var i: u8 = 0;
            while (i < c.RGB_MATRIX_LED_COUNT) : (i += 1) {
                c.rgb_matrix_set_color(i, 0x00, 0x10, 0x40);  // dim blue
            }
        },
        2 => {  // System
            c.rgb_matrix_set_color_all(0x40, 0x10, 0x00);     // dim orange
        },
        3 => {  // Gaming
            c.rgb_matrix_set_color_all(0x40, 0x00, 0x00);     // dim red
        },
        else => {},
    }
    return false;  // override Oryx-defined RGB
}
```

Drop into `overlay/`. The build picks up `*.zig` automatically (no
`features.toml` change needed unless you want to disable RGB matrix in
the feature flags, which you wouldn't).

### Caveats

- Returning `false` overrides any Oryx-configured RGB. Return `true` to
  *augment* instead of replace.
- `RGB_MATRIX_LED_COUNT` is provided by QMK (52 on the Voyager: 26 per
  side).
- Zig's `@cImport` reads QMK headers directly — no bindgen needed.

---

## Stateful custom keycodes (Tier 2 — needs Zig)

### When to use

A custom keycode needs state. Examples:
- Toggle between work and personal email on alternating presses
- Leader key sequences (press X then Y then Z → action)
- Custom keycode that types different things based on the active layer

### Tier 2 form

`overlay/email_toggle.zig`:

```zig
const c = @cImport({
    @cInclude("quantum.h");
});

// Bind this in features.toml [[macros]] with slot = "USER01"
// (the macro just exists to give it a USERnn keycode the visual layout
// can reference; the actual logic is here)
const CK_EMAIL_TOGGLE: u16 = c.QK_USER_0;  // = USER01

var email_state: bool = false;

export fn process_record_user_overlay(keycode: u16, record: *c.keyrecord_t) bool {
    if (!record.event.pressed) return true;
    switch (keycode) {
        CK_EMAIL_TOGGLE => {
            const addr = if (email_state) "personal@example.com" else "work@example.com";
            c.send_string_with_delay(addr.ptr, 0);
            email_state = !email_state;
            return false;
        },
        else => return true,
    }
}
```

### `process_record_user` collision

**Critical**: there can only be one `process_record_user` in the entire
firmware. The generator (Tier 1) defines `process_record_user` to dispatch
macros and key overrides. **Tier 2 code that wants this hook MUST be
named `process_record_user_overlay` instead**, not `process_record_user`.
The generated `process_record_user` calls `process_record_user_overlay`
after handling its own dispatches.

```zig
// CORRECT — overlay hook name, gets called automatically
export fn process_record_user_overlay(keycode: u16, record: *c.keyrecord_t) bool { ... }

// WRONG — duplicate symbol with the generated function, link will fail
// export fn process_record_user(keycode: u16, record: *c.keyrecord_t) bool { ... }
```

The lint rule `process-record-user-collision` catches this and tells the
user to rename. The same applies to `matrix_scan_user`,
`keyboard_post_init_user`, and `housekeeping_task_user` — use the
`_overlay` suffix.

---

## Tap dance (Tier 2)

### When to use

A single key behaves differently on single tap, double tap, hold, etc.

### Tier 2 form

`overlay/tap_dance.zig`:

```zig
const c = @cImport({
    @cInclude("quantum.h");
});

// QMK's tap_dance_actions[] in idiomatic Zig
const TD_LSFT_CAPS: u8 = 0;

const tap_dance_actions = [_]c.tap_dance_action_t{
    [TD_LSFT_CAPS] = c.ACTION_TAP_DANCE_DOUBLE(c.KC_LSFT, c.KC_CAPS),
    // ... more
};

// Export the array under the symbol QMK expects
export const tap_dance_actions_count: usize = tap_dance_actions.len;
```

Plus enable in `features.toml`:

```toml
[features]
tap_dance = true
```

(For very simple tap dances — single tap = X, double tap = Y — Tier 1 is
sufficient via a future `[[tap_dances]]` block.)

---

## Hooks (init, suspend, wake) — Tier 2

### When to use

Run code on boot, suspend, wake, or layer change.

### Tier 2 form

```zig
const c = @cImport({
    @cInclude("quantum.h");
});

export fn keyboard_post_init_user_overlay() void {
    // Runs once when the keyboard finishes booting.
    // Use this for one-time setup: set initial RGB, log a marker, etc.
}

export fn suspend_power_down_user_overlay() void {
    // Runs when the host suspends.
}

export fn suspend_wakeup_init_user_overlay() void {
    // Runs when the host wakes up. E.g., force back to layer 0.
    c.layer_clear();
}

export fn layer_state_set_user_overlay(state: c.layer_state_t) c.layer_state_t {
    // Runs whenever the active layer changes.
    return state;
}
```

Note the `_overlay` suffix on every hook — see the
"`process_record_user` collision" section above for why.

---

## Vendoring upstream C (Tier 2′)

### When to use

You found a C library on GitHub (e.g., a custom QMK feature from
drashna's modules) and want to drop it in unmodified.

### How

1. Copy the `.c` and `.h` files into `overlay/`
2. The build picks them up automatically (`SRC += <filename>` is
   generated for every `.c` file in `overlay/`)
3. If the library needs a feature flag, add it to `[features]` in
   `features.toml`
4. If the library exposes hooks via `process_record_user` etc., follow
   the same `_overlay` suffix discipline (you may need to lightly modify
   the upstream code to rename — that's the one acceptable edit)

### Caveats

- Tier 2′ exists only because not everything in the QMK ecosystem has a
  Zig equivalent. **For new code you write, use Zig (Tier 2).** C is for
  paste-only.
- Multiple vendored libraries that all define `process_record_user` will
  collide. You'll need to combine them into one dispatcher — at that
  point you've effectively forked the library, which is fine.

---

## How to write a new recipe

When the user asks for a feature not in this cookbook:

1. Check if QMK supports it natively (it almost always does)
2. Find the upstream QMK docs for the feature
3. Decide tier:
   - **Pure config?** → Tier 1, propose a `features.toml` schema addition
     to the maintainers
   - **Procedural?** → Tier 2, write a small Zig file
   - **Vendored upstream?** → Tier 2′, paste the `.c` files
4. Test build, lint, diff, then update this cookbook so the next user
   gets it for free
