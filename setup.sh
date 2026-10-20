#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  setup.sh — make this Neovim config reproducible on another machine
# ─────────────────────────────────────────────────────────────────────────────
#    ./setup.sh              install what is missing, then verify
#    ./setup.sh --check      only report; change nothing (same list as
#                            :checkhealth config)
#    ./setup.sh --no-plugins skip the plugin step (packages + scripts only)
#    ./setup.sh --help
#
#  What it does, in order:
#    1. finds the tools this config shells out to (the table below)
#    2. installs the missing ones with the system package manager
#    3. links bin/* into ~/.local/bin so the previews also work from a shell
#    4. installs the plugin revisions pinned in lazy-lock.json
#    5. prints what is left to do by hand (LSP servers, treesitter parsers)
#
#  Safe to re-run: every step is a no-op when it is already done.
#  The tool table is the same one lua/config/health.lua reports, so
#  `:checkhealth config` inside Neovim tells you the same story.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${HOME}/.local/bin"
MODE="install"
DO_PLUGINS=1

for arg in "$@"; do
  case "$arg" in
  --check | -c) MODE="check" ;;
  --no-plugins) DO_PLUGINS=0 ;;
  -h | --help)
    sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
  *)
    echo "unknown option: $arg (try --help)" >&2
    exit 2
    ;;
  esac
done

# ── output helpers ───────────────────────────────────────────────────────────
if [ -t 1 ]; then
  B=$'\033[1m' DIM=$'\033[2m' GRN=$'\033[32m' YEL=$'\033[33m' RED=$'\033[31m' OFF=$'\033[0m'
else
  B='' DIM='' GRN='' YEL='' RED='' OFF=''
fi
section() { printf '\n%s==> %s%s\n' "$B" "$1" "$OFF"; }
ok() { printf '    %s✓%s %s\n' "$GRN" "$OFF" "$1"; }
skip() { printf '    %s·%s %s\n' "$DIM" "$OFF" "$1"; }
warn() { printf '    %s!%s %s\n' "$YEL" "$OFF" "$1"; }
bad() { printf '    %s✗%s %s\n' "$RED" "$OFF" "$1"; }

# ── the dependencies ─────────────────────────────────────────────────────────
# cmd | group | package (Arch) | why this config wants it
#
# core     -> the editor itself does not work properly without it
# optional -> one feature only; a missing one is not a broken editor
DEPS=(
  "nvim|core|neovim|the editor itself"
  "git|core|git|clones plugins; gitsigns; the dashboard's git branch"
  "rg|core|ripgrep|telescope live_grep"
  "fd|core|fd|telescope find_files"
  "node|core|nodejs|LSP servers and markdown-preview's build step"
  "python3|core|python|bin/livehtml (HTML preview), pyright"
  "gcc|core|gcc|treesitter parsers, native plugin builds"
  "make|core|make|native plugin builds"
  "curl|core|curl|downloading parsers and language servers"
  "unzip|core|unzip|mason unpacks its packages with it"
  "wl-copy|core|wl-clipboard|clipboard sync (Settings → Editor)"
  "typst|optional|typst|Typst live preview (<leader>tv)"
  "zathura|optional|zathura|PDF viewer for LaTeX and Typst"
  "sioyek|optional|sioyek-git|alternative PDF viewer (Settings → Viewers)"
  "latexmk|optional|texlive-binextra|continuous LaTeX; bin/texbuild covers for it"
  "biber|optional|texlive-bibtexextra|bibliographies with biblatex"
  "qutebrowser|optional|qutebrowser|the chrome-less preview window (bin/mdpreview)"
  "firefox|optional|firefox|fallback for bin/mdpreview"
  "xdg-open|optional|xdg-utils|opens previews in your real browser"
  "lazygit|optional|lazygit|git TUI"
)

# Helper scripts that ship inside this config.
SCRIPTS=(livehtml mdpreview texbuild)

# Packages that are not a command we can look for. Zathura's PDF rendering
# backend ships separately; without one zathura opens a black window.
EXTRA_PKGS=(zathura-pdf-mupdf)

