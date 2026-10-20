-- ---------------------------------------------------------------------------
-- options — editor options, one block per concern
-- ---------------------------------------------------------------------------
-- Loaded before the plugins so their configs see these values. This is the
-- baseline; anything the :Settings panel can flip is applied from
-- lua/features/settings.lua on top (see its apply()).

local opt = vim.opt
local o = vim.o
local wo = vim.wo
local bo = vim.bo

-- MASON TOOLS ON PATH
-- Mason installs stylua / latexindent / texlab / tinymist / marksman etc.
-- Put its bin dir on PATH early so every tool (incl. Vimtex, Typst) finds them.
local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
if vim.fn.isdirectory(mason_bin) == 1 and not (vim.env.PATH or ""):find(mason_bin, 1, true) then
  vim.env.PATH = mason_bin .. ":" .. (vim.env.PATH or "")
end

-- NETRW stays enabled: it provides :Ex / :Explore / :Vex / :Sex.
-- (neo-tree is still the main explorer — <leader>e.)

-- EDITOR
o.timeoutlen = 500
o.updatetime = 300
o.confirm = true
bo.undofile = true
bo.undolevels = 10000
o.autoread = true
o.shada = "!,'200,<50,s10,h,/100"
o.jumpoptions = "view"
o.inccommand = "nosplit"

-- TAB / INDENT
bo.autoindent = true
bo.expandtab = true
bo.tabstop = 2
bo.softtabstop = 2
bo.shiftwidth = 2
o.shiftround = true
o.formatoptions = "tcqjl"

-- SEARCH
o.ignorecase = true
o.smartcase = true
o.hlsearch = true
o.incsearch = true

-- DISPLAY
o.number = true
o.relativenumber = true
o.numberwidth = 4
wo.cursorline = true
o.cursorlineopt = "number"
wo.signcolumn = "yes"
wo.scrolloff = 8
o.laststatus = 3
o.termguicolors = true
o.showmode = false
o.pumheight = 10
o.pumblend = 10
o.winblend = 10
opt.fillchars = {
  eob = " ",
  fold = " ",
  foldopen = "▾",
  foldclose = "▸",
  foldsep = " ",
  diff = "╱",
  vert = "│",
}

-- Show invisible characters subtly (trailing space, tabs, nbsp)
o.list = true
opt.listchars = { tab = "▸ ", trail = "·", nbsp = "␣", extends = "›", precedes = "‹" }

-- COMPLETION
opt.completeopt = { "menu", "menuone", "noselect" }
pcall(function() opt.completeopt:append("fuzzy") end)
o.wildmenu = true
o.wildmode = "longest:full,full"

-- WINDOWS
o.splitbelow = true
o.splitright = true

-- CLIPBOARD / MOUSE
opt.clipboard = "unnamedplus"
o.mouse = "a"

-- SPELL (enabled per filetype in autocmds)
o.spell = false
o.spelllang = "en_us"
o.spelloptions = "camel"

-- MESSAGES
opt.shortmess:append({ W = true, I = true, c = true, C = true, s = true })
opt.belloff = "all"
o.hidden = true

-- MAPPING
opt.backspace = { "indent", "eol", "start" }

-- LEADER
vim.g.mapleader = " "
vim.g.maplocalleader = " "
