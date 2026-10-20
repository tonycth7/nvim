#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  setup.sh — one command to get this Neovim config running on any machine
#
#  https://github.com/tonycth7/nvim
# ─────────────────────────────────────────────────────────────────────────────
#
#  Fresh machine (needs only bash + curl + internet):
#
#    curl -fsSL https://raw.githubusercontent.com/tonycth7/nvim/main/setup.sh | bash
#
#  Pass options through the pipe with `bash -s --`:
#
#    curl -fsSL https://raw.githubusercontent.com/tonycth7/nvim/main/setup.sh | bash -s -- --full
#
#  Or from a checkout:   ./setup.sh [options]
#
#  What it does, in order (every step is skipped when already done, so it is
#  safe to run again — re-running is also how you update):
#
#    1. detects OS / CPU / package manager (Arch, Debian/Ubuntu, Fedora/RHEL,
#       openSUSE, Alpine, Void, macOS+Homebrew)
#    2. installs the tools the config shells out to — git, a C compiler,
#       ripgrep, fd, node, python3, clipboard helper, tree-sitter-cli, …
#    3. makes sure Neovim is new enough (>= 0.11). If the distro's package is
#       too old, the official release is installed into ~/.local instead
#    4. clones the config to ~/.config/nvim (or pulls it); an existing
#       different config is moved to ~/.config/nvim.bak-<time>, never deleted
#    5. links bin/* into ~/.local/bin and puts that on PATH
#    6. installs a Nerd Font (the config draws icons)
#    7. restores the plugin revisions pinned in lazy-lock.json
#    8. pre-installs LSP servers / formatters (Mason) and tree-sitter parsers,
#       so the first real launch is instant instead of a wall of downloads
#    9. verifies the result (startup errors, :checkhealth config)
#
#  Options:
#    --minimal        core tools only (no typst, lazygit, go, …)
#    --full           everything: + LaTeX toolchain, zathura, qutebrowser
#    --check, -c      only report what is missing; change nothing
#    --dry-run, -n    show what would be done; change nothing
#    --yes, -y        never ask questions (default when there is no terminal)
#    --no-packages    do not touch system packages (user-space installs only)
#    --no-fonts       skip the Nerd Font
#    --no-plugins     skip the plugin restore
#    --no-lsp         skip Mason (LSP servers / formatters)
#    --no-parsers     skip tree-sitter parsers
#    --no-shell-rc    do not edit ~/.bashrc / ~/.zshrc / fish config
#    --repo URL       config repository   (default: tonycth7/nvim on GitHub)
#    --branch NAME    branch to check out (default: the repo's default)
#    --dir PATH       where the config lives (default: ~/.config/nvim)
#    --uninstall      remove what this script added (asks before deleting data)
#    --help, -h
#
#  Environment: NVIM_CONFIG_REPO, NVIM_CONFIG_BRANCH, NVIM_CONFIG_DIR.
#  Log of every command: ~/.cache/nvim-setup/setup-<time>.log
#
#  Works with bash 3.2 (the one macOS ships) and newer.
# ─────────────────────────────────────────────────────────────────────────────

# No `set -e`: most steps are best-effort, and each one reports its own result.
set -o pipefail

REPO_URL="${NVIM_CONFIG_REPO:-https://github.com/tonycth7/nvim.git}"
BRANCH="${NVIM_CONFIG_BRANCH:-}"
CONFIG_DIR="${NVIM_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/nvim}"

MIN_NVIM="0.11.0"   # lua/config/health.lua: vim.lsp.config, inlay hints
MIN_NODE="18"       # mason's npm packages, markdown-preview
MIN_GO="1.21"       # first Go that can fetch the toolchain gopls wants

BIN_DIR="$HOME/.local/bin"
OPT_DIR="$HOME/.local/opt"
ORIG_PATH="$PATH"
export PATH="$BIN_DIR:$PATH"

MODE="install"; PROFILE="standard"; ASSUME_YES=0; DRY=0
DO_PKGS=1; DO_FONTS=1; DO_PLUGINS=1; DO_LSP=1; DO_PARSERS=1; DO_RC=1

# Language servers / tools Mason pre-installs (see lua/plugins/lsp.lua).
MASON_PKGS="lua-language-server typescript-language-server pyright gopls rust-analyzer texlab tinymist marksman stylua shfmt prettier black goimports latexindent"
# Tree-sitter parsers. The config starts tree-sitter for any filetype that has one.
TS_LANGS="lua luadoc vim vimdoc query markdown markdown_inline latex bibtex typst bash python javascript typescript tsx json jsonc yaml toml html css go gomod rust c cpp regex diff gitcommit git_config gitignore make dockerfile sql comment"

# ── output ───────────────────────────────────────────────────────────────────
TTY_OUT=0; [ -t 1 ] && TTY_OUT=1
TTY_IN=0;  ( : </dev/tty ) 2>/dev/null && TTY_IN=1
USE_COLOR=0
{ [ "$TTY_OUT" = 1 ] || [ -n "${FORCE_COLOR:-}" ]; } && [ -z "${NO_COLOR:-}" ] && [ "${TERM:-}" != dumb ] && USE_COLOR=1
if [ "$USE_COLOR" = 1 ]; then
  B=$'\033[1m' DIM=$'\033[38;5;244m' OFF=$'\033[0m'
  GRN=$'\033[38;5;78m' YEL=$'\033[38;5;221m' RED=$'\033[38;5;203m' CYN=$'\033[38;5;117m'
  ACC=$'\033[38;5;111m' PUR=$'\033[38;5;141m' PNK=$'\033[38;5;212m'
else
  B='' DIM='' GRN='' YEL='' RED='' CYN='' ACC='' PUR='' PNK='' OFF=''
fi
UTF=0
case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in *[Uu][Tt][Ff]-8* | *[Uu][Tt][Ff]8*) UTF=1 ;; esac
if [ "$UTF" = 1 ]; then
  S_OK="✔" S_BAD="✘" S_WARN="▲" S_DOT="•" S_ARR="➜"
  BX_TL="╭" BX_BL="╰" BX_V="│" BX_H="─" SEC_MARK="▍"
  FRAMES=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