# ── package manager ─────────────────────────────────────────────────────────
PM=""
SUDO=""
if command -v pacman >/dev/null 2>&1; then PM="pacman"; fi
if command -v apt-get >/dev/null 2>&1; then PM="${PM:-apt}"; fi
if command -v dnf >/dev/null 2>&1; then PM="${PM:-dnf}"; fi
if [ -z "$PM" ]; then
  warn "no known package manager — I will only report what is missing"
fi
if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then SUDO="sudo"; fi

# Arch package name -> the name the other families use (when it differs).
pkg_for() {
  local name="$1"
  case "$PM:$name" in
  apt:*)
    case "$name" in
    neovim) echo neovim ;;
    ripgrep) echo ripgrep ;;
    fd) echo fd-find ;;
    nodejs) echo nodejs ;;
    python) echo python3 ;;
    texlive-binextra) echo latexmk ;;
    texlive-bibtexextra) echo biber ;;
    sioyek-git) echo "" ;;
    typst) echo "" ;;
    *) echo "$name" ;;
    esac
    ;;
  dnf:*)
    case "$name" in
    fd) echo fd-find ;;
    python) echo python3 ;;
    texlive-binextra) echo latexmk ;;
    texlive-bibtexextra) echo biber ;;
    sioyek-git) echo "" ;;
    wl-clipboard) echo wl-clipboard ;;
    *) echo "$name" ;;
    esac
    ;;
  *) echo "$name" ;;
  esac
}

install_pkgs() { # install_pkgs pkg...
  [ -n "$PM" ] || return 1
  case "$PM" in
  pacman) $SUDO pacman -S --needed --noconfirm "$@" ;;
  apt) $SUDO apt-get install -y "$@" ;;
  dnf) $SUDO dnf install -y "$@" ;;
  esac
}

# ── 1 + 2. tools ─────────────────────────────────────────────────────────────
# Everything is checked first so --check can print the whole story, then the
# missing ones are installed in one batch (falling back to one at a time so a
# single bad package name cannot sink the rest).
section "Checking the tools this config uses"
missing_core=() missing_opt=() install_list=() aur_list=()
AUR_PKGS=" sioyek-git " # not in the repos: reported, never installed for you
for row in "${DEPS[@]}"; do
  IFS='|' read -r cmd group pkg why <<<"$row"
  if command -v "$cmd" >/dev/null 2>&1; then
    skip "$cmd — $(command -v "$cmd")"
    continue
  fi

  if [ "$group" = core ]; then
    missing_core+=("$cmd")
  else
    missing_opt+=("$cmd")
  fi

  if [ "$PM" = pacman ] && [[ "$AUR_PKGS" == *" $pkg "* ]]; then
    warn "$cmd missing (optional, AUR) — $why"
    continue
  fi

  local_pkg="$(pkg_for "$pkg")"
  if [ -z "$local_pkg" ]; then
    warn "$cmd missing — $why (no $PM package; install it by hand)"
    continue
  fi
  if [ "$group" = core ]; then
    bad "$cmd missing — $why  [${PM:-?}: $local_pkg]"
  else
    warn "$cmd missing (optional) — $why  [${PM:-?}: $local_pkg]"
  fi
  install_list+=("$local_pkg")
done

