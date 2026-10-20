-- Interface: which-key, noice, lualine, indent guides, trouble.
return {
  -- Keybinding popup
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "classic",
      icons = {
        breadcrumb = "»",
        separator = "➜",
        group = "+",
      },
      win = {
        border = "rounded",
        padding = { 1, 2 },
        wo = { winblend = 10 },
      },
      spec = {
        { "<leader>f", group = "Find" },
        { "<leader>b", group = "Buffer" },
        { "<leader>s", group = "Split / Search" },
        { "<leader>l", group = "LSP / LaTeX" },
        { "<leader>t", group = "Typst / Theme" },
        { "<leader>x", group = "Trouble" },
        { "<leader>n", group = "New from template" },
        { "<leader>u", group = "UI toggles" },
        { "<leader>w", group = "Write / Quit" },
        { "<leader>q", group = "Quit" },
        { "<leader>p", group = "Plugins" },
      },
    },
  },

  -- Enhanced command line UI with fuzzy suggestions
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = { "MunifTanjim/nui.nvim" },
    config = function()
      vim.api.nvim_set_hl(0, "NoiceCmdlinePopupBorder", { fg = "#b4befe" })
      vim.api.nvim_set_hl(0, "NoiceCmdlineIcon", { fg = "#89b4fa" })
      require("noice").setup({
        cmdline = {
          enabled = true,
          view = "cmdline_popup",
          format = {
            cmdline = { icon = "" },
            search_down = { icon = " ", lang = "regex" },
            search_up = { icon = " ", lang = "regex" },
            filter = { icon = "$" },
            lua = { icon = "" },
            help = { icon = "?" },
          },
          opts = {
            position = { row = "100%", col = "50%" },
            size = { min_width = 60, width = "auto" },
            border = {
              style = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
              padding = { 0, 1 },
            },
          },
        },
        messages = { enabled = true, view = "mini" },
        popupmenu = { enabled = true, backend = "cmp" },
        lsp = {
          override = {
            "vim.lsp.util.convert_input_to_markdown",
            "vim.lsp.util.stylize_markdown",
          },
        },
        preset = {
          bottom_search = true,
          command_palette = "cmdline",
          long_message_to_split = true,
        },
      })
    end,
  },

  -- Statusline
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    config = function()
      require("lualine").setup({
        options = {
          theme = function()
            if vim.g.colors_name == "matugen" and vim.g.matugen_lualine_theme then
              return vim.g.matugen_lualine_theme
            end
            return "auto"
          end,
          component_separators = "",
          section_separators = "",
          globalstatus = true,
          disabled_filetypes = {
            statusline = { "dashboard", "lazy", "mason", "alpha" },
          },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch", "diff" },
          lualine_c = {
            {
              "filename",
              path = 1,
              symbols = { modified = " ●", readonly = "  ", unnamed = "[No Name]" },
            },
            {
              "diagnostics",
              symbols = { error = " ", warn = " ", info = " ", hint = " " },
            },
          },
          lualine_x = {
            { function() return require("features.preview.live").status() end },
            "encoding",
            { "fileformat", symbols = { unix = "", dos = " ", mac = "" } },
            "filetype",
          },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
      })
    end,
  },

  -- Indentation guides
  {
    "lukas-reineke/indent-blankline.nvim",
    event = { "BufReadPre", "BufNewFile" },
    main = "ibl",
    opts = {
      indent = { char = "│", tab_char = "│" },
      scope = { enabled = true, show_start = false, show_end = false },
      exclude = {
        filetypes = {
          "dashboard", "help", "lazy", "mason", "lspinfo", "neo-tree", "neo-tree-popup",
          "trouble", "Trouble", "noice", "notify", "qf",
          "markdown", "text", "typst", "tex", "gitcommit",
        },
      },
    },
  },

  -- Diagnostics / symbols panel
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      focus = true,
      win = { border = "rounded" },
    },
  },
}