else
  S_OK="+" S_BAD="x" S_WARN="!" S_DOT="." S_ARR=">"
  BX_TL="+" BX_BL="+" BX_V="|" BX_H="-" SEC_MARK="|"
  FRAMES=('|' '/' '-' '\')
fi
N_WARN=0; N_BAD=0; PROBLEMS=""; MANUAL=""; SEC_N=0
short() { local h="~"; printf '%s' "${1//$HOME/$h}"; }   # /home/me/x → ~/x
rule() { local n="${1:-58}" i; printf '%s' "$DIM"; for ((i = 0; i < n; i++)); do printf '%s' "$BX_H"; done; printf '%s' "$OFF"; }
section() {
  SEC_N=$((SEC_N + 1))
  printf '\n  %s%s%s %s%s%s  %s%s%s\n  %s\n' "$ACC" "$SEC_MARK" "$OFF" "$DIM" "$SEC_N" "$OFF" "$B" "$1" "$OFF" "$(rule 58)"
}
ok()   { printf '    %s%s%s  %s\n' "$GRN" "$S_OK" "$OFF" "$(short "$1")"; }
skip() { printf '    %s%s%s  %s%s%s\n' "$DIM" "$S_DOT" "$OFF" "$DIM" "$(short "$1")" "$OFF"; }
info() { printf '    %s%s%s  %s\n' "$CYN" "$S_ARR" "$OFF" "$(short "$1")"; }
warn() { N_WARN=$((N_WARN + 1)); printf '    %s%s%s  %s\n' "$YEL" "$S_WARN" "$OFF" "$(short "$1")"; }
bad()  { N_BAD=$((N_BAD + 1)); PROBLEMS="$PROBLEMS
      - $1"; printf '    %s%s%s  %s\n' "$RED" "$S_BAD" "$OFF" "$(short "$1")"; }
todo() { MANUAL="$MANUAL
$1"; }
die()  { printf '%s%s%s %s\n' "$RED" "$S_BAD" "$OFF" "$1" >&2; exit 1; }
# aligned "name   detail" cell used by the tool table
trow() { printf '%-13s %s%s%s' "$1" "$DIM" "$(short "$2")" "$OFF"; }

banner() {
  local t="$B"
  printf '\n'
  if [ "$UTF" = 1 ]; then
    printf '   %s█▄ █%s  %s█ █%s  %s█%s  %s█▀▄▀█%s    %ssetup%s\n' "$ACC" "$OFF" "$PUR" "$OFF" "$PNK" "$OFF" "$GRN" "$OFF" "$DIM" "$OFF"
    printf '   %s█ ▀█%s  %s▀▄▀%s  %s█%s  %s█ ▀ █%s    %sone command, whole editor%s\n' "$ACC" "$OFF" "$PUR" "$OFF" "$PNK" "$OFF" "$GRN" "$OFF" "$DIM" "$OFF"
  else
    printf '   %sNVIM setup%s - one command, whole editor\n' "$t" "$OFF"
  fi
  printf '\n   %s%s%s\n' "$DIM" "$(short "$REPO_URL")" "$OFF"
  printf '   %s%s %s %s %s %s %s profile: %s%s\n' "$DIM" "$DISTRO" "$S_DOT" "$ARCH" "$S_DOT" "${PM:-no package manager}" "$S_DOT" "$PROFILE" "$OFF"
  local flags=""
  [ "$MODE" = check ] && flags=" check only — nothing will change"
  [ "$DRY" = 1 ] && [ "$MODE" != check ] && flags=" dry run — nothing will change"
  [ -n "$flags" ] && printf '   %s%s%s%s\n' "$YEL" "$S_WARN" "$flags" "$OFF"
  printf '   %slog: %s%s\n' "$DIM" "$(short "$LOG")" "$OFF"
}

# ── helpers ──────────────────────────────────────────────────────────────────
have() { command -v "$1" >/dev/null 2>&1; }
have_any() { local c; for c in $1; do have "$c" && return 0; done; return 1; }
ver_ge() { # ver_ge A B  → A >= B
  [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]
}
abs_dir() { (cd -P "$1" 2>/dev/null && pwd -P); }

TMP="$(mktemp -d 2>/dev/null || mktemp -d -t nvimsetup)"
LOG_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/nvim-setup"
mkdir -p "$LOG_DIR" 2>/dev/null
LOG="$LOG_DIR/setup-$(date +%Y%m%d-%H%M%S).log"
: >"$LOG"
SUDO_KEEPALIVE=""
cleanup() {
  [ -n "$SUDO_KEEPALIVE" ] && kill "$SUDO_KEEPALIVE" 2>/dev/null
  rm -rf "$TMP"
}
trap cleanup EXIT
trap 'printf "\n"; die "interrupted"' INT TERM

# step "what" cmd args… — run quietly (output → log), show a spinner on a tty.
step() {
  local desc="$1"; shift
  if [ "$DRY" = 1 ]; then info "would: $desc"; return 0; fi
  local start rc pid i=0 t0=$SECONDS took=""
  start=$(wc -l <"$LOG")
  printf '\n### %s :: %s\n' "$desc" "$*" >>"$LOG"
  if [ "$TTY_OUT" = 1 ]; then
    "$@" >>"$LOG" 2>&1 </dev/null &
    pid=$!
    while kill -0 "$pid" 2>/dev/null; do
      printf '\r    %s%s%s  %s %s%ss%s' "$ACC" "${FRAMES[$((i % ${#FRAMES[@]}))]}" "$OFF" "$desc" "$DIM" "$((SECONDS - t0))" "$OFF"
      i=$((i + 1)); sleep 0.1
    done
    wait "$pid"; rc=$?
    printf '\r\033[K'
  else
    "$@" >>"$LOG" 2>&1 </dev/null; rc=$?
  fi
  [ $((SECONDS - t0)) -ge 3 ] && took="  ${DIM}$((SECONDS - t0))s${OFF}"
  if [ "$rc" -eq 0 ]; then
    ok "$desc$took"
  else
    bad "$desc (exit $rc)"
    tail -n +"$((start + 1))" "$LOG" | tail -n 8 | cut -c1-150 | sed "s/^/        ${DIM}/;s/\$/${OFF}/"
  fi
  return "$rc"
}

# step_soft: like step, but a failure is only a warning (optional things).
step_soft() {
  local n0=$N_BAD p0="$PROBLEMS" rc
  step "$@"; rc=$?
  if [ "$rc" -ne 0 ]; then N_BAD=$n0; PROBLEMS="$p0"; N_WARN=$((N_WARN + 1)); fi
  return "$rc"
}

dl() { # dl URL OUT
  curl -fsSL --retry 3 --retry-delay 2 --connect-timeout 20 -o "$2" "$1"
}
gh_latest_tag() { # gh_latest_tag owner/repo → v1.2.3 (empty on failure)
  local t
  t="$(curl -fsSL --retry 2 --connect-timeout 20 "https://api.github.com/repos/$1/releases/latest" 2>/dev/null |
    sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -n1)"
  case "$t" in v[0-9]*) echo "$t"; return 0 ;; esac
  t="$(curl -fsSLI --retry 2 --connect-timeout 20 -o /dev/null -w '%{url_effective}' \
    "https://github.com/$1/releases/latest" 2>/dev/null | sed 's#.*/##')"
  case "$t" in v[0-9]*) echo "$t" ;; esac
}
ask() { # ask "question" → 0 for yes (default yes). No terminal / --yes → yes.
  [ "$ASSUME_YES" = 1 ] && return 0
  [ "$TTY_IN" = 1 ] || return 0
  local a
  printf '    %s?%s %s [Y/n] ' "$B" "$OFF" "$1" >/dev/tty
  read -r a </dev/tty || return 0
  case "$a" in n | N | no | NO) return 1 ;; *) return 0 ;; esac
}
with_timeout() { # with_timeout SECS cmd…
  local s="$1"; shift
  if have timeout; then timeout "$s" "$@"
  elif have gtimeout; then gtimeout "$s" "$@"
  else "$@"; fi
}

usage() { sed -n '2,/^# ──.*──$/p;' "$0" 2>/dev/null | sed -n '3,60p' | sed 's/^#  \{0,2\}//'; }

# ── arguments ────────────────────────────────────────────────────────────────
parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
    install | clone | update) ;; # clone/update: accepted for the old one-liner
    check | doctor | --check | -c) MODE="check" ;;
    uninstall | --uninstall) MODE="uninstall" ;;
    --minimal) PROFILE="minimal" ;;
    --full) PROFILE="full" ;;
    -y | --yes) ASSUME_YES=1 ;;
    -n | --dry-run) DRY=1 ;;
    --no-packages) DO_PKGS=0 ;;
    --no-fonts) DO_FONTS=0 ;;
    --no-plugins) DO_PLUGINS=0 ;;
    --no-lsp) DO_LSP=0 ;;
    --no-parsers) DO_PARSERS=0 ;;
    --no-shell-rc) DO_RC=0 ;;
    --repo) REPO_URL="${2:?--repo needs a URL}"; shift ;;
    --repo=*) REPO_URL="${1#*=}" ;;
    --branch) BRANCH="${2:?--branch needs a name}"; shift ;;
    --branch=*) BRANCH="${1#*=}" ;;
    --dir) CONFIG_DIR="${2:?--dir needs a path}"; shift ;;
    --dir=*) CONFIG_DIR="${1#*=}" ;;
    -h | --help) usage; exit 0 ;;
    *) die "unknown option: $1 (try --help)" ;;
    esac
    shift
  done
  [ "$MODE" = check ] && DRY=1
  [ "$MODE" = check ] && ASSUME_YES=1
  return 0
}

