-- Colourscheme: catppuccin is the default; <leader>th picks another.
return {
  -- Current theme (default)
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha",
        transparent_background = false,
        integrations = {
          treesitter = true,
          telescope = true,
          indent_blankline = { enabled = true },
          lsp_trouble = true,
          mason = true,
          cmp = true,
          gitsigns = true,
          neo_tree = true,
          which_key = true,
          noice = true,
          rainbow_delimiters = true,
          native_lsp = {
            enabled = true,
            virtual_text = { errors = {italic = true}, hints = {italic = true} },
            underlines = { errors = {}, hints = {} },
          },
        },
      })
    end,
  },

  -- Additional themes to choose from with <leader>th
  { "folke/tokyonight.nvim", lazy = true },
  { "rebelot/kanagawa.nvim", lazy = true },
  { "ellisonleao/gruvbox.nvim", lazy = true },
  { "Mofiqul/dracula.nvim", lazy = true },
  { "rose-pine/neovim", lazy = true },
}
