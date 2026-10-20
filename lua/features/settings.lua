-- ---------------------------------------------------------------------------
-- settings — one panel for all the "happens by itself" behaviours
-- ---------------------------------------------------------------------------
--
--   :Settings        or  <leader>uS      (also the "Settings" entry on the dashboard)
--
-- <CR> toggles the row under the cursor, R restores the defaults, q closes.
-- Choices are persisted in stdpath("state")/settings.json and applied
-- immediately — no restart, and no editing of this file to change your mind.
--
-- These toggles are the single source of truth for the preview modules:
-- lua/features/preview/live.lua, lua/features/preview/typst.lua and lua/features/preview/html.lua read
-- them instead of hardcoding "on". The Editor rows set real options (see
-- M.apply) and the prose/LSP autocommands consult the globals it publishes.

local M = {}

local STATE = vim.fn.stdpath("state") .. "/settings.json"
local CHROMELESS = require("config.bin").path("mdpreview")
local PROSE = {
  "markdown", "text", "gitcommit", "rst", "asciidoc", "org", "tex", "plaintex", "typst",
}

-- The panel, in order. `default` is used on first run and by `R`.
-- Every default matches what the config did before this panel existed, so
-- opening the panel and walking away changes nothing.
local schema = {
  {
    section = "LaTeX",
    items = {
      {
        key = "latex_compile_on_open",
        label = "Compile when a .tex opens",
        default = true,
        desc = "Build the PDF as soon as a document loads",
      },
      {
        key = "latex_auto_view",
        label = "Open the PDF viewer by itself",
        default = false,
        desc = "Zathura opens after the first build (<leader>lv)",
      },
      {
        key = "latex_compile_on_save",
        label = "Rebuild on save",
        default = true,
        desc = "Also fires after a live-sync write",
      },
    },
  },
  {
    section = "Typst",
    items = {
      {
        key = "typst_preview_on_open",
        label = "Preview when a .typ opens",
        default = false,
        desc = "typst watch + the PDF viewer (<leader>tv)",
      },
    },
  },
  {
    section = "HTML",
    items = {
      {
        key = "html_server_on_open",
        label = "Live server when .html opens",
        default = false,
        desc = "Local http server + auto-reload (<leader>hp)",
      },
      {
        key = "html_write_first",
        label = "Save before the server starts",
        default = true,
        desc = "A brand-new HTML file would otherwise 404",
      },
    },
  },
  {
    section = "Viewers",
    items = {
      {
        key = "pdf_sioyek",
        label = "Use Sioyek as the PDF viewer",
        default = false,
        desc = "Off = Zathura; for the LaTeX and Typst previews",
      },
      {
        key = "browser_previews",
        label = "Previews in a normal browser",
        default = false,
        desc = "Markdown/HTML; off = the chrome-less window",
      },
    },
  },
  {
    section = "Editor",
    items = {
      {
        key = "live_sync",
        label = "Live sync (rebuild without :w)",
        default = true,
        desc = "Write .tex/.typ a moment after you pause",
      },
      {
        key = "format_on_save",
        label = "Format on save",
        default = false,
        desc = "Run the formatter on every write",
      },
      {
        key = "line_numbers",
        label = "Show line numbers",
        default = true,
        desc = "Absolute number on the cursor line",
      },
      {
        key = "relative_numbers",
        label = "Relative line numbers",
        default = true,
        desc = "Number the distance, for jumps like 5j",
      },
      {
        key = "wrap_long_lines",
        label = "Wrap long lines",
        default = true,
        desc = "Prose filetypes always wrap regardless",
      },
      {
        key = "spell_check",
        label = "Spell check in prose",
        default = true,
        desc = "markdown, tex, typst, gitcommit, ...",
      },
      {
        key = "show_invisibles",
        label = "Show invisible characters",
        default = true,
        desc = "Tabs, trailing space, non-breaking space",
      },
      {
        key = "clipboard_sync",
        label = "Sync with system clipboard",
        default = true,
        desc = "Yanks land in the Wayland clipboard",
      },
      {
        key = "persistent_undo",
        label = "Remember undo after closing",
        default = true,
        desc = "undofile: undo survives a restart",
      },
      {
        key = "inlay_hints",
        label = "LSP inlay hints",
        default = true,
        desc = "Types and parameter names shown inline",
      },
    },
  },
}

