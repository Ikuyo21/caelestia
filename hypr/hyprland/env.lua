local vars = require("variables")

-- Themes
hl.env("QT_QPA_PLATFORMTHEME", "qtengine")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("XCURSOR_THEME", vars.cursorTheme)
hl.env("XCURSOR_SIZE", vars.cursorSize)

-- Toolkit backends
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("SDL_VIDEODRIVER", "wayland,x11,windows")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- XDG specifications
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Others
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")

-- The tools setup.sh installs into ~/.local/bin (caelestia, caelestia-record,
-- ...) are invoked by bare name from keybinds and the shell, but nothing else
-- puts ~/.local/bin on PATH (no login-shell profile does on stock Arch), so
-- everything the session spawns must inherit it from here
local path = os.getenv("PATH") or "/usr/local/bin:/usr/bin"
local localbin = (os.getenv("HOME") or "") .. "/.local/bin"
if not path:find(localbin, 1, true) then
    hl.env("PATH", localbin .. ":" .. path)
end
