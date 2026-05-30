# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

GT-IconScaler is a pure-Bash icon generator (no Node/Python). It takes one source image and produces 38 sizes across 8 platforms (Linux hicolor, PWA, Android mipmap, iOS, watchOS, Windows tiles, Electron, macOS `.icns`, plus a Windows `.ico` and favicon). Two entry points share the same library:

- `GT-IconScaler.sh` — interactive CLI (uses `zenity`/`kdialog`/`yad` for file pickers; falls back to `read`)
- `GT-IconScaler-GUI.sh` — Zenity-only GUI wrapping the same engine in a progress dialog

Both are bilingual (Arabic / English) and depend only on ImageMagick at runtime.

## Common commands

```bash
# Run without installing
./GT-IconScaler.sh                 # CLI, auto-detect language
./GT-IconScaler.sh --lang=en       # force language
GT_LANG=ar ./GT-IconScaler.sh      # language via env
./GT-IconScaler-GUI.sh             # Zenity GUI

# Install / uninstall (interactive by default — asks which version)
./install.sh                       # per-user (~/.local), prompts CLI/GUI/both
./install.sh --cli -y              # CLI only, no prompts
./install.sh --gui -y              # Zenity GUI only, no prompts
./install.sh --all -y              # both, no prompts (default when -y)
sudo ./install.sh --all -y         # system (/usr/local), both
./uninstall.sh                     # per-user removal
sudo ./uninstall.sh                # system removal

# One-line install from anywhere (auto-bootstraps if files missing)
bash <(curl -sSL https://raw.githubusercontent.com/SalehGNUTUX/GT-IconScaler/main/install.sh)
bash <(curl -sSL .../install.sh) --cli -y   # flags pass through

# Rebuild compiled i18n after editing i18n/{ar,en}.json
./i18n/build-bash.sh               # requires `jq` (build-time only)
```

### Batch / non-interactive mode (CLI only)

`GT-IconScaler.sh` accepts batch flags that skip the matching interactive step. Any omitted flag falls back to its prompt — the modes are hybrid by design.

```bash
gt-iconscaler \
  --icon=/path/logo.png \
  --output=/path/dist \
  --name=myapp-icons \
  --platforms=all|linux-pwa|linux-pwa-android|linux-electron|mobile|windows \
  --compress=zip|targz|both|none \
  [--json]                         # single-line JSON summary on stdout, decoration muted
```

With `--json` stdout emits exactly one line:
```json
{"final_dir":"...","done":38,"failed":0,"has_ico":true,"has_icns":true,"icns_method":"imagemagick","compress":"both","archives":["...zip","...tar.gz"]}
```
Warnings/errors go to stderr (prefixed `WARN:` / `ERROR:`). Invalid `--platforms` or `--compress` exits 2; missing `--icon` path exits 1. The Electron GUI (3.2) will spawn this mode.

The Zenity GUI (`GT-IconScaler-GUI.sh`) does not accept batch flags — it stays purely interactive and is preserved as the lightweight option alongside the planned Electron GUI.

There is no test suite, lint config, or CI workflow in this repo.

## Architecture

### Two-phase generation

`lib/gt-iconscaler-core.sh` exposes the engine. Generation is always two phases:

1. **`gt_generate_all`** — for every size in `GT_ALL_SIZES` (38 entries), render `all/${size}x${size}/${basename}.png` once. Sets `GT_DONE_COUNT` / `GT_FAIL_COUNT`. Takes an optional progress callback name invoked as `cb <size> ok|fail`.
2. **`gt_distribute`** — copy from `all/` into platform subfolders, filtered by the enabled-platform list. Per-size routing lives in `gt_platform_dirs()` (case branches per size → list of relative dirs) and per-platform naming in `gt_target_filename()` (e.g. `ic_launcher.png` for Android, `Square150x150Logo.png` for Windows, `Icon-167.png` for iOS).

To add a platform: extend both `gt_platform_dirs` (which sizes map to which dirs) **and** `gt_target_filename` (how files are named there), then add it to `gt_resolve_platforms` if you want a preset.

### Format-specific outputs

`lib/gt-iconscaler-formats.sh` builds derived artifacts after `all/` exists:
- `gt_build_ico` — multi-size `.ico` via ImageMagick (sizes 16/24/32/48/64/128/256).
- `gt_build_icns` — tries `iconutil` (macOS-native, full Apple iconset map), then `png2icns` (Linux icnsutils), then ImageMagick as a degraded fallback. Sets `GT_ICNS_METHOD` so the caller can report which path was taken.
- `gt_build_favicon` — `favicon/` with 16/32/48 PNGs plus a copy of the `.ico`.
- `gt_compress_package` — `zip` / `tar.gz` / both / none, run from inside the export dir.

### ImageMagick abstraction

Never call `convert`/`magick` directly. Use `gt_im_cmd` (returns `magick` for IM7, `convert` for IM6, fails if neither). Same pattern for `identify` via `gt_identify_cmd`. This is how the tool stays compatible with both ImageMagick generations.

### Library discovery (lib/ lookup)

Both entry scripts resolve `LIB_DIR` in this order:
1. `<script dir>/lib` (running from a clone)
2. `$HOME/.local/share/gt-iconscaler/lib`
3. `/usr/local/share/gt-iconscaler/lib`
4. `/usr/share/gt-iconscaler/lib`

`install.sh` copies scripts to `bin/` and libraries to `share/gt-iconscaler/lib/` so the installed launchers find the libs via step 2 or 3. If you add a new file to `lib/`, update **both** `REQUIRED_FILES` and `install_libs` in `install.sh` and the corresponding cleanup in `uninstall.sh`.