# ── platform ─────────────────────────────────────────────────────────────────
OS=""; ARCH=""; DISTRO=""; PM=""; MUSL=0; SESSION=""
detect_platform() {
  case "$(uname -s)" in
  Linux) OS=linux ;;
  Darwin) OS=macos ;;
  *) die "unsupported OS: $(uname -s) (Linux and macOS only; on Windows use WSL)" ;;
  esac
  case "$(uname -m)" in
  x86_64 | amd64) ARCH=x86_64 ;;
  aarch64 | arm64) ARCH=arm64 ;;
  *) ARCH="$(uname -m)" ;;
  esac
  if [ "$OS" = linux ]; then
    local id="" like=""
    if [ -r /etc/os-release ]; then
      id="$(. /etc/os-release; echo "${ID:-}")"
      like="$(. /etc/os-release; echo "${ID_LIKE:-}")"
    fi
    DISTRO="${id:-linux}"
    case " $id $like " in
    *" arch "* | *" manjaro "* | *" endeavouros "*) PM=pacman ;;
    *" debian "* | *" ubuntu "*) PM=apt ;;
    *" fedora "* | *" rhel "* | *" centos "*) PM=dnf ;;
    *" suse "* | *" opensuse"*) PM=zypper ;;
    *" alpine "*) PM=apk ;;
    *" void "*) PM=xbps ;;
    esac
    if [ -z "$PM" ]; then # unknown distro: go by what is installed
      for p in pacman apt-get dnf zypper apk xbps-install; do
        have "$p" && { PM="${p%-get}"; PM="${PM%-install}"; break; }
      done
      [ "$PM" = xbps ] || true
    fi
    { ldd --version 2>&1 | grep -qi musl; } && MUSL=1
    grep -qi microsoft /proc/version 2>/dev/null && DISTRO="$DISTRO (WSL)"
  else
    DISTRO="macOS $(sw_vers -productVersion 2>/dev/null)"
    if have brew; then PM=brew
    elif [ -x /opt/homebrew/bin/brew ]; then eval "$(/opt/homebrew/bin/brew shellenv)"; PM=brew
    elif [ -x /usr/local/bin/brew ]; then eval "$(/usr/local/bin/brew shellenv)"; PM=brew
    fi
  fi
  # What kind of desktop session (decides the clipboard helper).
  if [ "$OS" = macos ]; then SESSION=mac
  elif [ -n "${WAYLAND_DISPLAY:-}" ] || [ "${XDG_SESSION_TYPE:-}" = wayland ]; then SESSION=wayland
  elif [ -n "${DISPLAY:-}" ]; then SESSION=x11
  elif [ -n "${SSH_CONNECTION:-}" ] || [ -f /.dockerenv ] || [ -f /run/.containerenv ]; then SESSION=headless
  else SESSION=unknown
  fi
}

# Package names per package manager. Empty = no package; a user-space fallback
# (or a manual note) takes over.
pkgs_for() { # pkgs_for TOOL
  case "$1:$PM" in
  git:*) echo git ;;
  curl:*) echo curl ;;
  unzip:*) echo unzip ;;
  xz:apt) echo xz-utils ;;
  xz:*) echo xz ;;
  cc:apt) echo build-essential ;;
  cc:pacman) echo gcc ;;
  cc:dnf | cc:zypper) echo gcc gcc-c++ ;;
  cc:apk) echo build-base ;;
  cc:xbps) echo base-devel ;;
  make:*) echo make ;;
  rg:*) echo ripgrep ;;
  fd:apt | fd:dnf) echo fd-find ;;
  fd:*) echo fd ;;
  node:zypper) echo nodejs-default npm-default ;;
  node:brew) echo node ;;
  node:*) echo nodejs npm ;;
  npm:*) ;; # comes with node above
  python3:pacman | python3:brew) echo python ;;
  python3:*) echo python3 ;;
  clip:*)
    case "$SESSION" in
    wayland | unknown) echo wl-clipboard ;;
    x11) echo xclip ;;
    esac ;;
  nvim:pacman | nvim:brew | nvim:apk | nvim:dnf | nvim:zypper | nvim:xbps) echo neovim ;;
  tree-sitter:pacman | tree-sitter:brew) echo tree-sitter-cli ;;
  xdg-open:apt | xdg-open:pacman | xdg-open:dnf | xdg-open:zypper | xdg-open:apk | xdg-open:xbps) echo xdg-utils ;;
  typst:pacman | typst:brew | typst:apk) echo typst ;;
  lazygit:pacman | lazygit:brew | lazygit:dnf | lazygit:apk | lazygit:xbps) echo lazygit ;;
  go:apt) echo golang-go ;;
  go:pacman | go:brew | go:dnf | go:apk | go:xbps) echo go ;;
  go:zypper) echo go ;;
  zathura:apt) echo zathura zathura-pdf-poppler ;;
  zathura:pacman | zathura:dnf | zathura:zypper | zathura:apk | zathura:xbps) echo zathura zathura-pdf-mupdf ;;
  latexmk:pacman) echo texlive-basic texlive-latex texlive-latexrecommended texlive-latexextra texlive-fontsrecommended texlive-binextra ;;
  latexmk:apt) echo latexmk texlive-latex-recommended texlive-latex-extra texlive-fonts-recommended ;;
  latexmk:dnf) echo latexmk texlive-collection-latexrecommended ;;
  latexmk:zypper) echo texlive-latexmk texlive-collection-latexrecommended ;;
  biber:pacman | biber:apt) echo biber ;;
  biber:dnf | biber:zypper) echo texlive-biber ;;
  qutebrowser:*) [ "$OS" = linux ] && echo qutebrowser ;;
  esac
}

# cmd(s) to look for | tier | why.  tier: core / std (standard+full) / full
TOOLS='git|git|core|clones plugins, gitsigns, the dashboard branch
curl|curl|core|downloads parsers, servers and fonts
unzip|unzip|core|Mason unpacks its packages with it
xz|xz|core|unpacks .tar.xz archives (typst, node)
cc|cc gcc clang|core|compiles tree-sitter parsers and native plugins
make|make gmake|core|native plugin builds
rg|rg|core|Telescope live_grep
fd|fd fdfind|core|Telescope find_files
node|node|core|LSP servers, Mason, markdown-preview
npm|npm|core|markdown-preview build, Mason npm packages
python3|python3|core|bin/livehtml (HTML preview), pyright
clip|wl-copy xclip xsel pbcopy|core|system clipboard (clipboard=unnamedplus)
nvim|nvim|core|the editor itself
tree-sitter|tree-sitter|core|builds tree-sitter parsers (nvim-treesitter main branch)
xdg-open|xdg-open open|std|opens previews in the real browser
typst|typst|std|Typst preview and compile
lazygit|lazygit|std|git TUI
go|go|std|gopls and goimports (Mason builds them)
zathura|zathura|full|PDF viewer for LaTeX and Typst
latexmk|latexmk|full|LaTeX build (bin/texbuild covers when absent)
biber|biber|full|biblatex bibliographies
qutebrowser|qutebrowser|full|chrome-less preview window (bin/mdpreview)'

tier_wanted() {
  case "$1:$PROFILE" in
  core:*) return 0 ;;
  std:standard | std:full) return 0 ;;
  full:full) return 0 ;;
  esac
  return 1
}

nvim_version() { # prints e.g. 0.11.4 (empty when no nvim)
  have nvim || return 0
  nvim --version 2>/dev/null | head -n1 | sed -n 's/^NVIM v\([0-9][0-9.]*\).*/\1/p'
}
node_major() { have node && node -v 2>/dev/null | sed -n 's/^v\([0-9]*\).*/\1/p'; }
go_version() { have go && go version 2>/dev/null | sed -n 's/.*go\([0-9][0-9.]*\).*/\1/p'; }

# Is TOOL satisfied right now? (handles minimum versions)
tool_ok() {
  case "$1" in
  nvim) local v; v="$(nvim_version)"; [ -n "$v" ] && ver_ge "$v" "$MIN_NVIM" ;;
  node) local m; m="$(node_major)"; [ -n "$m" ] && [ "$m" -ge "$MIN_NODE" ] ;;
  go) local g; g="$(go_version)"; [ -n "$g" ] && ver_ge "$g" "$MIN_GO" ;;
  cc) have_any "cc gcc clang" && { [ "$OS" != macos ] || xcode-select -p >/dev/null 2>&1; } ;;
  *) have_any "$2" ;;
  esac
}

