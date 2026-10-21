-- ── Code parsing & AI assistance ──────────────────────────────────────────────
return {
  -- GitHub Copilot for Neovim (needs `gh auth login` for auth)
  {
    "github/copilot.vim",
    build = ":CopilotAuth",  -- ensures authentication step runs
    event = "InsertEnter",  -- start when entering Insert mode
    keys = {
      { "<leader>ci", "<CMD>Copilot enable<CR>", desc = "Enable Copilot" },
      { "<leader>cd", "<CMD>Copilot disable<CR>", desc = "Disable Copilot" },
      { "<leader>ct", "<CMD>Copilot toggle<CR>", desc = "Toggle Copilot" },
    },
    config = function()
      require("copilot").setup({
        debug = false, -- set to true to debug locally
        suggestion = { auto_trigger = false }, -- manual trigger
        filetypes = { latex = true, markdown = true }, -- enable for common editors
      })
    end,
  },
}