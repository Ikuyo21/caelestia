#!/usr/bin/env bash
# setup.sh - full bootstrap for the caelestia dotfiles on Arch + Hyprland.
#
# Idempotent: every step detects "already done" and skips, so it is safe to
# re-run after a partial failure. Existing configs are never deleted -
# anything in the way of a symlink (file, directory, or a foreign symlink
# from a previous dotfiles setup) is moved to <path>.bak.<timestamp> first,
# with a fresh timestamp per run so re-runs never overwrite earlier backups.
#
# Run with --dry-run to preview every action (packages, backups, symlinks,
# services, shell change) without touching anything.

set -euo pipefail

# ------------------------------------------------------------------- options
DRY_RUN=0
for arg in "$@"; do
    case "$arg" in
    --dry-run | -n) DRY_RUN=1 ;;
    --help | -h)
        cat <<'EOF'
usage: setup.sh [--dry-run]

Bootstraps the caelestia dotfiles on Arch + Hyprland: installs packages
(repo batched, AUR one at a time), builds the Quickshell plugin, backs up
and symlinks configs, offers to set fish as the default shell, enables
services, and generates the first colour scheme.

  --dry-run, -n   print every action a real run would take without
                  executing any of them (nothing is installed, moved,
                  linked, enabled, or changed)
  --help, -h      this text

A real run needs sudo (package install, plugin install, services) and asks
before changing your default shell.
EOF
        exit 0
        ;;
    *)
        printf 'unknown argument: %s (try --help)\n' "$arg" >&2
        exit 1
        ;;
    esac
done

REPO_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/caelestia"
BIN_DIR="$HOME/.local/bin"
QS_CONF_DIR="$CONFIG_DIR/quickshell/caelestia"
STAMP="$(date +%Y%m%d_%H%M%S)"

FAILED_PKGS=() # AUR packages whose build/install failed (reported at exit)
WARNINGS=()    # non-fatal issues and skipped steps (reported at exit)
BACKUPS=()     # everything moved out of the way this run (reported at exit)

log() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
plan() { printf '\033[1;35m[dry-run]\033[0m would %s\n' "$*"; }
warn() {
    printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2
    WARNINGS+=("$*")
}
die() {
    printf '\033[1;31merror:\033[0m %s\n' "$*" >&2
    exit 1
}
trap 'printf "\033[1;31merror:\033[0m setup.sh aborted at line %s: %s\n" "$LINENO" "$BASH_COMMAND" >&2' ERR

# ---------------------------------------------------------------- 1. preflight
# CAELESTIA_SETUP_ASSUME_ARCH=1 skips only the distro-file check so test
# harnesses can exercise the script off-Arch; everything else still applies
if [[ "${CAELESTIA_SETUP_ASSUME_ARCH:-0}" != 1 ]]; then
    [[ -f /etc/arch-release ]] || grep -qsE '^(ID|ID_LIKE)=.*arch' /etc/os-release ||
        die "this bootstrap is Arch-only"
fi
command -v pacman >/dev/null || die "pacman not found - this bootstrap is Arch-only"
[[ $EUID -ne 0 ]] || die "run as your user, not root (sudo is used where needed)"
[[ -f "$REPO_DIR/setup.sh" && -d "$REPO_DIR/shell" ]] ||
    die "cannot locate the dotfiles repo around setup.sh (resolved to: $REPO_DIR)"
command -v sudo >/dev/null ||
    die "sudo is required (as root: pacman -S sudo, then add your user to wheel)"
if [[ $DRY_RUN == 0 ]]; then
    # fail before the first download, not in the middle of one
    curl -fsIL --connect-timeout 10 https://archlinux.org >/dev/null 2>&1 ||
        die "no network - cannot reach https://archlinux.org"
else
    log "dry run - printing what a real run would do; nothing will be changed"
fi

# ---------------------------------------------------------------- 2. AUR helper
if command -v yay >/dev/null; then
    : # already present
elif [[ $DRY_RUN == 1 ]]; then
    plan "bootstrap yay (pacman -S git base-devel, then makepkg yay-bin from the AUR)"