local state = {}

-- ---------------------------------------------------------------------------
-- state
-- ---------------------------------------------------------------------------

local function defaults()
  local out = {}
  for _, sec in ipairs(schema) do
    for _, it in ipairs(sec.items) do
      out[it.key] = it.default
    end
  end
  return out
end

local function read()
  state = defaults()
  local f = io.open(STATE, "r")
  if not f then
    return
  end
  local ok, data = pcall(vim.json.decode, f:read("*a"))
  f:close()
  if ok and type(data) == "table" then
    for k, v in pairs(data) do
      if state[k] ~= nil and type(v) == "boolean" then
        state[k] = v
      end
    end
  end
end

local function write()
  local f = io.open(STATE, "w")
  if not f then
    return
  end
  f:write(vim.json.encode(state))
  f:close()
end

-- Options that live on a window / in a buffer only take effect for the
-- windows and buffers that already exist if we go and set them there too.
local function win_opt(name, value)
  vim.o[name] = value
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    pcall(function()
      vim.wo[w][name] = value
    end)
  end
end

local function buf_opt(name, value)
  vim.o[name] = value
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    pcall(function()
      vim.bo[b][name] = value
    end)
  end
end

-- Effects that have to touch buffers that are already open (a plain global
-- would only reach buffers opened afterwards).
local after = {
  live_sync = function(on)
    if on then
      pcall(function()
        require("features.preview.live").schedule(nil, 250)
      end)
    end
  end,
  spell_check = function(on)
    -- 'spell' is a *window* option, so this has to walk the windows.
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      local ft = vim.bo[vim.api.nvim_win_get_buf(w)].filetype
      if vim.tbl_contains(PROSE, ft) then
        pcall(function()
          vim.wo[w].spell = on
        end)
      end
    end
  end,
}

function M.get(key)
  return state[key]
end

function M.apply()
  -- read by other modules
  vim.g.live_preview = state.live_sync      -- lua/features/preview/live.lua
  vim.g.autoformat = state.format_on_save   -- lua/autocmds.lua
  vim.g.prose_spell = state.spell_check     -- lua/autocmds.lua (prose group)
  vim.g.inlay_hints = state.inlay_hints     -- lua/autocmds.lua (LSP group)
  -- VimTeX reads this when it opens the viewer, so it can change live.
  vim.g.vimtex_view_automatic = state.latex_auto_view and 1 or 0

  -- editor options
  win_opt("number", state.line_numbers)
  win_opt("relativenumber", state.relative_numbers)
  win_opt("wrap", state.wrap_long_lines)
  win_opt("list", state.show_invisibles)
  buf_opt("undofile", state.persistent_undo)
  vim.o.clipboard = state.clipboard_sync and "unnamedplus" or ""

  -- which program opens the compiled PDF
  local viewer = state.pdf_sioyek and "sioyek" or "zathura"
  vim.g.vimtex_view_method = viewer
  vim.g.vimtex_view_general_viewer = viewer
  vim.g.typst_pdf_viewer = viewer
  pcall(function()
    require("features.preview.typst").set_viewer(viewer)
  end)

  -- the chrome-less window, or whatever the desktop considers the browser
  local opener = CHROMELESS
  if state.browser_previews then
    opener = vim.fn.executable("xdg-open") == 1 and "xdg-open" or "firefox"
  end
  vim.g.mkdp_browser = opener
  pcall(function()
    require("features.preview.html").opts.opener = opener
  end)

  -- inlay hints everywhere at once (LspAttach consults the global too)
  pcall(function()
    vim.lsp.inlay_hint.enable(state.inlay_hints)
  end)
end

function M.set(key, value)
  if state[key] == nil then
    return nil
  end
  state[key] = value and true or false
  M.apply()
  write()
  if after[key] then
    after[key](state[key])
  end
  return state[key]
end

function M.toggle(key)
  return M.set(key, not state[key])
end

function M.reset()
  state = defaults()
  M.apply()
  write()
  for key, fn in pairs(after) do
    pcall(fn, state[key])
  end
  return state
end

-- Every key and its current value (handy in a script or :lua one-liner).
function M.all()
  return vim.deepcopy(state)
end