# ── system packages ──────────────────────────────────────────────────────────
SUDO=""; APT_UPDATED=0
setup_sudo() {
  [ "$(id -u)" -eq 0 ] && return 0
  [ "$PM" = brew ] && return 0
  if have sudo; then
    if sudo -n true 2>/dev/null; then SUDO=sudo
    elif [ "$TTY_IN" = 1 ]; then
      info "sudo is needed to install system packages"
      sudo -v </dev/tty && SUDO=sudo
    fi
  elif have doas; then SUDO=doas; fi
  if [ "$SUDO" = sudo ]; then # keep the credentials warm during long installs
    ( while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) 2>/dev/null &
    SUDO_KEEPALIVE=$!
  fi
  [ -n "$SUDO" ]
}
can_install_pkgs() { [ -n "$PM" ] && [ "$DO_PKGS" = 1 ] && { [ "$(id -u)" -eq 0 ] || [ "$PM" = brew ] || [ -n "$SUDO" ]; }; }

pm_install() { # pm_install pkg…
  case "$PM" in
  pacman) $SUDO pacman -S --needed --noconfirm "$@" ;;
  apt)
    if [ "$APT_UPDATED" = 0 ]; then $SUDO env DEBIAN_FRONTEND=noninteractive apt-get update && APT_UPDATED=1; fi
    $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@" ;;
  dnf) $SUDO dnf install -y "$@" ;;
  zypper) $SUDO zypper --non-interactive install "$@" ;;
  apk) $SUDO apk add "$@" ;;
  xbps) $SUDO xbps-install -Sy "$@" ;;
  brew) brew install "$@" ;;
  esac
}

# ── tools: plan, then install ────────────────────────────────────────────────
MISSING=""   # "tool" names that are not satisfied
PKG_LIST=""
plan_tools() {
  local cmds tier why tool pk
  MISSING=""; PKG_LIST=""
  while IFS='|' read -r tool cmds tier why; do
    tier_wanted "$tier" || continue
    # the clipboard helper only matters on a desktop
    if [ "$tool" = clip ] && { [ "$SESSION" = headless ] || [ "$SESSION" = mac ]; }; then continue; fi
    # fd ships as `fdfind` on Debian/Ubuntu: a symlink fixes it, no package needed
    if [ "$tool" = fd ] && ! have fd && have fdfind; then
      MISSING="$MISSING fd-link"; warn "$(printf "%-13s" fd) is called fdfind here — will link it"; continue
    fi
    if tool_ok "$tool" "$cmds"; then
      case "$tool" in
      nvim) ok "$(trow nvim "v$(nvim_version)  $(command -v nvim)")" ;;
      node) ok "$(trow node "$(node -v)  $(command -v node)")" ;;
      go) ok "$(trow go "v$(go_version)")" ;;
      *) ok "$(trow "$tool" "$(command -v $cmds 2>/dev/null | head -n1)")" ;;
      esac
      continue
    fi
    case "$tool" in
    nvim) have nvim && warn "$(printf '%-13s' nvim)v$(nvim_version) is older than $MIN_NVIM — will upgrade" || warn "$(printf '%-13s' nvim)missing  ${DIM}$why${OFF}" ;;
    node) have node && warn "$(printf '%-13s' node)$(node -v) is older than v$MIN_NODE — will upgrade" || warn "$(printf '%-13s' node)missing  ${DIM}$why${OFF}" ;;
    go) have go && warn "$(printf '%-13s' go)v$(go_version) is older than $MIN_GO — will upgrade" || warn "$(printf '%-13s' go)missing  ${DIM}$why${OFF}" ;;
    *) case "$tier" in core) bad "$(printf '%-13s' "$tool")missing  ${DIM}$why${OFF}" ;; *) warn "$(printf '%-13s' "$tool")missing  ${DIM}$why${OFF}" ;; esac ;;
    esac
    MISSING="$MISSING $tool"
    pk="$(pkgs_for "$tool")"
    case " $PKG_LIST " in *" $pk "*) ;; *) PKG_LIST="$PKG_LIST $pk" ;; esac
  done <<EOF
$TOOLS
EOF
  # `bad` above only reports: whatever gets fixed later is not a failure yet
  N_BAD=0; N_WARN=0; PROBLEMS=""
}

install_packages() {
  [ -n "$MISSING" ] || return 0
  if [ -z "${PKG_LIST// /}" ]; then return 0; fi
  if [ "$PM" = "" ]; then
    warn "no supported package manager found — cannot install:$PKG_LIST"; return 0
  fi
  if [ "$DO_PKGS" = 0 ]; then skip "--no-packages: leaving system packages alone"; return 0; fi
  if [ "$DRY" = 1 ]; then info "would install with $PM:$PKG_LIST"; return 0; fi
  if [ "$PM" = brew ] && ! have brew; then return 0; fi
  setup_sudo
  if ! can_install_pkgs; then
    warn "no permission to install system packages (no root/sudo)"
    todo "install with your package manager ($PM):$PKG_LIST"
    return 0
  fi
  info "$PM install:$PKG_LIST"
  if ! ask "Install these packages?"; then warn "skipped by request"; return 0; fi
  # shellcheck disable=SC2086
  if ! step "installing ${PKG_LIST# } ($PM)" pm_install $PKG_LIST; then
    warn "the batch failed — retrying one package at a time"
    local p
    for p in $PKG_LIST; do step_soft "$p" pm_install "$p"; done
    [ "$PM" = pacman ] && todo "pacman could not find a package? refresh the db: sudo pacman -Syu"
  fi
  N_BAD=0; PROBLEMS="" # re-judged by the final check
}

# ── user-space installers (no root; used when the distro lacks a good package) ─
install_nvim_release() {
  local asset
  [ "$MUSL" = 1 ] && { echo "musl libc: no official Neovim build"; return 1; }
  case "$OS-$ARCH" in
  linux-x86_64) asset=nvim-linux-x86_64 ;;
  linux-arm64) asset=nvim-linux-arm64 ;;
  macos-arm64) asset=nvim-macos-arm64 ;;
  macos-x86_64) asset=nvim-macos-x86_64 ;;
  *) echo "no Neovim release for $OS-$ARCH"; return 1 ;;
  esac
  local base="https://github.com/neovim/neovim/releases/latest/download"
  dl "$base/$asset.tar.gz" "$TMP/nvim.tgz" || return 1
  if dl "$base/shasum.txt" "$TMP/nvim.sha" 2>/dev/null; then
    local want got
    want="$(grep " $asset.tar.gz\$" "$TMP/nvim.sha" | awk '{print $1}')"
    got="$( (sha256sum "$TMP/nvim.tgz" 2>/dev/null || shasum -a 256 "$TMP/nvim.tgz") | awk '{print $1}')"
    if [ -n "$want" ] && [ "$want" != "$got" ]; then echo "checksum mismatch"; return 1; fi
  fi
  rm -rf "$TMP/nvim-x" "$OPT_DIR/nvim"; mkdir -p "$TMP/nvim-x" "$OPT_DIR" "$BIN_DIR"
  tar -xzf "$TMP/nvim.tgz" -C "$TMP/nvim-x" || return 1
  mv "$TMP/nvim-x/$asset" "$OPT_DIR/nvim" || return 1
  ln -sfn "$OPT_DIR/nvim/bin/nvim" "$BIN_DIR/nvim"
  "$BIN_DIR/nvim" --version | head -n1
}