else
    log "bootstrapping yay"
    sudo pacman -S --needed --noconfirm git base-devel
    tmp="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
    (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
    rm -rf "$tmp"
fi

# ---------------------------------------------------------------- 3. packages
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
    # caelestia-clipboard, caelestia-emoji); libnotify gives caelestia-record
    # its start/stop notifications
    wf-recorder slurp fuzzel libnotify
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
# variant. The -git package Provides= the same name, so nothing loses its
# dependency. Removing it up front is what keeps the conflict from aborting
# an install transaction (which is exactly what happened in a real run).
# NB: `pacman -Q <name>` resolves Provides= (once the -git variant is
# installed, it matches the old name too - query.c falls back to
# alpm_find_satisfier), while -R only takes literal names. So compare the
# resolved package name and only remove the genuine leftover.
if [[ "$(pacman -Qq ttf-material-symbols-variable 2>/dev/null)" == "ttf-material-symbols-variable" ]]; then
    if [[ $DRY_RUN == 1 ]]; then
        plan "remove superseded ttf-material-symbols-variable (pacman -Rdd; the -git variant replaces it)"
    else
        log "removing superseded ttf-material-symbols-variable (conflicts with the -git variant)"
        sudo pacman -Rdd --noconfirm ttf-material-symbols-variable ||
            warn "could not remove ttf-material-symbols-variable - the -git variant's install may hit a conflict"
    fi
fi

# Which of the wanted packages are actually missing? (pacman -T honours
# Provides=, so an installed provider satisfies its plain name)
missing=()
while IFS= read -r p; do
    [[ -n "$p" ]] && missing+=("$p")
done < <(pacman -T "${packages[@]}" || true)

if [[ ${#missing[@]} -eq 0 ]]; then
    log "all ${#packages[@]} packages already installed"
else
    # Split repo vs AUR: repo packages go through pacman in one batch (a repo
    # transaction either works or the mirrors/keyring need human attention);
    # AUR packages are built ONE AT A TIME so a single failed build cannot
    # take unrelated packages down with it. In a real run, one conflict
    # killed the whole batched transaction including two packages that had
    # already built successfully - never again.
    repo_missing=()
    aur_missing=()
    for p in "${missing[@]}"; do
        if pacman -Si "$p" &>/dev/null; then
            repo_missing+=("$p")
        else
            aur_missing+=("$p")
        fi
    done

    if [[ $DRY_RUN == 1 ]]; then
        if [[ ${#repo_missing[@]} -gt 0 ]]; then
            plan "install ${#repo_missing[@]} repo packages (pacman, one batch): ${repo_missing[*]}"
        fi
        if [[ ${#aur_missing[@]} -gt 0 ]]; then
            plan "build+install ${#aur_missing[@]} AUR packages (yay, one at a time): ${aur_missing[*]}"
        fi
    else
        if [[ ${#repo_missing[@]} -gt 0 ]]; then
            log "installing ${#repo_missing[@]} repo packages"
            sudo pacman -S --needed --noconfirm "${repo_missing[@]}"
        fi
        for p in "${aur_missing[@]}"; do
            log "building/installing $p (AUR)"
            if ! yay -S --needed --noconfirm "$p"; then
                warn "$p failed to install - continuing with the rest"
                FAILED_PKGS+=("$p")
            fi
        done
    fi
fi

# Rubik (the shell's clock/workspaces font): AUR's ttf-rubik has been
# untouched since 2021 and downloads from a fonts.google.com endpoint whose
# zip layout changed, so its package() always fails. Install the variable
# fonts directly from the google/fonts repo instead.
rubik_dir="$HOME/.local/share/fonts/rubik"
rubik_base='https://raw.githubusercontent.com/google/fonts/main/ofl/rubik'
if [[ -f "$rubik_dir/Rubik[wght].ttf" && -f "$rubik_dir/Rubik-Italic[wght].ttf" ]]; then
    log "Rubik font already installed"
elif [[ $DRY_RUN == 1 ]]; then
    plan "download Rubik[wght].ttf + Rubik-Italic[wght].ttf from google/fonts into $rubik_dir and fc-cache"
else
    log "installing the Rubik font from google/fonts"
    mkdir -p "$rubik_dir"
    # download to temp names so a truncated file never masquerades as installed
    if curl -fsSL -o "$rubik_dir/.rubik.tmp" "$rubik_base/Rubik%5Bwght%5D.ttf" &&
        curl -fsSL -o "$rubik_dir/.rubik-italic.tmp" "$rubik_base/Rubik-Italic%5Bwght%5D.ttf"; then
        mv "$rubik_dir/.rubik.tmp" "$rubik_dir/Rubik[wght].ttf"
        mv "$rubik_dir/.rubik-italic.tmp" "$rubik_dir/Rubik-Italic[wght].ttf"
        fc-cache -f "$rubik_dir"
    else
        rm -f "$rubik_dir/.rubik.tmp" "$rubik_dir/.rubik-italic.tmp"
        warn "Rubik download failed - clock/workspaces will use a fallback font (re-run setup.sh to retry)"
    fi
fi

# ---------------------------------------------------------------- 4. build shell plugin
# Mirrors the upstream README's documented install exactly: prefix / puts
# the compiled QML modules in /usr/lib/qt6/qml where quickshell actually
# looks, which is why the install step needs sudo. The QSCONFDIR override is
# an absolute path into $HOME, so those files are chowned back to the user
# afterwards (sudo install writes them as root).
if [[ $DRY_RUN == 1 ]]; then
    plan "direnv allow $REPO_DIR/shell (pre-approve .envrc)"
    plan "cmake configure+build the shell plugin, then: sudo cmake --install (QML modules -> /usr/lib/qt6/qml, shell config -> $QS_CONF_DIR, chowned back to $USER)"
elif ! command -v cmake >/dev/null || ! command -v ninja >/dev/null; then
    warn "cmake/ninja missing (package install failed?) - skipped the shell plugin build"
else
    log "building the native Quickshell plugin"
    # Pre-approve shell/.envrc so direnv never blocks on it - neither here
    # nor the first time a shell is opened inside shell/ after bootstrap
    if command -v direnv >/dev/null; then
        (cd "$REPO_DIR/shell" && direnv allow)
    fi
    # -DVERSION: this fork has no git tags, so CMakeLists' `git describe
    # --tags` fallback dies with "VERSION is not set and failed to get from
    # git". Any fixed dotted version works (upstream's own CI overrides the
    # same two vars; empty also configures but makes project() warn).
    if (cd "$REPO_DIR/shell" &&
        cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
            -DVERSION=1.0.0 \
            -DGIT_REVISION="$(git -C "$REPO_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)" \
            -DCMAKE_INSTALL_PREFIX=/ \
            "-DINSTALL_QSCONFDIR=$QS_CONF_DIR" &&
        cmake --build build) &&
        sudo cmake --install "$REPO_DIR/shell/build" &&
        sudo chown -R "$(id -u):$(id -g)" "$QS_CONF_DIR"; then
        : # built and installed
    else
        warn "shell plugin build/install failed - the rest of the setup continues; re-run setup.sh after fixing"
    fi
fi

# ---------------------------------------------------------------- 5+6. backup & symlink
# ~/.config/caelestia is a third config dir (user overrides), distinct from
# ~/.config/hypr and the Quickshell config dir. hyprland.lua auto-creates
# hypr-vars.lua/hypr-user.lua in it via io.open(..., "w") - which silently
# no-ops when the parent dir is missing, so the require() right after trips
# Hyprland's emergency mode on first login. It must exist before the hypr
# symlink makes hyprland.lua reachable.
if [[ ! -d "$CONFIG_DIR/caelestia" ]]; then
    if [[ $DRY_RUN == 1 ]]; then
        plan "create $CONFIG_DIR/caelestia (user-override dir hyprland.lua writes into)"
    else
        log "creating $CONFIG_DIR/caelestia (user-override dir)"
        mkdir -p "$CONFIG_DIR/caelestia"
    fi
fi

# link <repo path> <dest>: idempotent - a link that already points at the
# repo is left alone; anything else in the way (file, directory, or a
# foreign symlink from someone's previous dotfiles) is moved to
# <dest>.bak.<timestamp> first. Nothing is ever deleted.
link() {
    local src="$1" dest="$2"
    if [[ -L "$dest" && "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
        return 0 # already linked correctly
    fi
    if [[ $DRY_RUN == 1 ]]; then
        if [[ -e "$dest" || -L "$dest" ]]; then
            plan "back up $dest -> $dest.bak.$STAMP"
        fi
        plan "symlink $dest -> $src"
        return 0
    fi
    if [[ -e "$dest" || -L "$dest" ]]; then
        log "backing up $dest -> $dest.bak.$STAMP"
        mv "$dest" "$dest.bak.$STAMP"
        BACKUPS+=("$dest -> $dest.bak.$STAMP")
    fi
    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
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
fish_path="$(command -v fish || true)"
current_shell="$(getent passwd "${USER:-$(id -un)}" | cut -d: -f7)"
if [[ -n "$fish_path" && "$current_shell" == "$fish_path" ]]; then
    log "fish is already the default shell"
elif [[ $DRY_RUN == 1 ]]; then
    # fish may not be installed yet here, but the real run installs it first
    plan "ask before changing the default shell ($current_shell -> fish); skipped when non-interactive"
elif [[ -z "$fish_path" ]]; then
    warn "fish is not installed - leaving the default shell alone"
elif [[ -t 0 ]]; then
    printf '\033[1;36m==>\033[0m Change your default shell from %s to fish? [Y/n] ' "$current_shell"
    read -r reply || reply="" # EOF = accept the default
    if [[ "$reply" =~ ^[Nn] ]]; then
        log "keeping $current_shell (change later with: chsh -s $fish_path)"
    else
        chsh -s "$fish_path" || warn "chsh failed - change it manually: chsh -s $fish_path"
    fi
else
    warn "non-interactive run - default shell left as $current_shell (chsh -s $fish_path to change)"
fi

# ---------------------------------------------------------------- 8. services
enable_service() { # enable_service <unit>: system service, idempotent
    local unit="$1"
    if systemctl is-enabled "$unit" &>/dev/null; then
        log "$unit already enabled"
    elif [[ $DRY_RUN == 1 ]]; then
        plan "sudo systemctl enable --now $unit"
    else
        log "enabling $unit"
        sudo systemctl enable --now "$unit" || warn "could not enable $unit"
    fi
}

# NetworkManager: the shell's network widget needs it, but silently hijacking
# networking on a machine that already runs a different stack is worse than a
# missing widget - detect and skip instead
nm_conflict=""
for unit in systemd-networkd dhcpcd iwd connman; do
    if systemctl is-enabled "$unit.service" &>/dev/null; then
        nm_conflict="$unit"
        break
    fi
done
if [[ -n "$nm_conflict" ]] && ! systemctl is-enabled NetworkManager.service &>/dev/null; then
    warn "$nm_conflict already manages networking - NOT enabling NetworkManager (the shell's network widget needs NM; switch manually if you want it)"
else
    enable_service NetworkManager.service
fi
enable_service bluetooth.service

if systemctl --user is-enabled ydotool.service &>/dev/null; then
    log "ydotool.service (user) already enabled"
elif [[ $DRY_RUN == 1 ]]; then
    plan "systemctl --user enable ydotool.service"
else
    log "enabling ydotool.service (user)"
    systemctl --user enable ydotool.service 2>/dev/null || true
fi
# PipeWire is socket-activated per user session; nothing to enable

# ---------------------------------------------------------------- 9. first-run bootstrap
if [[ -f "$STATE_DIR/scheme.json" ]]; then
    # never reset colours someone has since picked themselves
    log "colour scheme already generated - keeping current colours"
elif [[ $DRY_RUN == 1 ]]; then
    plan "generate the initial colour scheme (seed #29D3F0) via $BIN_DIR/caelestia"
elif [[ -x "$BIN_DIR/caelestia" ]] && command -v matugen >/dev/null && command -v jq >/dev/null; then
    log "generating the initial colour scheme (seed #29D3F0)"
    mkdir -p "$STATE_DIR/wallpaper"
    # Through the wrapper, not raw matugen: the wrapper finalizes the shell's
    # scheme.json (jq metadata patch + atomic move) after matugen renders
    "$BIN_DIR/caelestia" scheme set -c 29D3F0 ||
        warn "initial scheme generation failed - retry with: caelestia scheme set -c 29D3F0"
else
    warn "matugen/jq/caelestia unavailable - skipped scheme generation (run: caelestia scheme set -c 29D3F0)"
fi

if [[ $DRY_RUN == 1 ]]; then
    plan "pre-install nvim plugins + mason tools (headless nvim runs)"
elif command -v nvim >/dev/null; then
    log "pre-installing nvim plugins + tools (headless, takes a while)"
    nvim --headless "+qa" || true
    nvim --headless "+MasonToolsInstallSync" "+qa" || true
else
    warn "nvim missing - skipped plugin pre-install"
fi

if [[ $DRY_RUN == 1 ]]; then
    plan "xdg-user-dirs-update"
else
    xdg-user-dirs-update 2>/dev/null || true
fi

# ---------------------------------------------------------------- 10. done
echo
if [[ ${#BACKUPS[@]} -gt 0 ]]; then
    log "backed up this run (nothing was deleted):"
    for b in "${BACKUPS[@]}"; do printf '      %s\n' "$b"; done
fi
if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    log "${#WARNINGS[@]} warning(s) this run:"
    for w in "${WARNINGS[@]}"; do printf '      %s\n' "$w"; done
fi
if [[ ${#FAILED_PKGS[@]} -gt 0 ]]; then
    printf '\033[1;31merror:\033[0m %d package(s) failed to install: %s\n' \
        "${#FAILED_PKGS[@]}" "${FAILED_PKGS[*]}" >&2
    printf '       re-run setup.sh to retry just what is missing\n' >&2
    exit 1
fi
if [[ $DRY_RUN == 1 ]]; then
    log "dry run complete - nothing was changed"
else
    log "done - log out and pick the Hyprland session to start the shell"
fi