function M.setup()
  vim.api.nvim_set_hl(0, "SettingsOn", { link = "DiagnosticOk", default = true })
  vim.api.nvim_set_hl(0, "SettingsOff", { link = "Comment", default = true })

  read()
  M.apply()

  vim.api.nvim_create_user_command("Settings", function()
    M.panel()
  end, { desc = "Toggle automatic behaviours" })

  vim.api.nvim_create_user_command("SettingsReset", function()
    M.reset()
    vim.notify("Settings reset to defaults", vim.log.levels.INFO)
  end, { desc = "Reset the settings panel to its defaults" })
end

-- ---------------------------------------------------------------------------
-- panel
-- ---------------------------------------------------------------------------

local ns = vim.api.nvim_create_namespace("settings_panel")
local panel = { buf = nil, rows = {} }

local function draw(buf)
  -- widest label decides the column, so nothing can run into a description
  local col = 0
  for _, sec in ipairs(schema) do
    for _, it in ipairs(sec.items) do
      col = math.max(col, #it.label)
    end
  end
  col = col + 2

  local lines, rows, heads = {}, {}, {}
  for _, sec in ipairs(schema) do
    lines[#lines + 1] = ""
    lines[#lines + 1] = "  " .. sec.section
    heads[#lines] = true
    for _, it in ipairs(sec.items) do
      local on = M.get(it.key)
      lines[#lines + 1] = string.format(
        "    %s  %-" .. col .. "s %s",
        on and "[x]" or "[ ]",
        it.label,
        it.desc
      )
      rows[#lines] = it
    end
  end
  lines[#lines + 1] = ""

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for ln, it in pairs(rows) do
    local on = M.get(it.key)
    vim.api.nvim_buf_add_highlight(buf, ns, on and "SettingsOn" or "SettingsOff", ln - 1, 4, 7)
    if on then
      vim.api.nvim_buf_add_highlight(buf, ns, "SettingsOn", ln - 1, 9, 9 + #it.label)
    end
    vim.api.nvim_buf_add_highlight(buf, ns, "Comment", ln - 1, 9 + col + 1, #lines[ln])
  end
  for ln in pairs(heads) do
    vim.api.nvim_buf_add_highlight(buf, ns, "Title", ln - 1, 2, #lines[ln])
  end
  panel.rows = rows
  return lines
end

function M.panel()
  if panel.buf and vim.api.nvim_buf_is_valid(panel.buf) then
    local w = vim.fn.bufwinid(panel.buf)
    if w ~= -1 then
      vim.api.nvim_set_current_win(w)
      return
    end
  end

  local buf = vim.api.nvim_create_buf(false, true)
  panel.buf = buf
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "settings"

  local lines = draw(buf)

  local width = 0
  for _, l in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(l))
  end
  width = math.min(width + 2, vim.o.columns - 4)
  local height = math.min(#lines, vim.o.lines - 4)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.max(1, math.floor((vim.o.lines - height) / 2) - 1),
    col = math.max(1, math.floor((vim.o.columns - width) / 2)),
    style = "minimal",
    border = "rounded",
    title = " Settings ",
    title_pos = "center",
    footer = " <CR> toggle · q close · R reset ",
    footer_pos = "center",
  })
  vim.wo[win].wrap = false
  vim.wo[win].cursorline = true

  local first = nil
  for ln in pairs(panel.rows) do
    first = (first == nil) and ln or math.min(first, ln)
  end
  if first then
    vim.api.nvim_win_set_cursor(win, { first, 0 })
  end

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  local function act()
    local ln = vim.api.nvim_win_get_cursor(0)[1]
    local it = panel.rows[ln]
    if not it then
      return
    end
    local on = M.toggle(it.key)
    draw(buf)
    vim.api.nvim_win_set_cursor(win, { ln, 0 })
    vim.notify(it.label .. ": " .. (on and "ON" or "OFF"), vim.log.levels.INFO)
  end

  local function map(lhs, fn)
    vim.keymap.set("n", lhs, fn, { buffer = buf, silent = true, nowait = true })
  end
  map("<CR>", act)
  map("<Space>", act)
  map("x", act)
  map("q", close)
  map("<Esc>", close)
  map("R", function()
    M.reset()
    draw(buf)
    vim.notify("Settings reset to defaults", vim.log.levels.INFO)
  end)
end

return M