install_treesitter_cli() {
  local asset
  case "$OS-$ARCH" in
  linux-x86_64) asset=tree-sitter-linux-x64 ;;
  linux-arm64) asset=tree-sitter-linux-arm64 ;;
  macos-arm64) asset=tree-sitter-macos-arm64 ;;
  macos-x86_64) asset=tree-sitter-macos-x64 ;;
  esac
  mkdir -p "$BIN_DIR"
  if [ -n "$asset" ] && [ "$MUSL" = 0 ] &&
    dl "https://github.com/tree-sitter/tree-sitter/releases/latest/download/$asset.gz" "$TMP/ts.gz" &&
    gunzip -c "$TMP/ts.gz" >"$BIN_DIR/tree-sitter" && chmod +x "$BIN_DIR/tree-sitter" &&
    "$BIN_DIR/tree-sitter" --version; then
    return 0
  fi
  rm -f "$BIN_DIR/tree-sitter"
  echo "release binary unusable — trying npm"
  have npm && npm install -g --prefix "$HOME/.local" tree-sitter-cli && "$BIN_DIR/tree-sitter" --version
}

install_typst_release() {
  local triple
  case "$OS-$ARCH" in
  linux-x86_64) triple=x86_64-unknown-linux-musl ;;
  linux-arm64) triple=aarch64-unknown-linux-musl ;;
  macos-arm64) triple=aarch64-apple-darwin ;;
  macos-x86_64) triple=x86_64-apple-darwin ;;
  *) return 1 ;;
  esac
  have xz || return 1
  dl "https://github.com/typst/typst/releases/latest/download/typst-$triple.tar.xz" "$TMP/typst.txz" || return 1
  rm -rf "$TMP/typst-x"; mkdir -p "$TMP/typst-x" "$BIN_DIR"
  tar -xJf "$TMP/typst.txz" -C "$TMP/typst-x" || return 1
  install -m 0755 "$TMP/typst-x/typst-$triple/typst" "$BIN_DIR/typst" && "$BIN_DIR/typst" --version
}

install_lazygit_release() {
  local tag os arch
  tag="$(gh_latest_tag jesseduffield/lazygit)"; [ -n "$tag" ] || return 1
  case "$OS" in linux) os=Linux ;; macos) os=Darwin ;; esac
  case "$ARCH" in x86_64) arch=x86_64 ;; arm64) arch=arm64 ;; *) return 1 ;; esac
  dl "https://github.com/jesseduffield/lazygit/releases/download/$tag/lazygit_${tag#v}_${os}_${arch}.tar.gz" "$TMP/lg.tgz" || return 1
  rm -rf "$TMP/lg-x"; mkdir -p "$TMP/lg-x" "$BIN_DIR"
  tar -xzf "$TMP/lg.tgz" -C "$TMP/lg-x" lazygit || return 1
  install -m 0755 "$TMP/lg-x/lazygit" "$BIN_DIR/lazygit" && "$BIN_DIR/lazygit" --version | head -n1
}

install_go_release() {
  [ "$OS" = linux ] && [ "$MUSL" = 0 ] || return 1
  local v goarch
  v="$(curl -fsSL --retry 3 'https://go.dev/VERSION?m=text' | head -n1)"; [ -n "$v" ] || return 1
  case "$ARCH" in x86_64) goarch=amd64 ;; arm64) goarch=arm64 ;; *) return 1 ;; esac
  dl "https://go.dev/dl/$v.linux-$goarch.tar.gz" "$TMP/go.tgz" || return 1
  rm -rf "$TMP/go-x" "$OPT_DIR/go"; mkdir -p "$TMP/go-x" "$OPT_DIR" "$BIN_DIR"
  tar -xzf "$TMP/go.tgz" -C "$TMP/go-x" || return 1
  mv "$TMP/go-x/go" "$OPT_DIR/go" || return 1
  ln -sfn "$OPT_DIR/go/bin/go" "$BIN_DIR/go"; ln -sfn "$OPT_DIR/go/bin/gofmt" "$BIN_DIR/gofmt"
  "$BIN_DIR/go" version
}

install_node_release() {
  [ "$MUSL" = 0 ] || return 1
  local os arch name base="https://nodejs.org/dist/latest-v22.x"
  case "$OS" in linux) os=linux ;; macos) os=darwin ;; esac
  case "$ARCH" in x86_64) arch=x64 ;; arm64) arch=arm64 ;; *) return 1 ;; esac
  dl "$base/SHASUMS256.txt" "$TMP/node.sha" || return 1
  name="$(grep -o "node-v[0-9.]*-$os-$arch.tar.gz" "$TMP/node.sha" | head -n1)"; [ -n "$name" ] || return 1
  dl "$base/$name" "$TMP/node.tgz" || return 1
  local want got
  want="$(grep " $name\$" "$TMP/node.sha" | awk '{print $1}')"
  got="$( (sha256sum "$TMP/node.tgz" 2>/dev/null || shasum -a 256 "$TMP/node.tgz") | awk '{print $1}')"
  [ "$want" = "$got" ] || { echo "checksum mismatch"; return 1; }
  rm -rf "$TMP/node-x" "$OPT_DIR/node"; mkdir -p "$TMP/node-x" "$OPT_DIR" "$BIN_DIR"
  tar -xzf "$TMP/node.tgz" -C "$TMP/node-x" || return 1
  mv "$TMP/node-x/${name%.tar.gz}" "$OPT_DIR/node" || return 1
  local b
  for b in node npm npx; do ln -sfn "$OPT_DIR/node/bin/$b" "$BIN_DIR/$b"; done
  "$BIN_DIR/node" -v
}

link_fd() { mkdir -p "$BIN_DIR" && ln -sfn "$(command -v fdfind)" "$BIN_DIR/fd"; }

# After the package manager had its go, fix what is still missing or too old.
fallback_installs() {
  [ -n "$MISSING" ] || return 0
  todo() { [ "$DRY" = 1 ] || MANUAL="$MANUAL
$1"; }
  local t
  for t in $MISSING; do
    case "$t" in
    fd-link) step "link fdfind as fd" link_fd ;;
    nvim)
      tool_ok nvim && continue
      step "install Neovim (official release)" install_nvim_release || {
        todo "install Neovim >= $MIN_NVIM by hand: https://github.com/neovim/neovim/blob/master/INSTALL.md"; } ;;
    tree-sitter)
      tool_ok tree-sitter tree-sitter && continue
      step "install tree-sitter-cli" install_treesitter_cli || {
        todo "install tree-sitter-cli (npm i -g tree-sitter-cli, or cargo install tree-sitter-cli)"; } ;;
    typst)
      have typst && continue
      step_soft "install typst (official release)" install_typst_release || todo "install typst: https://github.com/typst/typst" ;;
    lazygit)
      have lazygit && continue
      step_soft "install lazygit (official release)" install_lazygit_release || todo "install lazygit: https://github.com/jesseduffield/lazygit" ;;
    go)
      tool_ok go && continue
      step_soft "install Go (official release)" install_go_release || todo "install Go >= $MIN_GO (gopls and goimports need it)" ;;
    node)
      tool_ok node && continue
      step "install Node.js (official release)" install_node_release || todo "install Node.js >= $MIN_NODE" ;;
    zathura | latexmk | biber | qutebrowser)
      if ! have "$t"; then
        case "$OS:$t" in
        macos:zathura) todo "zathura on macOS: brew tap zegervdv/zathura && brew install zathura zathura-pdf-mupdf" ;;
        macos:latexmk) todo "LaTeX on macOS: brew install --cask basictex  (or mactex-no-gui)" ;;
        *) todo "$t: no package for $PM — install it by hand (optional)" ;;
        esac
      fi ;;
    esac
  done
  hash -r 2>/dev/null
  # the first nvim in PATH might still be an old system one
  if have nvim && [ -x "$BIN_DIR/nvim" ] && [ "$(command -v nvim)" != "$BIN_DIR/nvim" ]; then
    todo "an older nvim at $(command -v nvim) shadows the new one — open a new shell (PATH now starts with ~/.local/bin)"
  fi
}

ensure_brew() {
  [ "$OS" = macos ] && [ -z "$PM" ] && [ "$DO_PKGS" = 1 ] || return 0
  warn "Homebrew is not installed"
  if [ "$DRY" = 1 ]; then info "would install Homebrew"; return 0; fi
  if ask "Install Homebrew (https://brew.sh)?"; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/null >>"$LOG" 2>&1
    for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do [ -x "$b" ] && eval "$("$b" shellenv)" && PM=brew && break; done
    [ "$PM" = brew ] && ok "Homebrew installed" || bad "Homebrew install failed"
  fi
}

