#!/usr/bin/env bash
# setup.sh - full bootstrap for the caelestia dotfiles on Arch + Hyprland.
# Follows the 10-step plan in CLAUDE.md. Idempotent: safe to re-run.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/caelestia"
BIN_DIR="$HOME/.local/bin"
QS_CONF_DIR="$CONFIG_DIR/quickshell/caelestia"
STAMP="$(date +%Y%m%d_%H%M%S)"

log() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
die() {
    printf '\033[1;31merror:\033[0m %s\n' "$*" >&2
    exit 1
}

# ---------------------------------------------------------------- 1. preflight
[[ -f /etc/arch-release ]] || die "this bootstrap is Arch-only"
[[ $EUID -ne 0 ]] || die "run as your user, not root (sudo is used where needed)"
[[ -f "$REPO_DIR/setup.sh" && -d "$REPO_DIR/shell" ]] || die "run from the dotfiles repo root"

# ---------------------------------------------------------------- 2. AUR helper
if ! command -v yay >/dev/null; then
    log "bootstrapping yay"
    sudo pacman -S --needed --noconfirm git base-devel
    tmp="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
    (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
    rm -rf "$tmp"
fi

# ---------------------------------------------------------------- 3. packages
log "installing packages"
packages=(
    # Core/build (m3shapes is not a package - shell/CMakeLists.txt fetches it
    # from GitHub via FetchContent during the plugin build)
    hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    quickshell-git qt6-base qt6-declarative qt6-shadertools
    cmake ninja pkgconf
    # Native plugin build deps
    libqalculate pipewire aubio libcava fftw
    # Shell utilities
    ddcutil brightnessctl lm_sensors swappy wl-clipboard xkeyboard-config
    cliphist ydotool hyprpicker
    # Recording / pickers (the tooling built in this repo: caelestia-record,
    # caelestia-clipboard, caelestia-emoji)
    wf-recorder slurp fuzzel
    # Night light (hypr execs.lua)
    gammastep geoclue
    # Fonts (Rubik is installed straight from google/fonts below - AUR's
    # ttf-rubik is abandoned and its source URL is dead)
    ttf-jetbrains-mono-nerd ttf-material-symbols-variable-git
    noto-fonts noto-fonts-cjk noto-fonts-emoji
    # Shell/terminal
    fish eza zoxide direnv alacritty fastfetch matugen btop starship
    # Neovim (clangd ships inside clang; no standalone clangd package exists)
    neovim git clang qml-language-server-bin
    # GTK/Qt theming
    adw-gtk-theme papirus-icon-theme papirus-folders
    # Auth/network/bluetooth
    gnome-keyring polkit-gnome networkmanager bluez bluez-utils
    # Audio
    pipewire-alsa pipewire-pulse pipewire-jack wireplumber pavucontrol
    # File manager
    thunar
    # General
    curl trash-cli jq lazygit bat ripgrep xdg-user-dirs
)
# Explicitly NOT installed: caelestia-cli (replaced by bin/caelestia +
# matugen), foot (we use Alacritty), darkly-bin (QWidgets-only theme engine
# that drags in the whole KDE Frameworks 5+6 stack for a shell that is pure
# QML - dropped per the performance/simplicity philosophy, see CLAUDE.md)

# The old non-git ttf-material-symbols-variable (deleted from the AUR, left
# over from the original upstream caelestia install) conflicts with the -git
# variant and would abort yay's entire batched transaction. The -git package
# Provides= the same name, so nothing loses its dependency.
if pacman -Q ttf-material-symbols-variable &>/dev/null; then
    log "removing superseded ttf-material-symbols-variable (conflicts with the -git variant)"
    sudo pacman -Rdd --noconfirm ttf-material-symbols-variable
fi

yay -S --needed --noconfirm "${packages[@]}"

# Rubik (the shell's clock/workspaces font): AUR's ttf-rubik has been
# untouched since 2021 and downloads from a fonts.google.com endpoint whose
# zip layout changed, so its package() always fails. Install the variable
# fonts directly from the google/fonts repo instead.
rubik_dir="$HOME/.local/share/fonts/rubik"
if [[ ! -f "$rubik_dir/Rubik[wght].ttf" || ! -f "$rubik_dir/Rubik-Italic[wght].ttf" ]]; then
    log "installing the Rubik font from google/fonts"
    mkdir -p "$rubik_dir"
    curl -fsSL -o "$rubik_dir/Rubik[wght].ttf" \
        'https://raw.githubusercontent.com/google/fonts/main/ofl/rubik/Rubik%5Bwght%5D.ttf'
    curl -fsSL -o "$rubik_dir/Rubik-Italic[wght].ttf" \
        'https://raw.githubusercontent.com/google/fonts/main/ofl/rubik/Rubik-Italic%5Bwght%5D.ttf'
    fc-cache -f "$rubik_dir"
fi

# ---------------------------------------------------------------- 4. build shell plugin
log "building the native Quickshell plugin"
# Pre-approve shell/.envrc so direnv never blocks on it - neither here nor
# the first time a shell is opened inside shell/ after bootstrap
(cd "$REPO_DIR/shell" && direnv allow)
(
    cd "$REPO_DIR/shell"
    # -DVERSION: this fork has no git tags, so CMakeLists' `git describe
    # --tags` fallback dies with "VERSION is not set and failed to get from
    # git". Empty VERSION + explicit short rev instead (upstream's own CI
    # overrides the same two vars).
    cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
        -DVERSION="" -DGIT_REVISION="$(git rev-parse --short HEAD)" \
        "-DINSTALL_QSCONFDIR=$QS_CONF_DIR"
    cmake --build build
    cmake --install build
)

# ---------------------------------------------------------------- 5+6. backup & symlink
# link <repo path> <destination>: backs up a pre-existing non-symlink dest
link() {
    local src="$1" dest="$2"
    if [[ -e "$dest" && ! -L "$dest" ]]; then
        log "backing up $dest -> $dest.bak.$STAMP"
        mv "$dest" "$dest.bak.$STAMP"
    fi
    mkdir -p "$(dirname "$dest")"
    ln -sfn "$src" "$dest"
}

log "symlinking configs"
link "$REPO_DIR/hypr" "$CONFIG_DIR/hypr"
link "$REPO_DIR/nvim" "$CONFIG_DIR/nvim"
link "$REPO_DIR/fish" "$CONFIG_DIR/fish"
link "$REPO_DIR/alacritty" "$CONFIG_DIR/alacritty"
link "$REPO_DIR/fastfetch" "$CONFIG_DIR/fastfetch"
link "$REPO_DIR/matugen" "$CONFIG_DIR/matugen"
link "$REPO_DIR/starship.toml" "$CONFIG_DIR/starship.toml"
for script in "$REPO_DIR"/bin/*; do
    link "$script" "$BIN_DIR/$(basename "$script")"
done

# ---------------------------------------------------------------- 7. default shell
if [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v fish)" ]]; then
    log "setting fish as the default shell"
    chsh -s "$(command -v fish)"
fi

# ---------------------------------------------------------------- 8. services
log "enabling services"
sudo systemctl enable --now NetworkManager.service
sudo systemctl enable --now bluetooth.service
systemctl --user enable ydotool.service 2>/dev/null || true
# PipeWire is socket-activated per user session; nothing to enable

# ---------------------------------------------------------------- 9. first-run bootstrap
log "generating the initial color scheme (seed #29D3F0)"
mkdir -p "$STATE_DIR/wallpaper"
# Through the wrapper, not raw matugen: the wrapper finalizes the shell's
# scheme.json (jq metadata patch + atomic move) after matugen renders
"$BIN_DIR/caelestia" scheme set -c 29D3F0

log "pre-installing nvim plugins + tools (headless, takes a while)"
nvim --headless "+qa" || true
nvim --headless "+MasonToolsInstallSync" "+qa" || true

xdg-user-dirs-update || true

# ---------------------------------------------------------------- 10. done
log "done - log out and pick the Hyprland session to start the shell"
