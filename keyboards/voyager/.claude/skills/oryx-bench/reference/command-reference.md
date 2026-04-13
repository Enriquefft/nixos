# Command reference

> **This file is GENERATED at build time** by the `xtask` binary from the
> clap CLI definitions in `src/cli.rs`. Do not edit by hand — run
> `cargo xtask gen-skill-docs` to regenerate. CI verifies the file is
> up-to-date.

---

## `oryx-bench`

```
Workbench for ZSA keyboard layouts — Oryx-friendly, not Oryx-required

Usage: oryx-bench [OPTIONS] <COMMAND>

Commands:
  setup          Detect toolchain (qmk, gcc-arm, zig, docker, wally-cli, keymapp). Idempotent
  init           Create a project skeleton
  attach         Switch a local-mode project to Oryx mode
  detach         Switch an Oryx-mode project to local mode. One-way
  pull           Manually fetch live state from Oryx. Usually unnecessary thanks to auto-pull
  show           Render a layer (or all) as an ASCII split-grid keyboard
  explain        Cross-layer view of a single position
  find           Search across all layers
  lint           Run static analysis
  status         One-screen overview of project, sync, and lint state
  build          Compile firmware via the bundled Docker image
  flash          Flash firmware to a connected keyboard
  skill          Install / remove the project-local Claude Code skill
  diff           Semantic diff vs git ref
  upgrade-check  Re-run lint with the current keycode catalog. Use after `cargo install --force
                 oryx-bench`
  help           Print this message or the help of the given subcommand(s)

Options:
      --project <PROJECT>
          Path to the project root (default: discover from cwd)

      --color <COLOR>
          Color mode
          
          [default: auto]
          [possible values: auto, always, never]

  -v, --verbose...
          Increase logging verbosity (repeatable)

  -h, --help
          Print help

  -V, --version
          Print version

```

---

## `oryx-bench attach`

Switch a local-mode project to Oryx mode

```
Switch a local-mode project to Oryx mode

Usage: attach [OPTIONS] --hash <HASH>

Options:
      --hash <HASH>
          The Oryx layout hash to attach to

      --force
          Skip the working-tree-clean safety check. Required when `layout.toml` has uncommitted
          changes OR when the directory isn't a git repo (so we can't tell whether your work is
          committed)

  -h, --help
          Print help

```

---

## `oryx-bench build`

Compile firmware via the bundled Docker image

```
Compile firmware via the bundled Docker image

Usage: build [OPTIONS]

Options:
      --dry-run
          Show what would be built; don't actually build

      --release
          Build with LTO, strip

      --emit-overlay-c
          Save the generated overlay C source for inspection

      --no-pull
          Skip auto-pull

  -h, --help
          Print help

```

---

## `oryx-bench detach`

Switch an Oryx-mode project to local mode. One-way

```
Switch an Oryx-mode project to local mode. One-way

Usage: detach [OPTIONS]

Options:
      --force
          Skip the confirmation prompt

  -h, --help
          Print help

```

---

## `oryx-bench diff`

Semantic diff vs git ref

```
Semantic diff vs git ref

Usage: diff [OPTIONS] [GIT_REF]

Arguments:
  [GIT_REF]
          Git reference to diff against (default: HEAD)

Options:
      --layer <LAYER>
          Limit visual layout diff to one layer (case-insensitive name)

  -h, --help
          Print help

```

---

## `oryx-bench explain`

Cross-layer view of a single position

```
Cross-layer view of a single position

Usage: explain <POSITION>

Arguments:
  <POSITION>
          Position name (e.g. R_thumb_outer, L_pinky_home)

Options:
  -h, --help
          Print help

```

---

## `oryx-bench find`

Search across all layers

```
Search across all layers

Usage: find <QUERY>

Arguments:
  <QUERY>
          Query string

Options:
  -h, --help
          Print help

```

---

## `oryx-bench flash`

Flash firmware to a connected keyboard