check_xcode_clt() {
  [ "$OS" = macos ] || return 0
  xcode-select -p >/dev/null 2>&1 && return 0
  [ "$DRY" = 1 ] && return 0
  warn "Xcode command line tools missing — a dialog will ask to install them"
  xcode-select --install >>"$LOG" 2>&1
  todo "finish the Xcode command line tools dialog, then run this script again"
}

# ── the config repo ──────────────────────────────────────────────────────────
norm_url() { # git@github.com:a/b.git → https://github.com/a/b
  echo "$1" | sed -e 's#^git@github.com:#https://github.com/#' -e 's#^ssh://git@github.com/#https://github.com/#' \
    -e 's#\.git$##' -e 's#/$##' | tr 'A-Z' 'a-z'
}

ensure_config() {
  local real="$CONFIG_DIR" url
  [ -L "$CONFIG_DIR" ] && real="$(abs_dir "$CONFIG_DIR")"
  if [ -d "$real/.git" ]; then
    url="$(git -C "$real" remote get-url origin 2>/dev/null)"
    if [ "$(norm_url "$url")" = "$(norm_url "$REPO_URL")" ]; then
      ok "config is a checkout of $(norm_url "$REPO_URL" | sed 's#https://github.com/##') — $real"
      [ "$DRY" = 1 ] && return 0
      [ -n "$BRANCH" ] && git -C "$real" checkout "$BRANCH" >>"$LOG" 2>&1
      # --autostash: Lazy rewrites lazy-lock.json; that must never block an update
      step_soft "pull the latest config (local edits are kept)" git -C "$real" pull --ff-only --autostash
      return 0
    fi
  fi
  if [ -e "$CONFIG_DIR" ] || [ -L "$CONFIG_DIR" ]; then
    if [ -d "$CONFIG_DIR" ] && [ -z "$(ls -A "$CONFIG_DIR" 2>/dev/null)" ]; then
      :
    else
      local bak="$CONFIG_DIR.bak-$(date +%Y%m%d-%H%M%S)"
      warn "$CONFIG_DIR is a different config — moving it to $bak"
      [ "$DRY" = 1 ] || mv "$CONFIG_DIR" "$bak" || { bad "could not move $CONFIG_DIR"; return 1; }
    fi
  fi
  if [ "$DRY" = 1 ]; then info "would clone $REPO_URL → $CONFIG_DIR"; return 0; fi
  mkdir -p "$(dirname "$CONFIG_DIR")"
  local args=""; [ -n "$BRANCH" ] && args="--branch $BRANCH"
  # shellcheck disable=SC2086
  step "clone $REPO_URL" git clone $args "$REPO_URL" "$CONFIG_DIR"
}

# ── helper scripts, PATH ─────────────────────────────────────────────────────
link_bin() {
  local src name dst
  [ -d "$CONFIG_DIR/bin" ] || { [ "$DRY" = 1 ] || warn "no bin/ in the config"; return 0; }
  [ "$DRY" = 1 ] || mkdir -p "$BIN_DIR"
  for src in "$CONFIG_DIR"/bin/*; do
    [ -f "$src" ] || continue
    name="$(basename "$src")"; dst="$BIN_DIR/$name"
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then warn "$dst exists and is not a link — left alone"; continue; fi
    if [ "$DRY" = 1 ]; then info "would link bin/$name → $dst"; continue; fi
    chmod +x "$src"; ln -sfn "$src" "$dst" && ok "bin/$name $S_ARR $dst"
  done
}

RC_MARK="# >>> nvim-setup (tonycth7/nvim) >>>"
RC_END="# <<< nvim-setup <<<"
add_rc_block() { # add_rc_block FILE
  local f="$1"
  grep -qF "$RC_MARK" "$f" 2>/dev/null && return 0
  {
    printf '\n%s\n' "$RC_MARK"
    printf 'case "$PATH" in "$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac\n'
    printf '%s\n' "$RC_END"
  } >>"$f"
}
setup_shell_rc() {
  [ "$DO_RC" = 1 ] || return 0
  case "$ORIG_PATH" in "$BIN_DIR":*) skip "$HOME/.local/bin already leads your PATH"; return 0 ;; esac
  [ "$DRY" = 1 ] && { info "would add ~/.local/bin to PATH in your shell rc files"; return 0; }
  local f done_any=0 sh="${SHELL##*/}"
  for f in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$f" ] || { [ "$f" = "$HOME/.bashrc" ] && [ "$sh" = bash ]; } || { [ "$f" = "$HOME/.zshrc" ] && [ "$sh" = zsh ]; }; then
      add_rc_block "$f" && { ok "PATH in ${f/#$HOME/~}"; done_any=1; }
    fi
  done
  if [ -d "$HOME/.config/fish" ]; then
    mkdir -p "$HOME/.config/fish/conf.d"
    printf 'fish_add_path -m %s\n' "$BIN_DIR" >"$HOME/.config/fish/conf.d/nvim-setup.fish" && { ok "PATH in fish config"; done_any=1; }
  fi
  [ "$done_any" = 1 ] && todo "open a new terminal (or: source ~/.bashrc) so ~/.local/bin is on PATH"
  return 0
}

