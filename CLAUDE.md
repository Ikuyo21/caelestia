# Caelestia Redesign — Project Context for Claude Code

Fork of [caelestia-dots/shell](https://github.com/caelestia-dots/shell) (Quickshell/QML Hyprland desktop shell) plus a Neovim config, redesigned for performance, beauty, and simplicity. This is an **updated status document**, not the original plan — most of the spec below is already built and pushed. For full historical reasoning, check the Obsidian vault under **Caelestia Redesign** if connected in this environment.

## Current status (as of this update)
- **Canonical repo: private `Ikuyo21/caelestia`** on GitHub, 15+ commits. This is the one to work in.
- **A stale public repo, `Ikuyo21/dotfiles`, also exists** — an early interim push before the private repo was set up as canonical. It should be deleted manually (API can't delete it) and should NOT be worked in or treated as current.
- Nearly the entire spec is implemented: shell fork with nexus trim, weather removal, dashboard fusion, session menu redesign, caelestia-cli replacement, keybind migrations, terminal stack (fish/alacritty/fastfetch/starship), Neovim config (kickstart base, LSP, colorscheme, dashboard, statusline), and `setup.sh`.
- **A real run of `setup.sh` on the actual Arch machine surfaced genuine bugs** — see "Known issues" below. The repo-side fixes for all of them landed 2026-07-04; what remains is machine-side verification (rerun setup.sh, matugen end-to-end test, orphan cleanup, cold-start measurement).
- **2026-07-05 session: fonts unified + setup.sh hardened.** The shell plugin's mono default is now `JetBrainsMono Nerd Font` (was upstream's never-installed `CaskaydiaCove NF`; exact string verified from the Arch package's font name tables — group.lua's `JetBrains Mono NF` matched nothing and is fixed too). Two latent fresh-install bugs found and fixed: nothing put `~/.local/bin` on the session PATH (keybinds/`execDetached` calls to `caelestia*` would fail; fixed in `hypr/hyprland/env.lua`), and the plugin install step could never have worked unprivileged (now upstream's documented `-DCMAKE_INSTALL_PREFIX=/` + `sudo cmake --install` + chown of the home config dir). setup.sh rewritten: `--dry-run`, per-package AUR installs with an end-of-run failure report, foreign-symlink-aware timestamped backups, chsh prompt, NetworkManager conflict detection, scheme.json re-run guard. Verified via 6 mocked persona scenarios (fresh/ricer/idempotent/failure-recovery/dry-run) in a sandboxed Git Bash harness; the real-Arch rerun and a plugin rebuild (hpp string change) are still machine-side.

## Philosophy
Performance, beauty, simplicity — in that order when they conflict. Trim caelestia down to what earns its place, keep its visual identity, make it fast on Arch + Hyprland.

## Approach
**Hybrid**: fork upstream, delete unwanted modules/pages up front, rewrite kept modules module-by-module as they're touched. Nothing gets simplified without first checking real dependencies via grep across the codebase — this discipline caught several near-misses during discussion and should continue into any further work.

## Working practices
- **Use the full toolset available** — bash, file editing, git, actually running and testing things, not just reading and guessing.
- **Keep the Obsidian vault updated as you go**, under **Caelestia Redesign**: dated entries in Progress Log, real decisions in Decisions.md, checkboxes in Requirements flipped only when actually built.
- **Use targeted section edits in Obsidian, never a full-file overwrite tool** — this destroyed an entire document once already during discussion. Don't repeat it.
- **Verify against the real world before trusting a plan, including this one.** Several items below were only caught by actually running things (a real `setup.sh` execution, diffing files byte-for-byte, checking live AUR listings) — reading documentation or a prior plan is not the same as confirming it works.

---

## Known issues — status after the 2026-07-04 fix session

Items 1–4 and 7 are resolved in the repo (verify on the next real Arch run); 5 and 6 still need the machine.

### 1. `darkly-bin` — RESOLVED: dropped from setup.sh
Decision made per the philosophy: it's a QWidgets-only theme engine (this shell is pure QML/Quickshell), it failed to build anyway, and it dragged in **33 packages / 68.85 MiB** of KDE Frameworks. The live AUR metadata confirmed its dependency list spans *both* the KF6 and legacy KF5 stacks (`frameworkintegration5`, `kirigami2`, `libplasma`, …) — even a fixed build would keep that cost. Not worth it for cosmetics.
**Machine-side cleanup still needed once:** the KDE packages from the failed install are now orphans. Run `pacman -Qtdq` to list orphans, review the list (unrelated orphans may appear too), then `sudo pacman -Rns $(pacman -Qtdq)` and repeat until empty.

### 2. `ttf-rubik` — RESOLVED: replaced with a direct google/fonts install
Root cause confirmed from the live PKGBUILD: the package is abandoned (last modified May 2021, 1 vote, popularity 0) and its source is `https://fonts.google.com/download?family=Rubik` — an endpoint whose zip layout Google changed years ago, so `cp src/Rubik-*` can never succeed. Not fixable on our side, not worth waiting for. `setup.sh` now downloads `Rubik[wght].ttf` + `Rubik-Italic[wght].ttf` directly from the google/fonts GitHub repo into `~/.local/share/fonts/rubik/` and runs `fc-cache` (URLs verified live, idempotent check on both files).
Note for AUR checks in general: the AUR web UI *and* its RPC are behind an Anubis bot-check that blocks WebFetch-style tools — plain `curl` against `https://aur.archlinux.org/rpc/v5/...` and cgit `/plain/PKGBUILD` URLs works fine.

### 3. material-symbols conflict — RESOLVED in setup.sh
Investigation result: the non-git `ttf-material-symbols-variable` **no longer exists in the AUR at all** — the installed copy is an unmaintainable leftover (most likely from the original upstream caelestia install; it is not a dependency of papirus-icon-theme). The `-git` package declares `Provides=ttf-material-symbols-variable`, so removing the old one cannot break a dependency. `setup.sh` now removes it with `pacman -Rdd` before any install, so the conflict can no longer kill the whole transaction. **Gotcha caught by the first real-Arch run of the hardened script:** `pacman -Q <name>` resolves `Provides=` (query.c falls back to `alpm_find_satisfier`), so once the `-git` variant is installed, `-Q` on the old name matches it — while `-R` takes only literal names ("target not found"). The guard therefore compares `pacman -Qq`'s *resolved* output against the literal old name, and the removal itself is non-fatal (warns instead of aborting the bootstrap).

### 4. `fastfetch/logo.txt` transcription errors — RESOLVED and re-verified
Fixed in commit f8f7285 (wholesale programmatic replacement from the vault, no retyping). Re-verified this session byte-for-byte against the vault's Ascii Art note on disk: logo identical (47 lines, 13,160 bytes, no CR bytes, trailing newline present). The nvim dashboard dragon header was byte-verified the same way — also identical. No transcription drift remains anywhere.

### 5. matugen template keywords — STILL OPEN, machine-side
Cross-checked the template's role names (`surface_container_high`, `outline_variant`, `surface_tint`, etc.) against matugen's real documentation — they check out on paper, more solid than originally feared. But this was never actually run end-to-end (a sandbox attempt to test it hit an unrelated toolchain issue). **Run `matugen color hex "#29D3F0" -v` as the very first test on the real machine, before testing anything downstream of it.** One known matugen quirk found: `.default` always resolves to the dark-mode color regardless of the `-m` flag (a confirmed upstream matugen issue) — shouldn't matter here since nothing in this project needs real light-mode switching, but worth knowing if that's ever revisited.

### 6. Baseline performance numbers — real numbers in hand; cold start STILL OPEN, machine-side
Measured on the actual machine, unmodified upstream caelestia, idle: **CPU 12%, RAM 35%, GPU 54%** (via System Monitor/fastfetch; GPU wasn't one of the original three tracked metrics but is now measured, worth keeping). Real targets for the trimmed shell: **CPU <=8.4%, RAM <=22.75%**. Cold start time (launch -> first frame) still hasn't been measured -- needs a separate timed test. Use the same measurement tool for both baseline and trimmed-shell numbers to keep the comparison fair.

### 7. Smaller items — all RESOLVED
- **Starship theming — resolved by design, no template needed.** `starship.toml` uses only named ANSI colors (verified: zero hardcoded hex), and `matugen/templates/alacritty.toml` themes all 16 ANSI slots from M3 roles — so starship already follows both dynamic and pick-your-own modes transitively through the terminal palette (this matches what the vault Progress Log recorded at build time). A dedicated matugen template would add nothing: starship.toml has no import mechanism, so it would mean templating the entire file for zero visual difference. Decision recorded in the vault.
- **qmllint via nvim-lint — now actually wired** (`nvim/lua/caelestia/lint.lua`, loaded from init.lua section 10; it was NOT wired before this session despite being decided). Mirrors upstream's own CI lint job: `-I` args parsed from the Quickshell-generated `.qmlls.ini`, `--import disable`, scoped to the qml filetype only. Parse-checked; needs a runtime smoke test on Arch.
- **lualine — verified genuinely themed**, not just installed: `statusline.lua` builds a custom theme table from the caelestia palette (single-accent mode block, semantic diagnostic colors), no default rainbow.
- clangd vs ccls was revisited and re-confirmed: **keep clangd.** ccls also depends on libclang, so it wouldn't reduce the LLVM footprint at all, just trade to a less-maintained tool for no benefit. Don't relitigate this without new information.

---

## Repo structure
Single repo, config identifier stays **`caelestia`** throughout — `qs -c caelestia`, `~/.config/quickshell/caelestia`, every IPC call in keybinds.

```
shell/        # the caelestia-shell fork (QML + native plugin)
nvim/         # Neovim config (kickstart.nvim base)
hypr/         # Hyprland config, keybinds
fish/         # fish shell config
alacritty/    # terminal config
fastfetch/    # fastfetch config + custom logo
matugen/      # theming templates
setup.sh      # bootstrap script
```

The shell is built via CMake, not purely symlinked, mirroring upstream's documented install (the QML modules must land in `/usr/lib/qt6/qml` where quickshell looks, hence sudo + prefix `/`): `cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DVERSION=1.0.0 -DGIT_REVISION=$(git rev-parse --short HEAD) -DCMAKE_INSTALL_PREFIX=/ -DINSTALL_QSCONFDIR=~/.config/quickshell/caelestia && cmake --build build && sudo cmake --install build`, then chown the QSCONFDIR back to the user (sudo writes it as root). setup.sh does all of this.

---

## Shell (caelestia fork) — cut list (implemented, verified clean via direct repo check)

### Nexus — trimmed to appearance + panels only
**Verified**: only `WallpaperAndStyle.qml` and `PanelsPage.qml` (+ their subfolders) remain in `shell/modules/nexus/pages/`. Network/bluetooth/audio/updates/plugins/apps/services/language/about pages all removed. Deep-settings functionality deferred to system tools (`nm-connection-editor`/`iwctl`, `blueman`, `pavucontrol`).
**Do NOT delete these services** — verified still shared beyond nexus: `services/Nmcli.qml`, `services/VPN.qml`, Bluetooth (Quickshell built-in), `services/Audio.qml`.

### Weather — verified completely gone
Zero matches anywhere in the shell for weather-related files or references, including the underlying `services/Weather.qml` itself.

### Dashboard — verified fused into one view, no tabs
`Tabs.qml` and tab navigation confirmed removed from `Content.qml`. Kept: User card, DateTime, compact Media widget (cover art + controls, no lyrics), Performance cards simplified to plain bars + text instead of circular gauges/shape-morphing.

### Lock screen
Weather and media widgets cut, Center/NotifDock/LockSurface kept.

### Power/session menu
Redesigned to a text-list style (bracket header, vertical labeled list, highlight bar), decorative GIF dropped, still triggered by the single existing bar power icon.

### caelestia-cli — replaced
`bin/caelestia` wrapper script confirmed built and correctly implements both dynamic (wallpaper) and pick-your-own (seed color) modes via matugen.

### Special workspaces — verified fully removed
All 5 toggles gone, along with every window rule that pinned an app to one (`btop`->sysmon, music apps->music, Discord-family apps->communication, Todoist->todo). Zero `special:` references confirmed left in the hypr config.

---

## Theming architecture — two modes, one pipeline
Both modes go through matugen, difference is only the seed input:
- **Dynamic**: `matugen image <wallpaper>`
- **Pick your own**: `matugen color <hex>`

`#29D3F0` (electric cyan) is the default seed, not a hardcoded fallback. The color picker UI (`ColourSelect.qml`) was built from scratch — it was an unfinished upstream stub, nothing to extend.

**Fixed/manual palette values:**
- Background: `#16171b`, Text: `#E8E8EA` / `#9A9AA0` secondary, Accent: `#29D3F0`

**Sliders — verified they bind to real existing properties:**
- Roundness -> `Tokens.rounding.scale` only. Transparency -> `AppearanceConfig.transparency`. Blur -> Hyprland's `decoration:blur:size`/`passes` via `HyprExtras`. All three live in the nexus "Wallpaper & style" page.
- Terminal (Alacritty) blur/transparency via Hyprland windowrule on window class `Alacritty` — exact behavior (windowrule alone vs. also touching Alacritty's own opacity) still needs empirical confirmation.
- matugen also themes Alacritty's actual colors (confirmed working via the repo's `matugen/templates/alacritty.toml`).

---

## Neovim
Base: kickstart.nvim (uses Neovim's own built-in `vim.pack`, not `lazy.nvim` — verify this is still current, kickstart evolves). Scope: C/C++/QML only.

**LSP:** `clangd` for C/C++ (confirmed correct choice, do not swap to ccls — see Known Issues #7). `qml-language-server` (cushycush/Go-based, the `-bin` AUR variant) for QML — preferred over Qt's own `qmlls`, which can't resolve Quickshell-specific types. Treesitter grammar is `qmljs`, not `qml`. Empty `.qmlls.ini` next to `shell.qml`, gitignored.

**Colorscheme** — ties into the dynamic/pick-your-own toggle via matugen's M3 roles:

| Syntax role | Fixed hex | Dynamic matugen role |
|---|---|---|
| Background | `#16171b` | `background` |
| Default text | `#E8E8EA` | `on_background` |
| Keywords | `#29D3F0` | `primary` |
| Strings | `#6FA8B5` | `secondary` |
| Numbers | `#c9a86a` | `tertiary` |
| Comments | `#6a6d73`, italic | `outline_variant` |
| Types | `#f2f2f3` | `on_surface` |
| Errors/warnings/git | semantic red/amber/green, unconditional | same |

**Dashboard**: `snacks.nvim`, dashboard module only. `header` = the custom dragon ASCII art (verify this one was copied correctly too, given the fastfetch logo had transcription errors — don't assume this one is fine just because it wasn't explicitly flagged).

**Enabled**: `neo-tree` (file explorer), DAP (debugger — C++ side standard via `codelldb`, QML side unverified/less mature, don't assume it works). `nvim-lint` scoped specifically to `qmllint` for QML (see Known Issues #7).
**Not enabled**: indentation guides, autopairs, general extra linters.

**Statusline**: `lualine.nvim`, themed to the established palette (not lualine's default rainbow mode-colors) — verified actually themed (custom theme table from the caelestia palette in `statusline.lua`).

---

## Terminal (Alacritty)
Font: `ttf-jetbrains-mono-nerd` (confirmed correct over the shell README's `caskaydia-cove-nerd`). The exact family string everywhere (alacritty.toml, the shell plugin's mono default, hypr group.lua) is **`JetBrainsMono Nerd Font`** — verified from the package's actual font name tables; do not "correct" it to `JetBrains Mono NF`, which matches nothing. fastfetch wired into `~/.config/fish/config.fish` guarded by `status is-interactive`. Starship added but needs theming confirmed (Known Issues #7).

---

## Keybinds (`hypr/hyprland/keybinds.lua`, `variables.lua`, `rules.lua`)
Pattern: follow end-4/dots-hyprland's key choices and patterns where equivalent functionality exists — not a literal file copy, adapted to caelestia's actual IPC targets.

**Verified already matching end-4 almost everywhere** — `CTRL+ALT+Delete` (session), `SUPER+L` (lock), `SUPER+SHIFT+L` (sleep), scroll-wheel/Page_Up/Down workspace nav, window pin, fullscreen/maximize, keyboard resize (covers split-ratio) were all already present in caelestia before any changes. Don't "fix" gaps that don't actually exist.

**Migrated off caelestia-cli:**
- `caelestia shell -d` -> `qs -c caelestia -d`
- `Print` screenshot -> same native global-shortcut path as the other screenshot binds
- Special workspaces — dropped entirely, not migrated (see cut list above)
- Recording simplified to 2 modes (fullscreen + region-select) via `wf-recorder` + `slurp`
- Clipboard/emoji via `fuzzel` + `cliphist`, plus a curated `data/emoji.txt` (233 entries) piped into fuzzel for the emoji picker — confirmed built and working (`bin/caelestia-emoji`)

**Cheatsheet**: static `README.md`/`KEYBINDS.md` in the repo, not a live in-app feature.

---

## setup.sh
Full bootstrap: preflight (Arch/pacman/sudo/network checks, runs from anywhere, never as root) -> AUR helper (`yay`) -> packages (repo missing set in one pacman batch; AUR packages **one at a time** so a single failed build can't cascade, failures collected and reported at exit with code 1) -> Rubik from google/fonts -> build + sudo-install the Quickshell plugin -> backup & symlink (timestamped per run, never overwrites older backups, catches foreign symlinks, prints a summary of everything it moved) -> default shell (asks first on a tty, skips with instructions otherwise, no-op if already fish) -> services (NetworkManager only if no other network stack is enabled; bluetooth; ydotool user unit) -> first-run bootstrap (initial scheme guarded by an existing `scheme.json` so re-runs never reset picked colours; headless Neovim run for mason) -> summary. `--dry-run` previews every action (built for the "existing dotfiles" persona); `--help` documents it. Idempotent: a second run changes nothing and says so.

**Known Issues #1-3 are now fixed in the script** (darkly-bin dropped, Rubik vendored from google/fonts, material-symbols conflict pre-removed before any install) and the 2026-07-05 hardening pass was verified with 6 mocked persona scenarios (fresh Arch, existing ricer, idempotent re-runs, failure recovery, dry-runs) — still needs one real end-to-end run on the machine to confirm, plus the one-time KDE-orphan cleanup from issue #1.

---

## Animation (`hypr/hyprland/animations.lua`)
Durations reduced ~30-40% from upstream (confirmed applied correctly on the real repo, including correctly dropping the now-meaningless `specialWorkspace` animation leaf once special workspaces were removed entirely). Same curves/styles as upstream, just faster.

---

## Things intentionally NOT done — don't scope-creep these back in
- None of end-4's 8 bonus features (OCR, Lens-search, translation, AI summary, on-screen keyboard, light/dark toggle, cursor zoom, VM submap).
- No standalone in-shell file explorer — Thunar covers this at the OS level.
- Bar itself (workspaces, clock, tray, status icons, power button + popouts) — stays exactly as upstream, no cuts requested.
- Numpad workspace bindings, a direct poweroff quick-bind — explicitly declined.
- Nothing from caelestia's optional components (spotify/spicetify, other editors, discord, todoist, uwsm, zen browser, Firefox theme) unless explicitly asked for.
