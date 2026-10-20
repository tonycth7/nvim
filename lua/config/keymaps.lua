-- ---------------------------------------------------------------------------
-- keymaps — every keymap this config adds
-- ---------------------------------------------------------------------------
-- Grouped by prefix, mirroring the leader layout in CHEATSHEET.md:
--   <leader>f files · <leader>g git · <leader>l LaTeX · <leader>t Typst
--   <leader>h HTML  · <leader>n new   · <leader>m Markdown · <leader>u toggles
-- Keymaps a plugin sets for itself stay in that plugin's spec (lua/plugins/).

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

--------------------------------------------------------------
-- LEADER KEY
--------------------------------------------------------------
vim.g.mapleader = " "
vim.g.maplocalleader = " "

--------------------------------------------------------------
-- TELESCOPE (lazy: only loads when used)
--------------------------------------------------------------
local function tb(fn)
  return function()
    require("telescope.builtin")[fn]()
  end
end

map("n", "<leader>ff", tb("find_files"), { desc = "Find files" })
map("n", "<leader>fg", tb("live_grep"), { desc = "Live grep" })
map("n", "<leader>fb", tb("buffers"), { desc = "Buffers" })
map("n", "<leader>fh", tb("help_tags"), { desc = "Help tags" })
map("n", "<leader>fs", tb("grep_string"), { desc = "Grep string" })
map("n", "<leader>fr", tb("oldfiles"), { desc = "Recent files" })
map("n", "<leader>fk", tb("keymaps"), { desc = "Keymaps" })
map("n", "<leader>fd", tb("diagnostics"), { desc = "Diagnostics" })
map("n", "<leader>fc", tb("commands"), { desc = "Commands" })

-- Theme picker
map("n", "<leader>th", function() require("features.theme_picker").pick() end, { desc = "Pick theme" })

--------------------------------------------------------------
-- WINDOW NAVIGATION
--------------------------------------------------------------
map("n", "<C-h>", "<C-w>h", opts)
map("n", "<C-j>", "<C-w>j", opts)
map("n", "<C-k>", "<C-w>k", opts)
map("n", "<C-l>", "<C-w>l", opts)

map("n", "<leader>sv", "<C-w>v", opts)  -- vertical split
map("n", "<leader>sh", "<C-w>s", opts)  -- horizontal split
map("n", "<leader>se", "<C-w>=", opts)  -- equalize windows
map("n", "<leader>sx", ":close<CR>", opts)  -- close current window

--------------------------------------------------------------
-- BUFFER NAVIGATION
--------------------------------------------------------------
map("n", "<leader>bn", ":bnext<CR>", opts)
map("n", "<leader>bp", ":bprevious<CR>", opts)
map("n", "<leader>bd", ":bdelete<CR>", opts)
map("n", "<leader>bl", ":buffers<CR>", opts)
map("n", "<leader>bo", function()  -- close other buffers
  local cur = vim.api.nvim_get_current_buf()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if b ~= cur and vim.bo[b].buflisted then
      vim.cmd("bdelete " .. b)
    end
  end
end, { desc = "Close other buffers" })

--------------------------------------------------------------
-- QUIT / SAVE
--------------------------------------------------------------
map("n", "<leader>qq", ":qa<CR>", opts)
map("n", "<leader>qw", ":wq<CR>", opts)
map("n", "<leader>w", ":w<CR>", opts)   -- quick save
map("n", "<leader>ww", ":w<CR>", opts)
map("n", "<leader>wq", ":wq<CR>", opts)

--------------------------------------------------------------
-- MOVE LINES
--------------------------------------------------------------
map("n", "<A-j>", ":m .+1<CR>==", opts)
map("n", "<A-k>", ":m .-2<CR>==", opts)
map("v", "<A-j>", ":m '>+1<CR>gv=gv", opts)
map("v", "<A-k>", ":m '<-2<CR>gv=gv", opts)

--------------------------------------------------------------
-- CLEAR SEARCH HIGHLIGHT
--------------------------------------------------------------
map("n", "<Esc>", ":nohlsearch<CR><Esc>", opts)

