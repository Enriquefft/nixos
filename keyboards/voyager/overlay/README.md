# overlay/

Everything in this directory is **your** code. oryx-bench merges it with
the visual layout (from Oryx or layout.toml) to produce the firmware.

- `features.toml` — Tier 1, declarative QMK features
- `*.zig`         — Tier 2, procedural code (state machines, animations)
- `*.c`           — Tier 2′, vendored upstream C libraries (paste-only)

See ARCHITECTURE.md for the four-tier model.
