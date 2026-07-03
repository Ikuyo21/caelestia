# Caelestia Redesign — Project Context for Claude Code

Fork of [caelestia-dots/shell](https://github.com/caelestia-dots/shell) (Quickshell/QML Hyprland desktop shell) plus a Neovim config, redesigned for performance, beauty, and simplicity. This file is the working spec. For the full reasoning behind any decision below, check the Obsidian vault under **Caelestia Redesign** (Overview / Requirements / Decisions / Architecture Audit / Progress Log) if it's connected in this environment — this file has the conclusions, the vault has the "why."

## Philosophy
Performance, beauty, simplicity — in that order when they conflict. Trim caelestia down to what earns its place, keep its visual identity, make it fast on Arch + Hyprland.

## Approach
**Hybrid**: fork upstream, delete unwanted modules/pages up front, rewrite kept modules module-by-module as they're touched — not a big-bang rewrite. Nothing gets "simplified" without first checking real dependencies via grep across the codebase (this caught several near-misses during discussion — e.g. cutting a service that turned out to still be used elsewhere).

## Working practices
- **Use the full toolset available** — bash, file editing, git, actually running and testing things on the machine, not just reading and guessing. The discussion phase's discipline (verify against real code before cutting/changing anything, don't assume) should carry into execution — check dependencies with grep before deleting, actually run the shell/nvim to confirm something works rather than assuming it compiles.
- **Keep the Obsidian vault updated as you go**, under **Caelestia Redesign**, same conventions already established there:
  - **Progress Log.md** — append a dated entry after any real chunk of work (what got built, what broke, what got deferred), same format as the existing entries.
  - **Decisions.md** — log any real decision made or deviation from this spec during execution (ADR-lite: Decision / Context / Owner), especially anything not explicitly covered above that required a judgment call.
  - **Requirements.md** — flip `[ ]` to `[x]` as items actually get implemented (not just planned) — it should reflect real build status, not just discussion-phase intent.
  - Use `vault_patch` (or the equivalent targeted-edit tool) for section edits, not a full-file overwrite tool — a full overwrite will destroy everything else in the file. This bit Claude (chat) once during discussion; don't repeat it.

## Environment
- Single physical machine, dual-boot Windows/Arch. Editing/planning can happen on Windows; **building the native C++ plugin and running/testing Hyprland+Quickshell requires being booted into Arch.**
- Self-discover hardware/monitor specifics at kickoff (`hyprctl monitors`, `lspci | grep VGA`, `free -h`) rather than relying on anything hardcoded here.
- AUR helper: `yay`.

## Performance targets
No reliable published benchmark exists for Quickshell/caelestia — don't invent absolute numbers. **Measure the unmodified upstream shell on the actual machine first**, then hit these reduction targets against that real baseline:
- Idle RSS memory: ≥35% lower
- Idle CPU%: ≥30% lower
- Cold start (launch → first frame): ≥25% faster

---

## Repo structure
Single repo, config identifier stays **`caelestia`** throughout (no rename) — `qs -c caelestia`, `~/.config/quickshell/caelestia`, every IPC call in keybinds stays as upstream uses it.

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

The shell isn't purely symlinked — it's **built via CMake**: `cmake -B build -DCMAKE_BUILD_TYPE=Release -DINSTALL_QSCONFDIR=~/.config/quickshell/caelestia && cmake --build build && cmake --install build`.

---

## Shell (caelestia fork) — cut list

### Nexus (control center) — trim to appearance + panels only
**Delete:**
- `modules/nexus/pages/network/EthernetDetailPage.qml`, `modules/nexus/common/EthernetSection.qml`, `modules/nexus/pages/NetworkPage.qml`
- `modules/nexus/pages/bluetooth/BtDeviceInfo.qml`, `modules/nexus/pages/bluetooth/BluetoothPairing.qml`, `modules/nexus/pages/BluetoothPage.qml`
- `modules/nexus/pages/audio/AppVolumes.qml`
- `modules/nexus/pages/apps/AllApps.qml`, `modules/nexus/pages/apps/AppInfo.qml`
- `modules/nexus/pages/LanguageAndRegion.qml`
- `modules/nexus/pages/ServicesPage.qml`
- `modules/nexus/pages/AboutPage.qml`
- Drop "Updates"/"Plugins" entries from `PageRegistry.qml` (no implementation files upstream, nothing to delete, just remove the registry entries)

