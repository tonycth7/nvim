-- ── Code parsing: treesitter highlighting and rainbow brackets. ─────────────────
-- ── GitHub Copilot (disabled by default) ─────────────────────────────────────
-- To enable when you have a GitHub Copilot subscription:
--   1. Uncomment the block below.
--   2. Run `gh auth login` (already logged in as tonycth7).
--   3. In Neovim: `:Copilot auth` to authorize.
--   4. Toggle with <leader>ci / <leader>cd / <leader>ct.
--
-- -- GitHub Copilot for Neovim (official plugin)
-- {
--   "github/copilot.vim",
--   build = ":CopilotAuth",
--   event = "InsertEnter",
--   keys = {
--     { "<leader>ci", "<CMD>Copilot enable<CR>", desc = "Enable Copilot" },
--     { "<leader>cd", "<CMD>Copilot disable<CR>", desc = "Disable Copilot" },
--     { "<leader>ct", "<CMD>Copilot toggle<CR>", desc = "Toggle Copilot" },
--   },
--   config = function()
--     require("copilot").setup({
--       debug = false,
--       suggestion = { auto_trigger = false },
--       filetypes = { latex = true, markdown = true },
--     })
--   end,
-- },
return {
  -- Syntax highlighting & parsing
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup({})

      -- Neovim only auto-starts Tree-sitter for lua/markdown/help/query, so we
      -- start it for everything that has a parser (LaTeX, Typst, ...).
      vim.api.nvim_create_autocmd("FileType", {
        callback = function()
          pcall(vim.treesitter.start)
        end,
      })
    end,
  },

  -- Rainbow brackets/parens (nested delimiters for code, LaTeX & Typst)
  {
    "HiPhish/rainbow-delimiters.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      -- Fallback colours, used only if the active colourscheme doesn't
      -- define the RainbowDelimiter* groups itself.
      local names = { "Red", "Yellow", "Blue", "Orange", "Green", "Violet", "Cyan" }
      local colors = { "#f38ba8", "#f9e2af", "#89b4fa", "#fab387", "#a6e3a1", "#cba6f7", "#94e2d5" }
      local function set_fallback()
        for i, n in ipairs(names) do
          local group = "RainbowDelimiter" .. n
          local existing = vim.api.nvim_get_hl(0, { name = group })
          if not (existing and (existing.fg or existing.link)) then
            vim.api.nvim_set_hl(0, group, { fg = colors[i] })
          end
        end
      end

      set_fallback()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_fallback })

      require("rainbow-delimiters.setup").setup({})
    end,
  },

  -- LSP installer
  {
    "mason-org/mason.nvim",
    build = ":MasonUpdate",
    cmd = "Mason",
    opts = {},
  },
}