```
Flash firmware to a connected keyboard

Usage: flash [OPTIONS]

Options:
      --dry-run
          Print what would be flashed; don't flash

      --yes
          Skip the CLI's confirmation prompt. Still requires explicit conversational approval when
          used by an agent — this flag only bypasses the in-process `[y/N]` prompt

      --backend <BACKEND>
          Backend selection. `auto` (default) prefers wally-cli if installed and falls back to the
          Keymapp GUI handoff

          Possible values:
          - auto:    Prefer wally-cli if it's on PATH; otherwise fall back to keymapp
          - wally:   Force `wally-cli`. Errors if it isn't installed
          - keymapp: Force the Keymapp GUI handoff
          
          [default: auto]

      --force
          Flash even if the firmware on disk doesn't match the current canonical inputs (i.e.
          someone forgot to rebuild after a pull or overlay edit). Off by default; use only when you
          know what you're doing

  -h, --help
          Print help (see a summary with '-h')

```

---

## `oryx-bench init`

Create a project skeleton

```
Create a project skeleton

Usage: init [OPTIONS]

Options:
      --hash <HASH>
          The Oryx layout hash. Mutually exclusive with `--blank`

      --blank
          Use local mode (no Oryx hash)

      --geometry <GEOMETRY>
          Keyboard geometry (voyager in v0.1)
          
          [default: voyager]

      --name <NAME>
          Friendly project name (defaults to current dir basename)

      --no-skill
          Don't prompt to install the project-local Claude Code skill

      --force
          Overwrite existing files

  -h, --help
          Print help

```

---

## `oryx-bench lint`

Run static analysis

```
Run static analysis

Usage: lint [OPTIONS]

Options:
      --strict
          Fail on warnings as well as errors

      --rule <RULE>
          Run only this rule

      --format <FORMAT>
          Output format
          
          [default: text]
          [possible values: text, json]

      --no-pull
          Skip auto-pull

  -h, --help
          Print help

```

---

## `oryx-bench pull`

Manually fetch live state from Oryx. Usually unnecessary thanks to auto-pull

```
Manually fetch live state from Oryx. Usually unnecessary thanks to auto-pull

Usage: pull [OPTIONS]

Options:
      --revision <REVISION>
          Specific revision hash, or "latest" (defaults to kb.toml)

      --force
          Bypass the 60s metadata cache and the `auto_pull = never` setting

  -h, --help
          Print help

```

---

## `oryx-bench setup`

Detect toolchain (qmk, gcc-arm, zig, docker, wally-cli, keymapp). Idempotent

```
Detect toolchain (qmk, gcc-arm, zig, docker, wally-cli, keymapp). Idempotent

Usage: setup [OPTIONS]

Options:
  -f, --full
          Print each tool's `--version` output (or the equivalent flag), not just whether it was
          found on PATH. Useful when debugging version-mismatch issues with the docker build backend

  -h, --help
          Print help

```

---

## `oryx-bench show`

Render a layer (or all) as an ASCII split-grid keyboard

```
Render a layer (or all) as an ASCII split-grid keyboard

Usage: show [OPTIONS] [LAYER]

Arguments:
  [LAYER]
          Layer name (case-insensitive). Default: render all layers

Options:
      --names
          Show position names instead of keycodes

      --no-pull
          Skip the auto-pull check (read from local cache only)

  -h, --help
          Print help

```

---

## `oryx-bench skill`

Install / remove the project-local Claude Code skill

```
Install / remove the project-local Claude Code skill

Usage: skill <COMMAND>

Commands:
  install  Install the skill at `./.claude/skills/oryx-bench/` (or `~/.claude/...` with --global)
  remove   Remove the skill from the project (or global install with --global)
  help     Print this message or the help of the given subcommand(s)

Options:
  -h, --help
          Print help

```

---

## `oryx-bench status`

One-screen overview of project, sync, and lint state

```
One-screen overview of project, sync, and lint state

Usage: status [OPTIONS]

Options:
      --no-pull
          Skip the metadata query (useful offline)

  -h, --help
          Print help

```

---

## `oryx-bench upgrade-check`

Re-run lint with the current keycode catalog. Use after `cargo install --force oryx-bench`

```
Re-run lint with the current keycode catalog. Use after `cargo install --force oryx-bench`

Usage: upgrade-check

Options:
  -h, --help
          Print help

```

---