--------------------------------------------------------------
-- BETTER INDENT
--------------------------------------------------------------
map("v", "<", "<gv", opts)
map("v", ">", ">gv", opts)

--------------------------------------------------------------
-- KEEP CURSOR CENTERED WHEN PAGING
--------------------------------------------------------------
map("n", "<C-d>", "<C-d>zz", opts)
map("n", "<C-u>", "<C-u>zz", opts)
map("n", "n", "nzzzv", opts)
map("n", "N", "Nzzzv", opts)

--------------------------------------------------------------
-- BETTER PASTE (don't overwrite register)
--------------------------------------------------------------
map("v", "p", '"_dP', opts)

--------------------------------------------------------------
-- ESCAPE FROM TERMINAL
--------------------------------------------------------------
map("t", "<Esc>", "<C-\\><C-n>", opts)
map("t", "<C-h>", "<C-\\><C-n><C-w>h", opts)
map("t", "<C-j>", "<C-\\><C-n><C-w>j", opts)
map("t", "<C-k>", "<C-\\><C-n><C-w>k", opts)
map("t", "<C-l>", "<C-\\><C-n><C-w>l", opts)

--------------------------------------------------------------
-- RESIZE WINDOWS
--------------------------------------------------------------
map("n", "<C-Up>", ":resize -2<CR>", opts)
map("n", "<C-Down>", ":resize +2<CR>", opts)
map("n", "<C-Left>", ":vertical resize -2<CR>", opts)
map("n", "<C-Right>", ":vertical resize +2<CR>", opts)

--------------------------------------------------------------
-- DIAGNOSTICS / TROUBLE
--------------------------------------------------------------
map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", { desc = "Diagnostics (Trouble)" })
map("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", { desc = "Buffer diagnostics" })
map("n", "<leader>xs", "<cmd>Trouble symbols toggle focus=false<CR>", { desc = "Symbols" })
map("n", "<leader>xl", "<cmd>Trouble lsp toggle focus=false win.position=right<CR>", { desc = "LSP references" })
map("n", "<leader>xq", "<cmd>Trouble qflist toggle<CR>", { desc = "Quickfix" })
map("n", "<leader>xt", "<cmd>TodoTrouble<CR>", { desc = "Todos (Trouble)" })
map("n", "<leader>st", "<cmd>TodoTelescope<CR>", { desc = "Todos (Telescope)" })

--------------------------------------------------------------
-- NOICE (messages)
--------------------------------------------------------------
map("n", "<leader>snh", "<cmd>Noice history<CR>", { desc = "Message history" })
map("n", "<leader>snl", "<cmd>Noice last<CR>", { desc = "Last message" })
map("n", "<leader>snd", "<cmd>Noice dismiss<CR>", { desc = "Dismiss messages" })

--------------------------------------------------------------
-- UI TOGGLES
--------------------------------------------------------------
map("n", "<leader>us", function()
  vim.opt_local.spell = not vim.opt_local.spell:get()
end, { desc = "Toggle spell" })
map("n", "<leader>uw", function()
  vim.opt_local.wrap = not vim.opt_local.wrap:get()
end, { desc = "Toggle wrap" })
map("n", "<leader>ul", function()
  vim.opt_local.list = not vim.opt_local.list:get()
end, { desc = "Toggle list chars" })
map("n", "<leader>un", function()
  vim.opt_local.number = not vim.opt_local.number:get()
  vim.opt_local.relativenumber = vim.opt_local.number:get()
end, { desc = "Toggle line numbers" })
map("n", "<leader>uc", function()
  vim.opt_local.cursorline = not vim.opt_local.cursorline:get()
end, { desc = "Toggle cursorline" })
map("n", "<leader>uf", function()
  local on = require("features.settings").toggle("format_on_save")
  vim.notify("Format on save: " .. (on and "ON" or "OFF"))
end, { desc = "Toggle format on save" })
map("n", "<leader>uS", function()
  require("features.settings").panel()
end, { desc = "Settings panel (all the toggles)" })
map("n", "<leader>up", function()
  require("features.preview.live").toggle()
end, { desc = "Toggle live preview (sync without :w)" })

--------------------------------------------------------------
-- NEW FROM TEMPLATE
--------------------------------------------------------------
map("n", "<leader>nt", function() require("features.templates").pick() end, { desc = "New from template" })
map("n", "<leader>nm", function() require("features.templates").markdown() end, { desc = "New Markdown document" })
map("n", "<leader>nl", function() require("features.templates").latex() end, { desc = "New LaTeX document" })
map("n", "<leader>nT", function() require("features.templates").typst() end, { desc = "New Typst document" })

--------------------------------------------------------------
-- LATEX (Vimtex)
--------------------------------------------------------------
map("n", "<leader>ll", "<cmd>VimtexCompile<CR>", { desc = "LaTeX compile" })
map("n", "<leader>lv", "<cmd>VimtexView<CR>", { desc = "LaTeX view PDF" })
map("n", "<leader>lk", "<cmd>VimtexStop<CR>", { desc = "LaTeX stop" })
map("n", "<leader>lc", "<cmd>VimtexClean<CR>", { desc = "LaTeX clean" })
map("n", "<leader>le", "<cmd>VimtexErrors<CR>", { desc = "LaTeX errors" })
map("n", "<leader>lt", "<cmd>VimtexTocToggle<CR>", { desc = "LaTeX table of contents" })
map("n", "<leader>lI", "<cmd>VimtexInfo<CR>", { desc = "LaTeX info" })

--------------------------------------------------------------
-- TYPST
--------------------------------------------------------------
map("n", "<leader>tw", function()
  require("features.preview.typst").toggle()
end, { desc = "Typst: live preview (same as tv)" })
map("n", "<leader>tp", "<cmd>TypstPreviewToggle<CR>", { desc = "Typst: live preview in browser" })
map("n", "<leader>tq", function()
  -- Stop both kinds of live preview.
  require("features.preview.typst").stop()
  pcall(vim.cmd, "TypstPreviewStop")
  vim.notify("Stopped Typst live previews", vim.log.levels.INFO)
end, { desc = "Typst: stop live preview (browser + watch)" })
map("n", "<leader>ts", function()
  local ok = pcall(vim.cmd, "Toc")
  if not ok then
    vim.notify("Toc is only available in .typ buffers", vim.log.levels.WARN)
  end
end, { desc = "Typst outline" })
map("n", "<leader>tv", function()
  require("features.preview.typst").toggle()
end, { desc = "Typst: live preview (watch + Zathura)" })

--------------------------------------------------------------
-- HTML (live server)
--------------------------------------------------------------
map("n", "<leader>hp", function()
  require("features.preview.html").toggle(false)
end, { desc = "HTML: live server (index.html first)" })
map("n", "<leader>hP", function()
  require("features.preview.html").toggle(true)
end, { desc = "HTML: live server (this file)" })
map("n", "<leader>hq", function()
  if require("features.preview.html").stop() then
    vim.notify("HTML live preview stopped")
  end
end, { desc = "HTML: stop live server" })

--------------------------------------------------------------
-- MARKDOWN / MISC
--------------------------------------------------------------
map("n", "<leader>mp", function()
  -- MarkdownPreviewToggle is buffer-local to markdown buffers, so guard it
  -- instead of failing with "Command not found".
  if vim.bo.filetype ~= "markdown" then
    vim.notify(
      "Markdown preview needs a markdown buffer (use <leader>mr to render in place)",
      vim.log.levels.WARN
    )
    return
  end
  vim.cmd("MarkdownPreviewToggle")
end, { desc = "Markdown preview (minimal browser)" })
map("n", "<leader>mr", "<cmd>RenderMarkdown toggle<CR>", { desc = "Markdown: render in place" })
map("n", "<leader>pm", "<cmd>Mason<CR>", { desc = "Mason" })
map("n", "<leader>lg", "<cmd>Lazy<CR>", { desc = "Lazy" })
