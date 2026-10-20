-- ---------------------------------------------------------------------------
-- :checkhealth config — is this machine ready for this config?
-- ---------------------------------------------------------------------------
-- setup.sh installs everything listed here; this is the same list, inside the
-- editor, for after a fresh install or when something stops working.
--
-- Neovim finds this automatically because of where it sits:
-- lua/config/health.lua  ->  :checkhealth config

local M = {}

-- What the editor itself leans on. `cmd` is what we look for on PATH,
-- `pkg` is the Arch package that provides it, `why` shows up in the report.
local core = {
  { "git", "git", "clones plugins, gitsigns, the dashboard's branch" },
  { "rg", "ripgrep", "telescope live_grep" },
  { "fd", "fd", "telescope find_files" },
  { "node", "nodejs", "LSP servers, markdown-preview's build step" },
  { "python3", "python", "bin/livehtml (HTML preview), pyright" },
  { "gcc", "gcc", "treesitter parsers, native plugin builds" },
  { "make", "make", "native plugin builds" },
  { "wl-copy", "wl-clipboard", "clipboard sync (Settings -> Editor)" },
  { "curl", "curl", "downloading parsers and language servers" },
  { "unzip", "unzip", "mason unpacks its packages with it" },
}

-- Only some features need these; a warn here is not a broken editor.
local optional = {
  { "typst", "typst", "Typst preview (<leader>tv)" },
  { "zathura", "zathura", "PDF viewer for LaTeX and Typst" },
  { "sioyek", "sioyek-git", "alternative PDF viewer (Settings -> Viewers)" },
  { "latexmk", "texlive-binextra", "continuous LaTeX; bin/texbuild takes over without it" },
  { "biber", "texlive-bibtexextra", "bibliographies with biblatex" },
  { "qutebrowser", "qutebrowser", "chrome-less preview window (bin/mdpreview)" },
  { "firefox", "firefox", "fallback for bin/mdpreview" },
}

-- Shipped with the config itself (setup.sh links them into ~/.local/bin).
local shipped = {
  { "livehtml", "the HTML live server" },
  { "mdpreview", "the chrome-less browser launcher" },
  { "texbuild", "the LaTeX multi-pass wrapper" },
}

function M.check()
  vim.health.start("config — environment")

  -- Neovim itself
  local v = vim.version()
  local msg = string.format("Neovim %d.%d.%d (%s)", v.major, v.minor, v.patch, jit and jit.version or "no LuaJIT")
  if vim.fn.has("nvim-0.11") == 1 then
    vim.health.ok(msg)
  else
    vim.health.error(msg, "this config assumes Neovim 0.11+ (vim.lsp.config, vim.lsp.inlay_hint)")
  end

  -- The scripts in bin/, and where the features will find them
  vim.health.start("config — helper scripts (bin/)")
  local bin_dir = vim.fn.stdpath("config") .. "/bin"
  if vim.fn.isdirectory(bin_dir) == 0 then
    vim.health.error(bin_dir .. " is missing", "the previews would have nothing to run")
  end
  local on_path = {}
  for _, s in ipairs(shipped) do
    local path = require("config.bin").path(s[1])
    if vim.fn.executable(path) == 1 then
      vim.health.ok(string.format("%s — %s", s[1], path))
    else
      vim.health.error(string.format("%s (for %s) not found", s[1], s[2]), "run ./setup.sh in the config directory")
    end
    if vim.fn.exepath(s[1]) == "" then
      on_path[#on_path + 1] = s[1]
    end
  end
  if #on_path > 0 then
    vim.health.info(
      "not on PATH: " .. table.concat(on_path, ", ")
        .. " — only needed outside Neovim; ./setup.sh links them into ~/.local/bin"
    )
  end

  -- Tools on PATH
  vim.health.start("config — tools on PATH (Arch package in brackets)")
  for _, t in ipairs(core) do
    if vim.fn.executable(t[1]) == 1 then
      vim.health.ok(string.format("%s — %s", t[1], t[3]))
    else
      vim.health.error(string.format("%s missing — %s", t[1], t[3]), "sudo pacman -S " .. t[2])
    end
  end
  for _, t in ipairs(optional) do
    if vim.fn.executable(t[1]) == 1 then
      vim.health.ok(string.format("%s (optional) — %s", t[1], t[3]))
    else
      vim.health.warn(string.format("%s (optional) missing — %s", t[1], t[3]), "sudo pacman -S " .. t[2])
    end
  end

  -- Plugins and the lock file (how reproducible this install is)
  vim.health.start("config — plugins")
  local ok, stats = pcall(function()
    return require("lazy").stats()
  end)
  if ok then
    vim.health.ok(string.format("%d plugins loaded of %d, %.0f ms startup", stats.loaded, stats.count, stats.startuptime))
  else
    vim.health.error("lazy.nvim is not loaded", "run ./setup.sh or :Lazy")
  end
  local lock = vim.fn.stdpath("config") .. "/lazy-lock.json"
  if vim.fn.filereadable(lock) == 1 then
    vim.health.ok("lazy-lock.json present — :Lazy restore reproduces these revisions")
  else
    vim.health.warn("no lazy-lock.json", "run :Lazy sync, then keep the file with the config")
  end

  -- Choices made in the :Settings panel
  vim.health.start("config — settings")
  local state = vim.fn.stdpath("state") .. "/settings.json"
  if vim.fn.filereadable(state) == 1 then
    local on = 0
    for _, v in pairs(require("features.settings").all()) do
      if v then
        on = on + 1
      end
    end
    vim.health.ok(string.format("%s — %d toggles on (:Settings / <leader>uS)", state, on))
  else
    vim.health.info("no settings.json yet — the panel writes it the first time you toggle something")
  end
end

return M