# ── Nerd Font ────────────────────────────────────────────────────────────────
nerd_font_present() {
  if have fc-list; then fc-list 2>/dev/null | grep -qi "nerd font\|NerdFont\|Nerd Font Mono"; return; fi
  ls "$HOME/Library/Fonts" /Library/Fonts 2>/dev/null | grep -qi nerd
}
install_font_linux() {
  local dst="$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
  dl "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" "$TMP/font.zip" || return 1
  rm -rf "$dst"; mkdir -p "$dst"
  unzip -qo "$TMP/font.zip" -d "$dst" '*.ttf' || return 1
  rm -f "$dst"/*Windows* 2>/dev/null
  have fc-cache && fc-cache -f "$dst"
  return 0
}
setup_font() {
  [ "$DO_FONTS" = 1 ] || { skip "--no-fonts"; return 0; }
  if [ "$SESSION" = headless ]; then
    skip "remote/container session — install a Nerd Font on the machine you read the terminal on"
    todo "set your terminal font to a Nerd Font (e.g. JetBrainsMono Nerd Font): https://www.nerdfonts.com"; return 0
  fi
  if grep -qi microsoft /proc/version 2>/dev/null; then
    warn "WSL: fonts belong to Windows — install a Nerd Font there and select it in Windows Terminal"
    todo "install a Nerd Font on Windows: https://www.nerdfonts.com"; return 0
  fi
  if nerd_font_present; then skip "a Nerd Font is already installed"; return 0; fi
  if [ "$DRY" = 1 ]; then info "would install JetBrainsMono Nerd Font"; return 0; fi
  if [ "$OS" = macos ]; then
    [ "$PM" = brew ] && step_soft "JetBrainsMono Nerd Font (brew cask)" brew install --cask font-jetbrains-mono-nerd-font
  else
    have unzip && step_soft "JetBrainsMono Nerd Font → ~/.local/share/fonts" install_font_linux
  fi
  todo "choose "JetBrainsMono Nerd Font" as the font in your terminal's settings — without it icons show as boxes"
}

# ── plugins, LSP servers, parsers (headless Neovim) ──────────────────────────
nvim_headless() { # nvim_headless args… (stdout+stderr → caller)
  with_timeout 1800 nvim --headless "$@" </dev/null
}

plugins_complete() {
  cat >"$TMP/plug.lua" <<'LUA'
local n = 0
for _, p in ipairs(require("lazy").plugins()) do if not p._.installed then n = n + 1 end end
print("PLUGINS_MISSING " .. n)
vim.cmd("qa!")
LUA
  nvim_headless -c "luafile $TMP/plug.lua" 2>&1 | grep -q "PLUGINS_MISSING 0"
}

restore_plugins() {
  [ "$DO_PLUGINS" = 1 ] || { skip "--no-plugins"; return 0; }
  have nvim || { bad "no usable nvim — plugin step skipped"; return 1; }
  if [ "$DRY" = 1 ]; then info "would run :Lazy! restore"; return 0; fi
  if [ -f "$CONFIG_DIR/lazy-lock.json" ]; then
    # the first start also bootstraps lazy.nvim itself; early noise is expected
    step "restore the plugins pinned in lazy-lock.json" nvim_headless "+Lazy! restore" +qa
    # a flaky network can leave one plugin behind: look, and try once more
    if ! plugins_complete; then
      step_soft "retry the plugins that did not install" nvim_headless "+Lazy! restore" +qa
    fi
  else
    step "install plugins (no lock file)" nvim_headless "+Lazy! sync" +qa
  fi
}

mason_install() {
  [ "$DO_LSP" = 1 ] || { skip "--no-lsp"; return 0; }
  have nvim || return 0
  if [ "$DRY" = 1 ]; then info "would install via Mason: $MASON_PKGS"; return 0; fi
  local pk="$MASON_PKGS"
  have go || pk="$(echo " $pk " | sed -e 's/ gopls / /' -e 's/ goimports / /')"
  have go || todo "no Go found: gopls and goimports were skipped (install Go, then :MasonInstall gopls goimports)"
  cat >"$TMP/mason.lua" <<LUA
local pkgs = vim.split("$pk", " ", { trimempty = true })
pcall(function() require("lazy").load({ plugins = { "mason.nvim" } }) end)
local ok, reg = pcall(require, "mason-registry")
if not ok then print("MASON_FATAL mason-registry not loadable") vim.cmd("qa!") end
local fresh, fresh_ok, fresh_err = false, false, nil
reg.refresh(function(success, detail) fresh, fresh_ok, fresh_err = true, success, detail end)
vim.wait(180000, function() return fresh end, 200)
if not fresh_ok and #reg.get_all_package_names() == 0 then
  print("MASON_FATAL registry unavailable: " .. vim.inspect(fresh_err):gsub("%s+", " "))
  vim.cmd("qa!")
end
local ok_n, failed, handles = {}, {}, {}
for _, name in ipairs(pkgs) do
  local g, pkg = pcall(reg.get_package, name)
  if not g then
    print("MASON_SKIP " .. name .. " (not in registry)")
  elseif pkg:is_installed() then
    ok_n[#ok_n + 1] = name
  else
    local s, h = pcall(function() return pkg:install() end)
    if s and h then handles[name] = { pkg = pkg, h = h } else failed[#failed + 1] = name end
  end
end
vim.wait(1500000, function()
  for _, e in pairs(handles) do if not e.h:is_closed() then return false end end
  return true
end, 500)
for name, e in pairs(handles) do
  if e.pkg:is_installed() then ok_n[#ok_n + 1] = name else failed[#failed + 1] = name end
end
print("MASON_RESULT ok=" .. #ok_n .. " failed=" .. table.concat(failed, ","))
vim.cmd("qa!")
LUA
  local out="$TMP/mason.out" rc
  step_soft "Mason: language servers & formatters (takes a few minutes)" bash -c "$(declare -f with_timeout nvim_headless have); nvim_headless -c 'luafile $TMP/mason.lua' >'$out' 2>&1"
  rc=$?
  cat "$out" >>"$LOG" 2>/dev/null
  local res; res="$(grep -h MASON_RESULT "$out" 2>/dev/null | tail -n1)"
  case "$res" in
  "") grep -q MASON_FATAL "$out" 2>/dev/null && warn "Mason registry unreachable — LSP servers not installed" || warn "Mason produced no result — open nvim and run :Mason" ;;
  *"failed=") ok "Mason: ${res#MASON_RESULT }" ;;
  *) warn "Mason: ${res#MASON_RESULT }"; todo "retry the failed Mason packages inside nvim:  :Mason" ;;
  esac
  grep -h "MASON_SKIP\|MASON_FATAL" "$out" 2>/dev/null | cut -c1-200 | sed 's/^/        /'
  if grep -q MASON_FATAL "$out" 2>/dev/null; then
    todo "Mason could not reach its registry (needs api.github.com + github.com). Later, inside nvim: :MasonInstall $MASON_PKGS"
  fi
  return 0
}

treesitter_install() {
  [ "$DO_PARSERS" = 1 ] || { skip "--no-parsers"; return 0; }
  have nvim || return 0
  if [ "$DRY" = 1 ]; then info "would install tree-sitter parsers"; return 0; fi
  if ! have_any "cc gcc clang" || ! have tree-sitter; then
    warn "parsers need a C compiler and tree-sitter-cli — skipped"; return 0
  fi
  cat >"$TMP/ts.lua" <<LUA
local langs = vim.split("$TS_LANGS", " ", { trimempty = true })
pcall(function() require("lazy").load({ plugins = { "nvim-treesitter" } }) end)
local ok, ts = pcall(require, "nvim-treesitter")
if not ok then print("TS_FATAL nvim-treesitter not loadable") vim.cmd("qa!") end
if ts.install then
  local t = ts.install(langs)
  if t and t.wait then t:wait(1500000) end
else
  vim.cmd("TSInstallSync " .. table.concat(langs, " "))
end
local missing = {}
for _, l in ipairs(langs) do
  if #vim.api.nvim_get_runtime_file("parser/" .. l .. ".*", false) == 0 then missing[#missing + 1] = l end
end
print("TS_RESULT total=" .. #langs .. " missing=" .. table.concat(missing, ","))
vim.cmd("qa!")
LUA
  local out="$TMP/ts.out"
  step_soft "tree-sitter parsers (compiles each one)" bash -c "$(declare -f with_timeout nvim_headless have); nvim_headless -c 'luafile $TMP/ts.lua' >'$out' 2>&1"
  cat "$out" >>"$LOG" 2>/dev/null
  local res; res="$(grep -h TS_RESULT "$out" 2>/dev/null | tail -n1)"
  case "$res" in
  *"missing=") ok "parsers: ${res#TS_RESULT }" ;;
  "") warn "tree-sitter step produced no result — see the log" ;;
  *) warn "parsers: ${res#TS_RESULT }  (they install on first use too)" ;;
  esac
  return 0
}

# ── verification ─────────────────────────────────────────────────────────────
verify() {
  have nvim || return 0
  [ "$DRY" = 1 ] && return 0
  # starting nvim would install plugins, which --no-plugins asked us not to do
  [ "$DO_PLUGINS" = 1 ] || { skip "--no-plugins: not starting Neovim"; return 0; }
  cat >"$TMP/verify.lua" <<'LUA'
local miss = {}
local ok, lazy = pcall(require, "lazy")
if ok then
  for _, p in ipairs(lazy.plugins()) do if not p._.installed then miss[#miss + 1] = p.name end end
  print("VERIFY plugins=" .. #lazy.plugins() .. " missing=" .. table.concat(miss, ","))
else
  print("VERIFY lazy_not_loaded")
end
vim.cmd("qa!")
LUA
  local out="$TMP/verify.out"
  nvim_headless -c "luafile $TMP/verify.lua" >"$out" 2>&1
  cat "$out" >>"$LOG"
  local res; res="$(grep -h '^VERIFY' "$out" | tail -n1)"
  local noise; noise="$(tr '\r' '\n' <"$out" | grep -v '^VERIFY' | grep -vE '\] +(clone|build|update|log|install) +\||Running task|Finished task' | sed '/^[[:space:]]*$/d')"
  case "$res" in
  "VERIFY plugins="*"missing=") ok "all plugins installed (${res#VERIFY plugins=})" ;;
  "") bad "Neovim did not start cleanly" ;;
  *) bad "plugins missing: ${res#*missing=}" ;;
  esac
  if [ -n "$noise" ]; then
    warn "Neovim printed messages while starting:"
    printf '%s\n' "$noise" | head -n 12 | sed 's/^/        /'
  else
    ok "Neovim starts without errors"
  fi
  # the config's own :checkhealth
  nvim_headless "+checkhealth config" "+w! $TMP/health.txt" "+qa!" >>"$LOG" 2>&1
  if [ -s "$TMP/health.txt" ]; then
    local e w; e="$(grep -c 'ERROR' "$TMP/health.txt")"; w="$(grep -c 'WARNING' "$TMP/health.txt")"
    if [ "$e" -gt 0 ]; then
      warn ":checkhealth config — $e error(s), $w warning(s):"
      grep 'ERROR' "$TMP/health.txt" | head -n 8 | sed 's/^[ -]*/        /'
    else
      ok ":checkhealth config — no errors ($w optional warning(s))"
    fi
  fi
}