if [ "$MODE" = install ] && [ ${#install_list[@]} -gt 0 ] && [ -n "$PM" ]; then
  section "Installing ${#install_list[@]} package(s) with $PM"
  if ! install_pkgs "${install_list[@]}"; then
    warn "the batch failed — retrying one package at a time"
    for p in "${install_list[@]}"; do
      if install_pkgs "$p"; then ok "$p"; else warn "$p — could not install"; fi
    done
  fi
fi

# The AUR helper is never invoked for you; just say what to run.
if [ -n "$PM" ] && ! command -v sioyek >/dev/null 2>&1; then
  if command -v paru >/dev/null 2>&1; then
    aur_list+=("paru -S sioyek-git   # alternative PDF viewer")
  elif command -v yay >/dev/null 2>&1; then
    aur_list+=("yay -S sioyek-git   # alternative PDF viewer")
  fi
fi

# ── extra packages that are not a command ───────────────────────────────────
section "Extra packages"
if [ "$PM" = pacman ]; then
  for p in "${EXTRA_PKGS[@]}"; do
    if pacman -Qq "$p" >/dev/null 2>&1; then
      ok "$p"
    elif [ "$MODE" = install ]; then
      if install_pkgs "$p"; then ok "$p (installed)"; else warn "$p — could not install"; fi
    else
      warn "$p missing — zathura would open a black window"
    fi
  done
else
  skip "${EXTRA_PKGS[*]} — zathura's PDF backend, check your distribution"
fi

# ── 3. the helper scripts ────────────────────────────────────────────────────
section "Helper scripts (bin/)"
for name in "${SCRIPTS[@]}"; do
  src="$CONFIG_DIR/bin/$name"
  if [ ! -e "$src" ]; then
    bad "bin/$name is missing from the config"
    continue
  fi
  if [ -x "$src" ]; then :; else
    [ "$MODE" = install ] && chmod +x "$src"
  fi
  if [ "$MODE" = check ]; then
    ok "bin/$name — $(head -1 "$src" | sed 's/^#!//')"
  else
    mkdir -p "$BIN_DIR"
    ln -sfn "$src" "$BIN_DIR/$name"
    ok "bin/$name → $BIN_DIR/$name"
  fi
done
case ":$PATH:" in
*":$BIN_DIR:"*) : ;;
*) warn "$BIN_DIR is not on your PATH — add it to your shell rc to use mdpreview/texbuild outside Neovim" ;;
esac

# ── 4. plugins ───────────────────────────────────────────────────────────────
section "Plugins"
if [ "$DO_PLUGINS" = 0 ]; then
  skip "--no-plugins: leaving lazy.nvim alone"
elif ! command -v nvim >/dev/null 2>&1; then
  bad "nvim is not installed yet — re-run this script once it is"
elif [ "$MODE" = check ]; then
  if [ -d "$HOME/.local/share/nvim/lazy" ]; then
    ok "$(ls -1 "$HOME/.local/share/nvim/lazy" | wc -l) plugins installed"
  else
    warn "no plugins installed yet — run ./setup.sh"
  fi
else
  if [ -f "$CONFIG_DIR/lazy-lock.json" ]; then
    # restore = install exactly the revisions in lazy-lock.json, which is what
    # makes two machines behave the same
    ok "restoring the revisions pinned in lazy-lock.json"
    nvim --headless "+Lazy! restore" +qa 2>/dev/null || warn "lazy restore reported a problem — run :Lazy inside Neovim"
  else
    warn "no lazy-lock.json — installing the latest versions instead"
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || warn "lazy sync reported a problem — run :Lazy inside Neovim"
  fi
fi

# ── 5. what is left to do by hand ────────────────────────────────────────────
section "Left to do by hand"
cat <<EOF
    · LSP servers: open Neovim once — mason installs the ones listed in
      lua/plugins/lsp.lua (mason-lspconfig ensure_installed).
    · Treesitter parsers: downloaded on first open of a filetype (needs gcc + curl).
    · Zathura shows a black window? its PDF backend is a separate package:
        ${YEL}sudo pacman -S zathura-pdf-mupdf${OFF}
    · Verify everything from inside Neovim with:  ${B}:checkhealth config${OFF}
EOF
if [ ${#aur_list[@]} -gt 0 ]; then
  printf '    · AUR (not run for you): %s\n' "${aur_list[*]}"
fi
if [ ${#missing_opt[@]} -gt 0 ]; then
  printf '    · Optional, still missing: %s\n' "${missing_opt[*]}"
fi

# ── summary ──────────────────────────────────────────────────────────────────
section "Summary"
if [ ${#missing_core[@]} -eq 0 ]; then
  ok "all core tools present"
else
  bad "core tools still missing: ${missing_core[*]}"
fi
if [ "$MODE" = check ]; then
  printf '    %s--check: nothing was changed.%s\n' "$DIM" "$OFF"
fi
printf '    config: %s\n' "$CONFIG_DIR"
printf '    keys:   CHEATSHEET.md    map: README.md\n'
exit 0
