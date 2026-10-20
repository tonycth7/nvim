# Neovim cheatsheet

`<leader>` = **Space**. Config lives in `~/.config/nvim` — see `README.md` for
where each part of it lives (and `./setup.sh` for a new machine).

---

## Files & search (Telescope)

| Key | Action |
| --- | --- |
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>fs` | Grep word under cursor |
| `<leader>fb` | Open buffers |
| `<leader>fr` | Recent files |
| `<leader>fh` | Help tags |
| `<leader>fk` | Keymaps |
| `<leader>fc` | Commands |
| `<leader>fd` | Diagnostics |
| `<leader>e`  | Toggle file explorer (neo-tree) |
| `:Ex`       | Netrw explorer (`:Explore`, `:Vex`, `:Sex` also work) |

## Buffers

| Key | Action |
| --- | --- |
| `<leader>bn` / `<leader>bp` | Next / previous buffer |
| `<leader>bd` | Delete buffer |
| `<leader>bl` | List buffers |
| `<leader>bo` | Close all *other* buffers |

## Windows

| Key | Action |
| --- | --- |
| `<C-h/j/k/l>` | Move between splits (also works in terminal) |
| `<leader>sv` / `<leader>sh` | Split vertical / horizontal |
| `<leader>se` | Equalize splits |
| `<leader>sx` | Close current split |
| `<C-Up/Down/Left/Right>` | Resize split |

## Save & quit

| Key | Action |
| --- | --- |
| `<leader>w` / `<leader>ww` | Save |
| `<leader>wq` / `<leader>qw` | Save & quit |
| `<leader>qq` | Quit all |
| `<Esc>` | Clear search highlight |

## Editing

| Key | Action |
| --- | --- |
| `<A-j>` / `<A-k>` | Move line (or selection) down / up |
| `<C-d>` / `<C-u>` | Half-page down / up, centred |
| `n` / `N` | Next / prev search, centred |
| `p` (visual) | Paste without clobbering register |
| `gcc` / `gc` / `gb` | Toggle comment |
| `ys{motion}{char}` | **surround**: add (e.g. `ysiw"`) |
| `cs{old}{new}` | **surround**: change (e.g. `cs"'`) |
| `ds{char}` | **surround**: delete |
| `s` | **flash**: jump anywhere on screen |
| `S` | **flash**: select treesitter node and jump |
| `f/F/t/T` | Jump with flash labels (`;` / `,` repeat) |

## LSP (buffer-local once a server attaches)

| Key | Action |
| --- | --- |
| `<leader>ld` | Go to definition |
| `<leader>lD` | Go to type definition |
| `<leader>lL` | Go to declaration |
| `<leader>li` | Go to implementation |
| `<leader>lr` | References |
| `<leader>lh` | Hover docs |
| `<leader>ls` | Signature help |
| `<leader>lo` / `<leader>lw` | Document / workspace symbols |
| `<leader>la` | Code action |
| `<leader>lrn` | Rename symbol |
| `<leader>lf` | Format buffer |
| `<leader>ldd` | Show line diagnostics |
| `<leader>ldp` / `<leader>ldn` | Previous / next diagnostic |

## Diagnostics & todos

| Key | Action |
| --- | --- |
| `<leader>xx` | Diagnostics panel (Trouble) |
| `<leader>xX` | Buffer diagnostics |
| `<leader>xs` | Symbols |
| `<leader>xl` | LSP refs / defs panel |
| `<leader>xq` | Quickfix list |
| `<leader>xt` | TODO comments (Trouble) |
| `<leader>st` | TODO comments (Telescope) |

## Messages

| Key | Action |
| --- | --- |
| `<leader>snh` | Message history |
| `<leader>snl` | Last message |
| `<leader>snd` | Dismiss messages |

## New from template

| Key | Action |
| --- | --- |
| `<leader>nt` | New from template — picker (Markdown, LaTeX, Typst, Rust, Python, C, C++, Go, Shell, HTML) |
| `<leader>nm` | New Markdown document |
| `<leader>nl` | New LaTeX document |
| `<leader>nT` | New Typst document |

## LaTeX (VimTeX)

| Key | Action |
| --- | --- |
| `<leader>ll` | Compile (continuous) |
| `<leader>lv` | View PDF in Zathura (SyncTeX) |
| `<leader>lk` | Stop compilation |
| `<leader>lc` | Clean auxiliary files |
| `<leader>le` | Show errors |
| `<leader>lt` | Toggle table of contents |
| `<leader>lI` | VimTeX info |

Note: VimTeX's red *"Syntax highlighting is controlled by Treesitter!"*
notice is filtered out (`vimtex_log_ignore`) — your LaTeX highlighting comes
from Tree-sitter. It is still recorded in `:VimtexLog`.

A **compile starts automatically** when you open a `.tex` file (VimTeX
`VimtexEventInitPost`), and **every `:w` recompiles** — so with `zathura` open
(which reloads a changed PDF by itself) you get a **live preview**:
`<leader>ll` + `<leader>lv`, then just write. (`texlive-binextra`'s `latexmk`
would make this truly continuous in the background.)

## Typst

| Key | Action |
| --- | --- |
| `<leader>tv` | **Live preview**: `typst watch` + Zathura (updates without `:w`) |
| `<leader>tw` | Same as `<leader>tv` |
| `<leader>tp` | Live preview in a browser (chrome-less window) |
| `<leader>tq` | Stop live previews (browser + watch) |
| `<leader>ts` | Document outline (`:Toc`) |

## HTML (live server)

| Key | Action |
| --- | --- |
| `<leader>hp` | Live server: serve the file's directory, open `index.html` if there is one |
| `<leader>hP` | Live server, but always open **this** file |
| `<leader>hq` | Stop the HTML live server |
| `:HtmlPreviewLog` | Show the live server's request log (diagnose 404s) |