**Keep:** `pages/WallpaperAndStyle.qml` + `pages/wallandstyle/`, `pages/PanelsPage.qml` + `pages/panels/`, `NavPane.qml`, `PageRegistry.qml` (trimmed), `Nexus.qml`, `NexusState.qml`, `PageCompRegistry.qml` (trimmed). Remove the now-dead `Weather` `ToggleRow` from `pages/panels/DashboardPanel.qml`.

**Do NOT delete these services** — verified still shared beyond nexus: `services/Nmcli.qml` (used by `bar/popouts/Network.qml`, `WirelessPassword.qml`, `bar/components/StatusIcons.qml`, `utilities/cards/Toggles.qml`), `services/VPN.qml` (Toggles.qml), Bluetooth (Quickshell built-in, used by `bar/popouts/Bluetooth.qml`), `services/Audio.qml` (bar/osd/dashboard).

Network/bluetooth/audio deep-settings functionality is deferred to system tools: `nm-connection-editor`/`iwctl`, `blueman`, `pavucontrol`.

### Weather — cut everywhere, including the service itself
**Delete:** `services/Weather.qml`, `modules/lock/WeatherInfo.qml`, `modules/lock/weather/BriefInfo.qml`, `modules/lock/weather/Forecast.qml`, `modules/dashboard/WeatherTab.qml`, `modules/dashboard/dash/SmallWeather.qml`.
**Edit (remove instantiations/references):** `modules/lock/Content.qml` (remove `WeatherInfo {}`), `modules/dashboard/Dash.qml` (remove `SmallWeather {}`), `modules/dashboard/Content.qml` (remove `Weather` from `dashboardTabs`), `utils/Icons.qml` (drop now-dead `weatherIcons`/`getWeatherIcon()`, low priority).

### Dashboard — fuse into one view, no tabs
Remove `Tabs.qml` and the tab-bar navigation in `Content.qml` (verified isolated, safe).

**Keep:** User card, DateTime, compact Media widget (`dash/Media.qml` — cover art + controls, no lyrics), Performance cards **simplified** (replace `CircularProgress` rings and the usage-`MaterialShape` morphing with plain linear bars + the "X / Y unit" text `UsageFmt.formatKib` etc. already compute).

**Cut:** `dash/Calendar.qml`, `dash/Resources.qml` (redundant once Performance cards are simplified), the full Media tab's lyrics/visualizer system — `modules/dashboard/media/BackgroundShapes.qml`, `CoverVisualiser.qml`, `Details.qml`, `LyricList.qml`, `LyricsAndSelector.qml`, `LyricsInfo.qml`, and the `modules/dashboard/Media.qml` tab wrapper (~1,100 lines total).

### Lock screen
**Cut:** `modules/lock/WeatherInfo.qml` + `weather/` (see Weather above), `modules/lock/Media.qml` (remove `Media {}` from `Content.qml` — underlying MPRIS service stays, used elsewhere).
**Keep:** Center (clock, profile pic, password), NotifDock/NotifGroup, LockSurface (the blob panel shape).

### Power/session menu — redesign
`modules/session/Content.qml` currently: 4 circular icon-only buttons (logout/shutdown/hibernate/reboot) + a decorative `AnimatedImage` GIF. **Redesign to a text-list style**: bracket-style header, vertical labeled list, highlight bar on the focused/hovered item, our theme colors. **Drop the decorative GIF.** Trigger stays exactly as-is — the single existing bar power icon (`modules/bar/components/Power.qml`), no other changes to how it's opened. OSD (`modules/osd/`) is explicitly untouched.

### caelestia-cli — fully cut, replaced by matugen
Two jobs it did:
1. Shell control convenience (`caelestia shell ...`) — **needs no replacement**, it was just a wrapper around native `IpcHandler`s already in the repo (`qs -c caelestia ipc call <target> <function>` works standalone).
2. Wallpaper switching + dynamic scheme generation — **hard dependency**, `services/Wallpapers.qml` shelled out to the `caelestia` binary directly, `Colours.qml` has no native generation of its own (it just watches `${Paths.state}/scheme.json` via `FileView`).