### i18n: JSON → compiled Bash

Source of truth: `i18n/ar.json` and `i18n/en.json`. These are compiled at dev time by `i18n/build-bash.sh` (which requires `jq`) into `lib/i18n-ar.sh` / `lib/i18n-en.sh`, each a series of `T[key]=value` assignments using `jq -r '... | @sh'` for safe shell quoting. The compiled files are committed so `jq` is **not** a runtime dependency.

Workflow when adding/changing a string:
1. Add the same key to **both** `ar.json` and `en.json`.
2. Run `./i18n/build-bash.sh`.
3. Commit the regenerated `lib/i18n-*.sh` alongside the JSON change.

Language detection priority (see `gt_i18n_detect` in `lib/gt-iconscaler-i18n.sh`): explicit `--lang=` → `$GT_LANG` → `$LANG` (anything starting `ar_` becomes `ar`) → `en`. Unknown languages fall back to `en` silently.

Use `t key [printf args...]` to print a translated line; `tn key` for the no-newline variant. Missing keys print the key itself (visible fallback). `gt_i18n_dir` returns `rtl`/`ltr` (the GUI doesn't currently use it but it's there).

### Engine vs UI separation

`lib/gt-iconscaler-core.sh` and `lib/gt-iconscaler-formats.sh` **must not print user-facing text**. The header comment in core.sh is explicit about this: callers decide messages via `t`. Keep this boundary — it's what makes the same library drive both the CLI and the Zenity GUI (and a future Electron GUI) without duplicated strings.

The core lib also **must not depend on the caller's `IFS`**. Entry scripts set `IFS=$'\n\t'`, which breaks unquoted word-splitting on spaces. Functions that split space-delimited strings (e.g. `gt_distribute` iterating over `enabled_platforms`) must declare `local IFS=$' \t\n'` first. If you add a helper that loops `for x in $var` on a space-separated string, do the same.

### Desktop integration

`gt-iconscaler-cli.desktop` and `gt-iconscaler-gui.desktop` ship in the repo with placeholder `Exec=` lines. `install.sh` `sed`-rewrites `Exec=` and `TryExec=` to point at the resolved `BIN_DIR` (so the same `.desktop` works for user and system installs). Icons come from `GT-IconScaler-{CLI,GUI}-ICON-icons/all/${size}x${size}/...` and are installed into 10 hicolor sizes.

**CLI launcher wrapper.** The CLI `.desktop` does **not** use `Terminal=true` directly — that fails silently on KDE/GNOME minimal installs when no default terminal is configured. Instead, `install.sh::install_cli_launcher()` generates `$BIN_DIR/gt-iconscaler-cli-launcher` (a bash wrapper auto-written at install time, not stored in the repo) that:
1. Honors `$TERMINAL` env var if set.
2. Tries `xdg-terminal-exec` (freedesktop spec) if installed.
3. Picks a terminal matching `XDG_CURRENT_DESKTOP` (konsole for KDE, gnome-terminal for GNOME, etc.).
4. Falls back through 14 emulators: konsole, gnome-terminal, xfce4-terminal, mate-terminal, lxterminal, qterminal, deepin-terminal, io.elementary.terminal, tilix, alacritty, kitty, terminator, foot, x-terminal-emulator, xterm.
5. Runs `gt-iconscaler` inside a temp helper script with a "press any key" pause at the end (so users see the summary before the window closes).

CLI `.desktop` becomes `Exec=$BIN_DIR/gt-iconscaler-cli-launcher` with `Terminal=false`. If you add a new terminal emulator, extend the `FALLBACK=()` array in `install_cli_launcher`.

### Installer architecture

`install.sh` is self-contained and supports three deployment paths:

1. **Local clone**: `./install.sh [flags]` — reads files from `$SCRIPT_DIR`.
2. **`curl | bash` bootstrap**: when the script is fetched from raw GitHub and all `REQUIRED_FILES` are missing, `bootstrap_from_remote()` git-clones the repo into a temp dir and `exec`s itself from there. `ORIG_ARGS` is forwarded so user flags survive the bootstrap.
3. **System install** (`sudo`): `setup_install_paths()` switches paths to `/usr/local/bin`, `/usr/share/icons/hicolor`, `/usr/share/applications`, `/usr/local/share/gt-iconscaler` when `$EUID == 0`.

Flags: `--cli`, `--gui`, `--all` (default), `-y/--yes` (non-interactive), `-h/--help`. Without a `--cli/--gui/--all` flag, `choose_components()` prompts interactively if stdin is a tty; otherwise defaults to both.

Dependencies are dynamic per selection (`build_deps_list`): CLI alone needs only ImageMagick (zenity is optional — script has kdialog/yad/read fallback), GUI/both need ImageMagick + zenity. Package manager auto-detect supports apt, dnf, pacman, zypper, **apk** (Alpine), with per-PM package names (`ImageMagick` on dnf/zypper vs `imagemagick` elsewhere).

Each `install_*` function gates on `INSTALL_CLI` / `INSTALL_GUI` flags. `print_summary()` shows only installed commands.

## Conventions

- All shell scripts use `set -euo pipefail`. Entry scripts also set `IFS=$'\n\t'`. Preserve both.
- `VERSION` is hardcoded as a string in each entry script (currently `2.2.0`). When bumping, update **four** places: `GT-IconScaler.sh`, `GT-IconScaler-GUI.sh`, `banner.title` in both `i18n/{ar,en}.json` (then rebuild), and the `Installer vX.Y.Z` line in `install.sh::main()`.
- The README is Arabic-first; both languages are first-class in i18n. Don't assume English-only.