Served over real HTTP, so relative `css`/`js`/`img` and `fetch()` work; saving
any file in the tree reloads the browser by itself. The server serves files
**from disk**, so `<leader>hp` writes the buffer first (Settings → HTML); with
that off, save with `:w` yourself. `:HtmlPreviewLog` shows the request log if a
page 404s.

## Markdown / misc / UI

| Key | Action |
| --- | --- |
| `<leader>mp` | Markdown preview in a minimal window (toggles) |
| `<leader>mr` | Render Markdown in place (no browser) |
| `<leader>th` | Pick a colourscheme (persists) |
| `<leader>lg` | Open Lazy |
| `<leader>pm` | Open Mason |
| `<leader>us` | Toggle spell |
| `<leader>uw` | Toggle wrap |
| `<leader>ul` | Toggle invisible chars |
| `<leader>un` | Toggle line numbers |
| `<leader>uc` | Toggle cursorline |
| `<leader>uf` | Toggle format-on-save |
| `<leader>up` | Toggle live preview (autosyncs `.tex`/`.typ` without `:w`) |
| `<leader>uS` | **Settings panel** — every automatic behaviour in one place |
| `<leader>ua` | Cycle the dashboard ASCII art (or `:DashboardArt`) |

The `<leader>u…` toggles above last for the session; the **Settings panel** rows
are the persistent versions of the same ideas (plus the previews).

---

## Notes

- **LaTeX compile**: uses `latexmk` when installed, otherwise the bundled
  `bin/texbuild` wrapper (multi-pass + bibtex/biber/makeindex, linked into
  `~/.local/bin` by `setup.sh`). For the native path:
  `sudo pacman -S texlive-binextra` (provides latexmk).
- **Settings panel** (`:Settings` / `<leader>uS`, or `s` on the dashboard):
  everything that happens "by itself" lives here, in five groups —
  **LaTeX** (compile on open, open the viewer, rebuild on save),
  **Typst** (preview on open), **HTML** (live server on open, save before
  serving), **Viewers** (Zathura or Sioyek; chrome-less window or a normal
  browser) and **Editor** (live sync, format-on-save, line numbers, relative
  numbers, wrapping, spell, invisible characters, clipboard, undo, inlay
  hints). Saved in `stdpath("state")/settings.json`; `<CR>` toggles, `R`
  restores defaults, `q` closes. `:SettingsReset` does the same from the
  command line.
- **Health check**: `:checkhealth config` reports the external tools this
  config shells out to, the `bin/` helper scripts, the plugin count and
  `lazy-lock.json` — the same list `./setup.sh --check` prints, so a fresh
  machine can be verified from either side.
- **Live preview** (`.tex` / `.typ`): about a second after you stop typing the
  buffer is quietly written to disk (`lua/features/preview/live.lua`). That write triggers
  the compile, and Zathura's own file monitor reloads the PDF — so the preview
  keeps up **without `:w`**. Toggle with `<leader>up` or `:LivePreview`; "live"
  appears in the statusline while it is on. The autosync deliberately skips the
  `BufWritePre` hooks, so it never strips the space you are about to type after.
- **PDFs opening as a black window?** Zathura needs a rendering backend:
  `sudo pacman -S zathura-pdf-mupdf` (or `zathura-pdf-poppler`). Without one,
  zathura reports "Could not determine file type" and shows nothing.
- **Typst**: `<leader>tv`/`<leader>tw` start `typst watch` in the background and
  open the PDF in Zathura once it exists (`lua/features/preview/typst.lua`); `<leader>tq`
  stops it. `<leader>tp` is the browser preview and needs `websocat`.
- **LSP servers** are managed by Mason (`:Mason`): lua_ls, ts_ls, pyright,
  gopls, rust_analyzer, texlab, tinymist, marksman.
- **Format-on-save** is off by default; enable per session with `<leader>uf`.
- **Treesitter** highlighting is started for every filetype with a parser
  (including LaTeX and Typst); rainbow brackets come from rainbow-delimiters.
- **Markdown preview**: `<leader>mr` renders the document *in place* (headings,
  tables, checkboxes, code blocks) with no browser at all. `<leader>mp` opens
  the browser preview in a chrome-less window — no tabs, no search/URL bar — via
  `bin/mdpreview` (qutebrowser; falls back to `firefox --kiosk`, then
  `xdg-open`). Under niri it tiles next to Neovim. PDFs (LaTeX/Typst) go to
  zathura/sioyek, which also tile beside the editor. `<leader>mp` only applies
  in a markdown buffer — elsewhere it just warns (use `<leader>mr` there).
  Settings → Viewers swaps the chrome-less window for your real browser.
- **Dashboard art**: the header shows your `brand` (`AS|`) by default. Press `a`
  on the dashboard (or `<leader>ua`) to cycle, `:DashboardArt <name>` to pin one
  (`brand`, `moon`, `tux`, `arch`, `neovim`, `hydra`, `saturn`, `doom`),
  `:DashboardArt random` for a random pick, `:DashboardArt list` to list them.
  Your pick is remembered in `~/.local/state/nvim/dashboard_art`; delete that
  file to fall back to `brand`.
- **Dashboard layout**: uses a compact theme (`lua/dashboard/theme/compact.lua`)
  that draws one line per entry instead of the stock `doom` theme's blank line
  after every entry. Menu: Find File, Live Grep, New File, **Template**
  (`require("features.templates").pick()`), Config, **Settings** (`s` → the toggles
  panel), Cheat Sheet, New Art, Plugins, Mason,
  Quit. Below it are your **Recent** files and the **Projects** (git
  repositories) you have been working in; the footer shows the plugin count, the
  current **git branch**, and the time.