# ── uninstall ────────────────────────────────────────────────────────────────
do_uninstall() {
  section "Uninstall"
  local f l
  for l in "$BIN_DIR"/*; do
    [ -L "$l" ] || continue
    case "$(readlink "$l")" in "$CONFIG_DIR"/bin/* | "$OPT_DIR"/*) rm -f "$l" && ok "removed link ${l/#$HOME/~}" ;; esac
  done
  for f in "$HOME/.bashrc" "$HOME/.zshrc"; do
    [ -f "$f" ] && grep -qF "$RC_MARK" "$f" &&
      { sed -i.bak "/$(printf '%s' "$RC_MARK" | sed 's#[][\.*^$/]#\\&#g')/,/$(printf '%s' "$RC_END" | sed 's#[][\.*^$/]#\\&#g')/d" "$f" && rm -f "$f.bak" && ok "PATH block removed from ${f/#$HOME/~}"; }
  done
  rm -f "$HOME/.config/fish/conf.d/nvim-setup.fish"
  for l in nvim go node; do [ -d "$OPT_DIR/$l" ] && ask "Remove $OPT_DIR/$l (installed by this script)?" && rm -rf "${OPT_DIR:?}/$l" && ok "removed $OPT_DIR/$l"; done
  local data="${XDG_DATA_HOME:-$HOME/.local/share}/nvim" state="${XDG_STATE_HOME:-$HOME/.local/state}/nvim" cache="${XDG_CACHE_HOME:-$HOME/.cache}/nvim"
  if [ "$ASSUME_YES" = 0 ] && [ "$TTY_IN" = 1 ] && ask "Delete plugins/LSP data ($data, $state, $cache)?"; then
    rm -rf "$data" "$state" "$cache" && ok "plugin, LSP and cache data deleted"
  else
    skip "plugin data kept (run with a terminal to be asked; or delete $data yourself)"
  fi
  if [ -e "$CONFIG_DIR" ] && ask "Move the config $CONFIG_DIR aside (to .removed-<time>)?"; then
    mv "$CONFIG_DIR" "$CONFIG_DIR.removed-$(date +%Y%m%d-%H%M%S)" && ok "config moved aside"
  fi
  echo; echo "Done. Packages installed with $PM are left in place."
}

# ── main ─────────────────────────────────────────────────────────────────────
main() {
  parse_args "$@"
  detect_platform
  [ "$MODE" = uninstall ] && { do_uninstall; return 0; }

  banner

  [ "$OS" = macos ] && [ "$MODE" != check ] && { ensure_brew; check_xcode_clt; }

  section "Checking tools"
  plan_tools

  if [ "$MODE" = check ]; then
    section "Config"
    if [ -d "$CONFIG_DIR/.git" ]; then ok "config present: $CONFIG_DIR"; else warn "no config at $CONFIG_DIR yet"; fi
    section "Plugins"
    local d="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
    if [ -d "$d/lazy" ]; then ok "$(ls -1 "$d/lazy" | wc -l | tr -d ' ') plugins in $d/lazy"; else warn "no plugins installed yet"; fi
    [ -d "$d/mason/bin" ] && ok "Mason: $(ls -1 "$d/mason/bin" | wc -l | tr -d ' ') tools" || warn "no Mason tools yet"
    printf '\n    %s--check: nothing was changed.%s  Missing: %s\n' "$DIM" "$OFF" "${MISSING:-nothing}"
    return 0
  fi

  if [ -n "$MISSING" ]; then
    section "Installing"
    install_packages
    fallback_installs
  fi

  section "Config"
  ensure_config || return 1

  section "Helper scripts and PATH"
  link_bin
  setup_shell_rc

  section "Nerd Font"
  setup_font

  if have nvim; then
    section "Plugins"
    restore_plugins
    section "Language servers and formatters"
    mason_install
    section "Tree-sitter parsers"
    treesitter_install
    section "Verifying"
    verify
  elif [ "$DRY" = 0 ]; then
    bad "Neovim is still not available — plugin, LSP and parser steps skipped"
  fi

  # ── summary ────────────────────────────────────────────────────────────────
  local core_missing="" tool cmds tier why
  while IFS='|' read -r tool cmds tier why; do
    [ "$tier" = core ] || continue
    [ "$tool" = clip ] && continue
    [ "$tool" = xz ] && continue
    tool_ok "$tool" "$cmds" || core_missing="$core_missing $tool"
  done <<EOF
$TOOLS
EOF
  [ "$DRY" = 1 ] && core_missing=""
  local col head
  if [ "$DRY" = 1 ]; then col="$CYN"; head="Dry run — nothing was changed"
  elif [ -z "$core_missing" ] && [ "$N_BAD" -eq 0 ]; then col="$GRN"; head="$S_OK  All set"
  else col="$RED"; head="$S_BAD  Needs attention"; fi
  local V="$col$BX_V$OFF"
  printf '\n  %s%s%s %s%s%s %s\n' "$col" "$BX_TL" "$BX_H" "$B" "$head" "$OFF" "$(rule 40)"
  printf '  %s\n' "$V"
  if [ -n "$core_missing" ]; then printf '  %s  %s%s%s missing: %s\n' "$V" "$RED" "$S_BAD" "$OFF" "${core_missing# }"; fi
  if [ -n "$PROBLEMS" ]; then printf '%s\n' "$PROBLEMS" | sed '/^$/d' | sed "s/^      - /  $V  ${RED}$S_BAD${OFF} /"; fi
  if [ "$DRY" = 0 ] && [ -z "$core_missing" ] && [ "$N_BAD" -eq 0 ]; then
    printf '  %s  %sstart%s     %snvim%s\n' "$V" "$DIM" "$OFF" "$B" "$OFF"
  fi
  printf '  %s  %sconfig%s    %s\n' "$V" "$DIM" "$OFF" "$(short "$CONFIG_DIR")"
  printf '  %s  %skeys%s      %s\n' "$V" "$DIM" "$OFF" "$(short "$CONFIG_DIR")/CHEATSHEET.md"
  printf '  %s  %shealth%s    :checkhealth config  %s(inside nvim)%s\n' "$V" "$DIM" "$OFF" "$DIM" "$OFF"
  printf '  %s  %supdate%s    run this script again — it pulls and restores pinned plugins\n' "$V" "$DIM" "$OFF"
  if [ "$N_WARN" -gt 0 ]; then
    printf '  %s  %s%s%s  %d warning(s) %s— details above%s\n' "$V" "$YEL" "$S_WARN" "$OFF" "$N_WARN" "$DIM" "$OFF"
  fi
  if [ -n "$MANUAL" ]; then
    printf '  %s\n  %s  %sLeft to do by hand%s\n' "$V" "$V" "$B" "$OFF"
    printf '%s\n' "$MANUAL" | sed '/^$/d' | sed "s/^ */  $V   ${ACC}$S_ARR${OFF} /"
  fi
  printf '  %s\n  %s%s%s\n\n' "$V" "$col" "$BX_BL$(rule 46 | sed 's/\x1b\[[0-9;]*m//g')" "$OFF"
  [ -n "$core_missing" ] && return 1
  return 0
}

# Everything above only defines things; nothing has run yet. If a `curl | bash`
# download is cut off, the file never reaches this line and nothing half-runs.
main "$@"
exit $?
