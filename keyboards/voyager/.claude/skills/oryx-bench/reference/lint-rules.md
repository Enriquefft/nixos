# Lint rules

> **This file is GENERATED at build time** by the `xtask` binary from the
> registered rules in `src/lint/rules/`. Do not edit by hand — run
> `cargo xtask gen-skill-docs` to regenerate. CI verifies the file is
> up-to-date.

Each rule below has: ID, severity, what it catches, why it's bad, and the
recommended fix.

---

### `lt-on-high-freq`

**Severity**: Error (Warning in Oryx mode)

**Catches**: Layer-tap (`LT(layer, key)`) where `key` is one of `KC_BSPC`, `KC_SPC`, `KC_ENT`, `KC_DEL`, `KC_TAB`, or `KC_ESC`.

**Why bad**: Tap-hold resolves on a tapping term. Below it = tap; above = hold. For high-frequency keys you press hundreds of times an hour, the boundary is hit constantly: a fast Backspace burst crosses the term and triggers the layer; a brief intentional layer hold falls below the term and injects a stray Backspace.

**Recommended fix**: Almost never "move the key" — add achordion to `overlay/features.toml`. Achordion forces tap-hold to only resolve as hold when the next key is on the opposite hand. See `reference/overlay-cookbook.md#achordion`.

---

### `unreachable-layer`

**Severity**: Error

**Catches**: A layer with no `MO`, `LT`, `TG`, `TO`, `TT`, or `DF` reference from any reachable layer.

**Why bad**: A layer that can't be activated is dead code — it consumes firmware space and mental overhead.

**Recommended fix**: In Oryx (or `layout.toml`), either delete the unreachable layer or add an activation key (MO/LT/TG/TO/TT/DF) pointing at it from a layer that is already reachable.

---

### `kc-no-in-overlay`

**Severity**: Warning

**Catches**: A non-base layer position bound to `KC_NO` (dead key) when the base layer at the same position has a real binding. Almost always the user meant `KC_TRANSPARENT` (fall-through).

**Why bad**: `KC_NO` does nothing; `KC_TRANSPARENT` falls through to the next active layer. They look identical in Oryx's grid view but produce wildly different behavior.

**Recommended fix**: In Oryx (or `layout.toml`), open the affected layer and set the position to "Transparent" instead of "Empty".

---

### `orphaned-mod-tap`

**Severity**: Warning

**Catches**: A key with `tap: null` and `hold: <plain modifier>`. This is the encoding Oryx produces when you start with a mod-tap and clear the tap action.

**Why bad**: Functionally works as a plain modifier, but the encoding signals "this used to be a mod-tap" and creates code-review confusion.

**Recommended fix**: In Oryx (or `layout.toml`), remove the mod-tap and re-add the same position as a plain modifier.

---

### `unknown-keycode`

**Severity**: Warning

**Catches**: A `code` field in pulled JSON that doesn't match any catalogued QMK keycode.

**Why bad**: Either Oryx introduced a new code we haven't catalogued, or the JSON is corrupt. The generator emits the literal string into the generated `keymap.c`, which compiles if QMK knows the symbol but lint can't reason about it (high-frequency-key detection, vowel detection, etc.).

**Recommended fix**: File an issue with the unknown code name. We add it to `src/schema/keycode.rs` and ship a new release. As a workaround, the catch-all `Keycode::Other(String)` preserves the literal so manual intervention is possible.

---

### `unknown-layer-ref`

**Severity**: Error

**Catches**: A layer-affecting action (`MO`, `LT`, `TG`, etc.) whose `layer` field points to a nonexistent layer index.