**Replacement**: [matugen](https://github.com/InioX/matugen) + a small wrapper script. Wrapper takes over what `Wallpapers.qml` called `caelestia wallpaper -f/-r/-p` for (setting wallpaper, writing `${Paths.state}/wallpaper/path.txt`, live preview). A matugen template renders straight to `${Paths.state}/scheme.json` matching `Colours.qml`'s existing schema — `Colours.qml` itself needs **zero changes**.

### Special workspaces — dropped entirely (keybinds/hypr, not shell QML)
All 5 toggles removed (`specialws`/`sysmon`/`music`/`communication`/`todo`) — see Keybinds section below.

---

## Theming architecture — two modes, one pipeline
Both modes go through matugen, difference is only the seed input:
- **Dynamic**: `matugen image <wallpaper>` — colors derived from wallpaper
- **Pick your own**: `matugen color <hex>` — colors derived from one user-picked seed color

Both produce identical downstream output, so shell/Neovim/Alacritty/starship colorscheme-reading code doesn't need to know which mode generated it. `#29D3F0` (electric cyan) is the **default seed**, not a hardcoded fallback — `matugen color 29D3F0` runs as part of first-run setup so there's always a generated file to read.

**The color picker UI needs to be built from scratch** — `modules/nexus/pages/wallandstyle/ColourSelect.qml` is an unfinished upstream stub ("Page under construction"), nothing to extend.

**Fixed/manual palette values** (used as the default seed and for any hardcoded reference):
- Background: `#16171b` (true dark neutral, not pure black)
- Text: `#E8E8EA` (primary), `#9A9AA0` (secondary/muted)
- Accent: `#29D3F0` (electric cyan)
- Elevation: Material 3 tonal system, no color tinting, pure neutral grays

**Corner rounding & blur/transparency — all bind to existing native properties, this is UI work not new architecture:**
- Roundness slider → `Tokens.rounding.scale` only (corner radius multiplier, already exists, already used in ~7+ places). `deformScale` (blob waviness) stays fixed, not exposed.
- Transparency slider → `AppearanceConfig.transparency.enabled`/`.base` (already wired into `Colours.qml`).
- Blur slider → Hyprland's `decoration:blur:size`/`passes`, via the existing `Hypr.extras.applyOptions()`/`HyprExtras` live-apply mechanism (already used for on/off in `GameMode.qml`).
- **All three sliders live in the nexus "Wallpaper & style" appearance page** (the page kept from the nexus trim above).
- Terminal blur/transparency: Alacritty has no native blur, comes entirely from a Hyprland windowrule on window class `Alacritty`. Live transparency also proposed via Hyprland windowrule-opacity (reusing the same `HyprExtras` mechanism) rather than editing `alacritty.toml` directly — **verify empirically once running**, exact behavior (windowrule alone vs. also touching Alacritty's own `window.opacity`) wasn't resolved in the abstract.
- **matugen also themes Alacritty's actual color palette** (not just blur/opacity) — same wallpaper/seed analysis drives both.

---

## Neovim
Base: **kickstart.nvim** — a single documented `init.lua`, meant to be trimmed, not LazyVim/NvChad. Uses Neovim's own built-in `vim.pack` package manager (not `lazy.nvim` — verify this is still current when building, kickstart evolves).

Scope: **C/C++/QML only** — this config is for working on this dotfiles project itself, not a general-purpose IDE. User is new to Neovim.

**LSP:**
- C/C++: `clangd`
- QML: `qml-language-server` (cushycush, Go-based, Quickshell-aware — go-to-definition, workspace indexing, Qt module discovery) — **preferred over** Qt's own `qmlls`, which per Qt's docs is still "in development" and can't resolve Quickshell-specific types like `PanelWindow`.
- Treesitter grammar for QML is `qmljs`, not `qml` — `:TSInstall qmljs`.
- Quickshell's own docs: create an empty `.qmlls.ini` next to `shell.qml`; Quickshell manages it automatically. Gitignore it (machine-specific).

**Colorscheme** — ties into the same dynamic/pick-your-own toggle as the shell, via matugen's Material Design 3 role output:
| Syntax role | Fixed-mode hex | Dynamic-mode matugen role |
|---|---|---|
| Background | `#16171b` | `background` |
| Default text | `#E8E8EA` | `on_background` |
| Keywords | `#29D3F0` | `primary` |
| Strings | `#6FA8B5` | `secondary` |
| Numbers | `#c9a86a` | `tertiary` (M3: hue-rotated 60° from primary — the *designed* answer, not an arbitrary deviation) |
| Comments | `#6a6d73`, italic | `outline_variant` |
| Component/type names | `#f2f2f3` | `on_surface` (bright tone) |
| Errors/warnings/git diff | semantic red/amber/green, unconditionally | same (verify whether matugen's own `error` role — red-family by M3 convention — can be used and still stay recognizable) |

Fallback: if the matugen-generated file doesn't exist yet, fall back to fixed-mode values (shouldn't actually happen given the first-run bootstrap, but don't let it hard-error).

**Dashboard**: `snacks.nvim`, dashboard module **only** (don't opt into its other bundled utilities — explorer/notifier/etc). `header` = the custom dragon ASCII art (delivered as a file during discussion, no "ZVIM"-style text logo). Menu: Find File (f), New File (n), Recent Files (r), Find Text (g), Config (c), Restore Session (s) — drop the "Lazy" entry since we use `vim.pack`.

**Toggle-on extras enabled**: `neo-tree` (file explorer), DAP (debugger). **Caveat**: DAP for the C++ plugin is standard (`nvim-dap` + `codelldb`/`cpptools`). DAP for QML itself is much less mature — investigate for real before assuming it works, don't just wire it up blind.
**Not enabled**: indentation guides, autopairs, extra linters (clangd's diagnostics cover enough for now).

**Statusline**: `lualine.nvim`, themed to our palette (not lualine's default rainbow mode-colors). Sections: mode indicator (cyan), git branch, filename+modified dot, diagnostics (semantic red/amber), filetype, LSP name, line:col.

---

## Terminal (Alacritty)
- Font: **`ttf-jetbrains-mono-nerd`** (JetBrains Mono Nerd Font) — resolves a discrepancy between the shell's README (said `caskaydia-cove-nerd`) and the actual dots manifest (`ttf-jetbrains-mono-nerd`); the manifest wins.
- fastfetch runs on every interactive shell start, wired into `~/.config/fish/config.fish`:
  ```fish
  if status is-interactive
      fastfetch
  end
  ```
- fastfetch custom logo: `~/.config/fastfetch/config.jsonc` → `"logo": { "source": "~/.config/fastfetch/logo.txt", "type": "file" }`. The ASCII art file was delivered during discussion. Module list inspired by a reference screenshot's layout (system/kernel/shell/uptime/DE-WM/memory/storage/colors), adapt for Arch.
- Starship prompt: added, themed via the same matugen pipeline as everything else (dynamic/pick-your-own applies here too).

---

## Keybinds (`hypr/hyprland/keybinds.lua`, `variables.lua`, `rules.lua`)
Approach: follow **end-4/dots-hyprland**'s key choices and patterns where equivalent functionality exists — **not a literal file copy**, end-4's binds call into a different Quickshell config's IPC handlers that don't exist here. Adapt to caelestia's actual IPC targets.

**Patterns adopted:**
- Resilient fallback — try the native shell IPC first, fall back to a standalone CLI tool if the shell isn't alive. Use this shape for the migration items below.
- App-launcher shortcuts bound to configurable variables (terminal/browser/file-manager/editor), not hardcoded — caelestia doesn't have this currently, worth adding.

**Verified during discussion: caelestia already matches end-4 almost everywhere else** — don't waste time "fixing" gaps that don't exist:
- `kbSession = "CTRL + ALT + Delete"`, `kbLock = "SUPER + L"`, direct sleep bind `SUPER+SHIFT+L` → `systemctl suspend-then-hibernate` — all already identical to end-4's choices.
- Scroll-wheel workspace switching, `Page_Up`/`Page_Down` nav, workspace-group jumps, window pin (`kbPinWindow`), fullscreen + "bordered fullscreen" (maximize), keyboard resize (covers split-ratio in tiled mode) — all already present.
- Explicitly declined as not worth adding: numpad duplicate workspace bindings, a direct poweroff quick-bind.

**Cheatsheet**: not a live in-app feature — becomes a static `README.md`/`KEYBINDS.md` in the repo instead, written once the scheme below is actually finalized in code.

**Required migrations (caelestia-cli is gone, these called it directly):**
- `caelestia shell -d` (2 places: restore-lock, kill/restart bind) → `qs -c caelestia -d` (trivial rename, unrelated to the CLI cut — this just launches Quickshell itself)
- `Print` key screenshot (`caelestia screenshot`) → switch to the same native global-shortcut path (`hl.dsp.global(...)`) the other screenshot binds already use — trivial
- **Special workspaces — dropped entirely**, not migrated. Remove all 5 toggle binds (`specialws`/`sysmon`/`music`/`communication`/`todo`) from `keybinds.lua`. **Also remove the window rules in `rules.lua`** that pinned apps to them, or those apps become unreachable:
  - `btop` → was `special:sysmon`
  - `feishin`/`Spotify`/`Supersonic`/`Cider`/YouTube Music/`Plexamp`/simpmusic (+ Spotify's title-match variant) → was `special:music`
  - `discord`/`equibop`/`vesktop`/`whatsapp` → was `special:communication`
  - `Todoist` → was `special:todo`
- Recording — simplified to **2 modes** (fullscreen + region-select, down from upstream's 3), via `wf-recorder` + `slurp`. No native IPC exists for this (`services/Recorder.qml` has no `IpcHandler`), build fresh.
- Clipboard/emoji — `fuzzel` as the picker frontend (matches the end-4 pattern already adopted), paired with `cliphist` for clipboard history, a plain curated emoji list for the emoji picker.

---

## setup.sh — full bootstrap
1. **Preflight** — confirm Arch Linux, confirm not root, confirm run from repo root
2. **AUR helper** — `yay`, bootstrap if not present
3. **Package install**, grouped:
   - Core/build: `hyprland`, `xdg-desktop-portal-hyprland`, `xdg-desktop-portal-gtk`, `quickshell-git` (AUR), `qt6-base`/`qt6-declarative`/`qt6-shadertools`, `m3shapes` (AUR), `cmake`, `ninja`, `pkg-config`
   - Native plugin build deps: `libqalculate`, `pipewire`, `aubio`, `libcava` (AUR), `fftw`
   - Shell utilities: `ddcutil`, `brightnessctl`, `lm-sensors`, `swappy`, `wl-clipboard`, `xkeyboard-config`, `cliphist`, `ydotool`, `hyprpicker`
   - Fonts: `ttf-jetbrains-mono-nerd`, `material-symbols`, `rubik`
   - Shell/terminal: `fish`, `eza`, `zoxide`, `direnv`, `alacritty`, `fastfetch`, `matugen` (AUR), `btop`, `starship`
   - Neovim: `neovim`, `git`, `clangd`, `qml-language-server`
   - GTK/Qt theming: `adw-gtk-theme`, `papirus-icon-theme`, `papirus-folders`, `darkly-bin`
   - Auth/network/bluetooth: `gnome-keyring`, `polkit-gnome`, `networkmanager`, `bluez`, `bluez-utils`
   - Audio: full `pipewire` stack, `wireplumber`, `pavucontrol`
   - File manager: `thunar`
   - General: `curl`, `git`, `trash-cli`, `jq`, `lazygit`, `bat`, `ripgrep`, `xdg-user-dirs`
   - **Explicitly NOT installed**: `caelestia-cli`, `foot` (upstream's default terminal — we use Alacritty)
4. **Build the native Quickshell plugin** — CMake steps above, pointed at `~/.config/quickshell/caelestia`
5. **Backup** any existing non-symlink configs (timestamped) before touching anything
6. **Symlink** each repo component to its XDG destination
7. **Set fish as default shell** — idempotent, skip if already fish
8. **Enable services** — NetworkManager, bluetooth (PipeWire is socket-activated, no explicit enable needed)
9. **First-run bootstrap** — `matugen color 29D3F0` to generate an initial scheme (so nothing's unstyled on first launch), headless Neovim run to let mason pre-install LSPs/plugins
10. **Done message** — reminder to log back into the Hyprland session

---

## Animation (`hypr/hyprland/animations.lua`)
Upstream's current config (32 lines) is already compact and intentional — Material Design 3 easing curve names, not bloated. Only change: **faster/snappier durations**, roughly 30–40% shorter, same curves/styles, same relative rhythm:

| Leaf | Current | New |
|---|---|---|
| layersIn | 500ms | 300ms |
| layersOut | 400ms | 300ms |
| fadeLayers | 500ms | 300ms |
| windowsIn | 500ms | 300ms |
| windowsOut | 300ms | 200ms |
| windowsMove | 600ms | 400ms |
| workspaces | 500ms | 300ms |
| specialWorkspace | 400ms | 300ms (n/a if special workspaces are fully removed — check whether this leaf is still meaningful once that's done) |
| fade | 600ms | 400ms |
| fadeDim | 600ms | 400ms |
| border | 600ms | 400ms |

Treat as a starting point — best judged by actually feeling it once running, not just read as numbers.

---

## Things intentionally NOT done (don't scope-creep these back in)
- None of end-4's 8 bonus features: OCR-to-clipboard, Google Lens-style region search, screen translation, AI summary (needs local Ollama), on-screen keyboard toggle, light/dark mode toggle, cursor zoom, VM submap.
- No standalone in-shell file explorer (there isn't one upstream either — `components/filedialog/` is just an open/save picker, not a file manager; Thunar covers this at the OS level).
- Bar itself (OS icon, workspaces, active window, clock, status icons, tray, power button + all its popouts) — **stays exactly as upstream**, no cuts requested.
- Nothing from caelestia's optional components (spotify/spicetify, other code editors, discord, todoist, uwsm, zen browser, the Firefox theme) unless explicitly asked for later.
