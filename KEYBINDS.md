# Keybinds

The static cheatsheet (per spec: a doc, not an in-shell overlay). Source of
truth is [hypr/hyprland/keybinds.lua](hypr/hyprland/keybinds.lua) +
[hypr/variables.lua](hypr/variables.lua); key choices there are configurable
via `~/.config/caelestia/hypr-vars.lua` overrides.

## Shell

| Keys | Action |
|---|---|
| `Super` (tap) | Launcher |
| `Ctrl+Alt+Delete` | Session menu (logout / shutdown / hibernate / reboot) |
| `Super+N` | Sidebar |
| `Super+K` | Show all panels |
| `Ctrl+Alt+C` | Clear notifications |
| `Super+L` | Lock |
| `Super+Alt+L` | Restore shell + lock |
| `Ctrl+Super+Shift+R` | Kill shell |
| `Ctrl+Super+Alt+R` | Restart shell |

## Media & hardware

| Keys | Action |
|---|---|
| `Ctrl+Super+Space` / `XF86AudioPlay/Pause` | Play/pause |
| `Ctrl+Super+=` / `XF86AudioNext` | Next track |
| `Ctrl+Super+-` / `XF86AudioPrev` | Previous track |
| `XF86AudioStop` | Stop |
| `XF86AudioRaise/LowerVolume` | Volume ±10% |
| `Super+Shift+M` / `XF86AudioMute` | Mute output |
| `XF86AudioMicMute` | Mute mic |
| `XF86MonBrightnessUp/Down` | Brightness |
| `Super+Shift+L` | Sleep (suspend-then-hibernate) |

## Workspaces

| Keys | Action |
|---|---|
| `Super+1..0` | Go to workspace 1–10 |
| `Super+Alt+1..0` | Move window to workspace 1–10 |
| `Ctrl+Super+1..0` | Jump to workspace group |
| `Ctrl+Super+Alt+1..0` | Move window to workspace group |
| `Super+Scroll` / `Ctrl+Super+←/→` / `Super+PgUp/PgDn` | Workspace ±1 |
| `Ctrl+Super+Scroll` | Workspace group ±10 |
| `Super+Alt+PgUp/PgDn` / `Super+Alt+Scroll` / `Ctrl+Super+Shift+←/→` | Move window to workspace ±1 |

Special workspaces don't exist in this fork (dropped entirely, including all
app pinning rules).

## Windows

| Keys | Action |
|---|---|
| `Super+←↑↓→` | Focus in direction |
| `Super+Shift+←↑↓→` | Move window |
| `Super+-` / `Super+=` | Resize horizontally |
| `Super+Shift+-` / `Super+Shift+=` | Resize vertically |
| `Super+Alt+←↑↓→` | Resize |
| `Super+LMB drag` / `Super+Z` | Move (mouse) |
| `Super+RMB drag` / `Super+X` | Resize (mouse) |
| `Super+Q` | Close |
| `Super+F` | Fullscreen |
| `Super+Alt+F` | Bordered fullscreen (maximize) |
| `Super+Alt+Space` | Toggle floating |
| `Super+P` | Pin |
| `Super+Alt+\` | Picture-in-picture |
| `Ctrl+Super+\` | Center |
| `Ctrl+Super+Alt+\` | Resize to 55%×70% + center |
| `Alt+Tab` / `Shift+Alt+Tab` | Cycle windows in group |
| `Ctrl+Alt+Tab` / `Ctrl+Shift+Alt+Tab` | Next/prev group |
| `Super+,` | Toggle group |
| `Super+Shift+,` | Lock group |
| `Super+U` | Ungroup window |

## Apps

| Keys | Action |
|---|---|
| `Super+T` | Terminal (alacritty) |
| `Super+W` | Browser (firefox) |
| `Super+C` | Editor (alacritty -e nvim) |
| `Super+E` | File manager (thunar) |
| `Ctrl+Alt+V` | Audio settings (pavucontrol) |

## Utilities

| Keys | Action |
|---|---|
| `Print` / `Super+Shift+Alt+S` | Screenshot |
| `Super+Shift+S` | Screenshot (freeze screen first) |
| `Ctrl+Alt+R` | Record fullscreen (toggle) |
| `Super+Shift+Alt+R` | Record region (slurp select) |
| `Super+Shift+C` | Color picker (hyprpicker) |
| `Super+V` | Clipboard history |
| `Super+Alt+V` | Clipboard history (delete mode) |
| `Super+.` | Emoji picker |
| `Ctrl+Shift+Alt+V` | Type most recent clipboard entry |