**Why bad**: Build will fail (or, worse, silently activate the wrong layer if the index is technically valid in QMK's numbering).

**Recommended fix**: Fix the dangling reference by editing the visual layout in Oryx (or `layout.toml`). Either rebind the offending key to a layer that exists, or add the missing layer.

---

### `duplicate-action`

**Severity**: Info

**Catches**: Two positions on the same layer producing the same effect.

**Why bad**: Often intentional (e.g., Backspace bound on a thumb and duplicated in the symbol layer's row 2 so you can erase while holding the layer key). Flagged as info so you can review and accept.

**Recommended fix**: Review and accept, or remove the duplicate if unintended.

---

### `mod-tap-on-vowel`

**Severity**: Info

**Catches**: Home-row mod (`MT(MOD_*, KC_<vowel>)`) on a vowel position.

**Why bad**: Vowels appear in fast bigrams in many languages, which causes more mod-tap misfires than mods on consonants.

**Recommended fix**: Either accept (and add achordion to mitigate), or move the mod to a consonant position.

---

### `home-row-mods-asymmetric`

**Severity**: Info

**Catches**: Home-row mods on the left half but not the right (or vice versa).

**Why bad**: Asymmetric mods make muscle memory harder.

**Recommended fix**: Either accept the asymmetry, or mirror the stack by editing the visual layout in Oryx (or `layout.toml`) so both halves use the same mod order.

---

### `layer-name-collision`

**Severity**: Warning (Info in Oryx mode)

**Catches**: Two layers whose titles sanitize to the same C identifier. For example, `"Sym + Num"` and `"Sym Num"` both sanitize to `SYM_NUM`.

**Why bad**: Layer references in `layout.toml` (e.g. `LT(Layer, KC_ENT)`) use the original name. When two layers share a name, the reference is ambiguous — codegen can only resolve it to one of them. The generated C enum is auto-disambiguated (`LAYER_1`, `LAYER_2`), but the `layout.toml` name lookup silently picks one, and the other layer becomes unreferenceable by name.

**Recommended fix**: Rename the colliding layers in `layout.toml` to have distinct names (e.g. `Symbols`, `Nav`). In Oryx mode, rename them in the Oryx UI and re-pull.

---

### `overlay-dangling-position`

**Severity**: Error

**Catches**: `overlay/features.toml` references a position name (e.g., `L_pinky_home`) that doesn't exist in the current geometry, OR references a binding (`LT(SymNum, BSPC)`) where no key in the visual layout has that binding.

**Why bad**: The generator can't resolve the reference. Build will fail or (worse) silently apply the feature to nothing.

**Recommended fix**: Either fix the position/binding name in the TOML, or update Oryx to add the missing binding.

---

### `overlay-dangling-keycode`

**Severity**: Error

**Catches**: `overlay/features.toml` references a keycode (e.g., for a key override) that isn't bound anywhere in the visual layout.

**Why bad**: A key override on a key that doesn't exist on the keyboard is silently dead — the override never fires.

**Recommended fix**: Either bind the keycode in Oryx, or remove the override.

---

### `custom-keycode-undefined`

**Severity**: Error

**Catches**: The visual layout binds a `USERnn` keycode but no `[[macros]]` entry, `.zig`, or vendored `.c` file in `overlay/` defines what `USERnn` does.

**Why bad**: Pressing the key does nothing.

**Recommended fix**: Either add a `[[macros]]` entry in `features.toml` with `slot = "USERnn"`, or add a Tier 2 dispatch arm in an `overlay/*.zig` file, or remove the binding from the visual layout.

---

### `unreferenced-custom-keycode`

**Severity**: Info

**Catches**: An overlay defines a custom keycode (`[[macros]]` with a `slot` or a `.zig` dispatch) but no layer in the visual layout binds that USERnn slot.

**Why bad**: Dead code.

**Recommended fix**: Either bind it in Oryx, or remove from `features.toml`.

---

### `process-record-user-collision`

**Severity**: Error

**Catches**: A Tier 2 file (`*.zig` or vendored `*.c`) defines `process_record_user` directly, colliding with the generator's auto-emitted `process_record_user`.

**Why bad**: The link step fails with a duplicate symbol error.

**Recommended fix**: Rename the Tier 2 function to `process_record_user_overlay`. The generated `process_record_user` dispatches to `_overlay` after handling its own concerns. Same applies to `matrix_scan_user`, `keyboard_post_init_user`, etc.

---

### `unbound-tapping-term`

**Severity**: Warning

**Catches**: `[[tapping_term_per_key]]` references a binding that doesn't exist anywhere in the visual layout.

**Why bad**: The `get_tapping_term` switch case will never fire because no key in the layout matches the binding. The override is dead code that takes flash space.

**Recommended fix**: Either bind the keycode in Oryx (or `layout.toml`), or remove the `[[tapping_term_per_key]]` entry.

---

### `unused-feature-flag`

**Severity**: Info

**Catches**: `features.toml` `[features]` enables a declarative flag whose corresponding section is empty.

**Why bad**: QMK compiles the feature into the firmware regardless of whether you use it. The result is a larger binary that wastes flash space — relevant on the Voyager which has only ~64KB. Either add entries to the section or set the flag to false.

**Recommended fix**: Either add an entry (e.g. `[[key_overrides]]` for `key_overrides = true`), or set the flag to `false`.

---

### `tt-too-short`

**Severity**: Warning

**Catches**: Effective `TAPPING_TERM` is strictly below the 150ms disambiguation minimum (after considering `features.toml [config]` overrides) when any mod-tap or layer-tap is in the layout.

**Why bad**: Below the minimum, the tap/hold boundary is too tight even for fast typists. Constant misfires.

**Recommended fix**: Set `tapping_term_ms` in `[config]` of `features.toml` to at least 180ms. 200–220ms is the sweet spot for most users.

---

### `not-pulled-recently`

**Severity**: Info

**Catches**: `pulled/revision.json` mtime is older than `[sync] warn_if_stale_s` (Oryx mode only — no-op in local mode).

**Why bad**: You may have edited in Oryx since the last pull. Local state could be stale.

**Recommended fix**: `oryx-bench pull`.

---

### `oryx-newer-than-build`

**Severity**: Warning

**Catches**: The current canonical layout + overlay differs from the inputs the most-recent build saw.

**Why bad**: You pulled fresh state from Oryx (or edited an overlay file), but the firmware on your keyboard is still based on the previous inputs. Flashing now would re-flash the stale firmware.

**Recommended fix**: `oryx-bench build` (and then `flash` after review).

---

### `large-firmware`

**Severity**: Info

**Catches**: The most-recent build produced a firmware image close to the target board's flash budget.

**Why bad**: The board has a fixed flash size; once you cross the budget the build fails to link. Approaching it gradually is fine, but you'll want to know which feature flag last pushed you over.

**Recommended fix**: Run `oryx-bench build --emit-overlay-c` and inspect the generated rules.mk for feature flags you don't use. Disable any feature you're not actually consuming. Avoid `MOUSEKEY_ENABLE` if you're not using mouse keys.

---

## How to add a rule

See `CONTRIBUTING.md`. Briefly:

1. Create `src/lint/rules/<rule_id>.rs` implementing `LintRule`
2. Register in `src/lint/rules/mod.rs::registry()`
3. Add positive + negative tests in `tests/lint_rules.rs`
4. Run `cargo xtask gen-skill-docs` — this file regenerates from the
   registry
5. CI verifies the committed file matches the generator output
