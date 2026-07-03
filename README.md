# caelestia

Personal Arch + Hyprland dotfiles, built around a performance-focused fork of
[caelestia-dots/shell](https://github.com/caelestia-dots/shell) (Quickshell/QML).

Philosophy, in priority order when they conflict: **performance, beauty,
simplicity**. Upstream was trimmed to what earns its place, keeping its visual
identity. The full working spec lives in [CLAUDE.md](CLAUDE.md).

## Layout

| Path | What |
|---|---|
| `shell/` | The caelestia-shell fork (QML + native C++ plugin, built via CMake) |
| `hypr/` | Hyprland config (lua), keybinds — see [KEYBINDS.md](KEYBINDS.md) |
| `nvim/` | Neovim config (kickstart.nvim base, C/C++/QML scope) |
| `fish/` `alacritty/` `fastfetch/` `starship.toml` | Terminal stack |
| `matugen/` | Theming config + templates (the one pipeline everything reads) |
| `bin/` | `caelestia` wrapper + recording/clipboard/emoji helpers |
| `setup.sh` | Full Arch bootstrap |

## Install (Arch)

```sh
git clone https://github.com/Ikuyo21/caelestia.git ~/dotfiles
cd ~/dotfiles && ./setup.sh
```

The script installs packages (pacman + yay), builds the native Quickshell
plugin into `~/.config/quickshell/caelestia`, backs up and symlinks every
config, sets fish as the default shell, enables services, and generates the
first color scheme. Log out into the Hyprland session when it finishes.

## Theming — two modes, one pipeline

Everything (shell, Hyprland, Alacritty, starship, Neovim) is themed by
[matugen](https://github.com/InioX/matugen) from a single seed:

- **Dynamic** — palette derived from the current wallpaper
- **Pick your own** — palette derived from one seed color (default `#29D3F0`)

Switch modes in the shell (Wallpaper & style → Colours) or from a terminal:

```sh
caelestia scheme set -c 29D3F0   # seed mode
caelestia scheme set -w          # dynamic (wallpaper) mode
caelestia scheme set -m light    # light/dark
caelestia wallpaper -f <image>   # set wallpaper (drives colors in dynamic mode)
```

`bin/caelestia` is a small bash drop-in for the parts of caelestia-cli this
fork actually used; the CLI itself is not installed.

## Differences from upstream caelestia-shell

Cut: weather (everywhere, including the service), the dashboard's tab system +
calendar + lyrics/visualizer media tab, the lock screen's weather/media
widgets, nexus deep-settings pages (network/bluetooth/audio/apps/services/
language/about — system tools cover those), the launcher's named-scheme and
variant pickers, special workspaces (binds, rules, gestures), the native
lyrics service, caelestia-cli.

Changed: dashboard fused into a single view with linear-bar performance
cards, session menu redesigned as a text list, animations ~35% faster,
recording rebuilt on wf-recorder + slurp, clipboard/emoji pickers on
fuzzel + cliphist, terminal is Alacritty (not foot).

Unchanged: the bar and all its popouts, the OSD, the launcher's app/calc/
wallpaper flows, all IPC (`qs -c caelestia ipc call ...`).
