-- ---------------------------------------------------------------------------
-- autocmds — every autocommand, grouped by purpose
-- ---------------------------------------------------------------------------
-- Each block is its own augroup, so `:autocmd General`, `:autocmd Prose` and
-- `:autocmd LSP` each show one concern. Autocommands that only make sense
-- while a certain plugin is loaded live next to that plugin (lua/plugins/).
--
-- Two globals are published for the editor rows of the :Settings panel:
--   vim.g.autoformat   format on save      (lua/features/settings.lua)
--   vim.g.prose_spell  spell in prose files
--   vim.g.inlay_hints  LSP inlay hints

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Format-on-save toggle (off by default; toggle with <leader>uf)
vim.g.autoformat = false

--------------------------------------------------------------
-- GENERAL SETTINGS GROUP
--------------------------------------------------------------
local general = augroup("General", { clear = true })

-- Return to last cursor position when opening a file
autocmd("BufReadPost", {
  group = general,
  desc = "Return to last edit position",
  pattern = "*",
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lc = mark[1]
    local lc2 = vim.api.nvim_buf_line_count(0)
    if lc > 0 and lc <= lc2 then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Highlight on yank
autocmd("TextYankPost", {
  group = general,
  desc = "Highlight on yank",
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 })
  end,
})

-- Remove trailing whitespace on save (skip filetypes where it is meaningful)
autocmd("BufWritePre", {
  group = general,
  desc = "Remove trailing whitespace",
  pattern = "*",
  callback = function(args)
    local ft = vim.bo[args.buf].filetype
    if vim.tbl_contains({ "markdown", "gitcommit", "diff" }, ft) then
      return
    end
    local save_cursor = vim.fn.getpos(".")
    pcall(function()
      vim.cmd([[keeppatterns %s/\s\+$//e]])
    end)
    vim.fn.setpos(".", save_cursor)
  end,
})

-- Auto-create missing parent directories on save
autocmd("BufWritePre", {
  group = general,
  desc = "Create parent dirs on save",
  pattern = "*",
  callback = function(args)
    local name = vim.api.nvim_buf_get_name(args.buf)
    if name == "" or name:match("^%w+://") then
      return
    end
    local dir = vim.fn.fnamemodify(name, ":p:h")
    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, "p")
    end
  end,
})

-- Resize splits when window is resized
autocmd("VimResized", {
  group = general,
  desc = "Equalize splits on resize",
  pattern = "*",
  command = "tabdo wincmd =",
})

-- Close certain buffers with q
autocmd("FileType", {
  group = general,
  desc = "Map q to quit on special buffers",
  pattern = {
    "help", "man", "qf", "lspinfo", "oil", "neo-tree",
    "startuptime", "tsplayground", "PlenaryTestPopup", "trouble",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = event.buf, silent = true })
  end,
})

-- Terminal buffers: no line numbers / signcolumn clutter
autocmd("TermOpen", {
  group = general,
  desc = "Terminal buffer options",
  pattern = "*",
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
    vim.opt_local.spell = false
    vim.opt_local.list = false
  end,
})

-- YAML: real tabs only for makefiles
autocmd("FileType", {
  group = general,
  desc = "Makefiles use tabs",
  pattern = "make",
  callback = function()
    vim.opt_local.expandtab = false
  end,
})

--------------------------------------------------------------
-- PROSE / WRITING GROUP (Markdown, LaTeX, Typst, ...)
--------------------------------------------------------------
local prose = augroup("Prose", { clear = true })

autocmd("FileType", {
  group = prose,
  desc = "Soft-wrap + spell for prose filetypes",
  pattern = { "markdown", "text", "gitcommit", "rst", "asciidoc", "org", "tex", "plaintex", "typst" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
    -- Settings → Editor → "Spell check in prose" (vim.g.prose_spell)
    vim.opt_local.spell = vim.g.prose_spell ~= false
    vim.opt_local.spelllang = "en_us"
    vim.opt_local.list = false
  end,
})

autocmd("FileType", {
  group = prose,
  desc = "Typst comment string",
  pattern = "typst",
  callback = function()
    vim.opt_local.commentstring = "// %s"
  end,
})

--------------------------------------------------------------
-- LSP GROUP
--------------------------------------------------------------
local lsp = augroup("LSP", { clear = true })

-- Enable LSP inlay hints (Neovim 0.10+)
autocmd("LspAttach", {
  group = lsp,
  desc = "Enable inlay hints on LSP attach",
  callback = function(args)
    if vim.g.inlay_hints == false then -- Settings → Editor → "LSP inlay hints"
      return
    end
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client:supports_method("textDocument/inlayHint") then
      vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
    end
  end,
})

-- Optional format-on-save (toggle with <leader>uf)
autocmd("BufWritePre", {
  group = lsp,
  desc = "Format on save (when enabled)",
  pattern = "*",
  callback = function(args)
    if not vim.g.autoformat then
      return
    end
    local ft = vim.bo[args.buf].filetype
    if vim.tbl_contains({
      "lua", "python", "go", "rust", "javascript", "typescript",
      "javascriptreact", "typescriptreact", "css", "html", "json",
      "yaml", "typst", "sh", "c", "cpp",
    }, ft) then
      pcall(vim.lsp.buf.format, { bufnr = args.buf, timeout_ms = 3000 })
    end
  end,
})
