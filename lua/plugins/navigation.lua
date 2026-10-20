-- Finding things: telescope (files/grep/help) and neo-tree (explorer).
return {
  -- Fuzzy finder (files, grep, buffers, help)
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-ui-select.nvim",
    },
    config = function()
      require("telescope").setup({
        defaults = {
          layout_strategy = "horizontal",
          layout_config = { prompt_position = "top" },
          sorting_strategy = "ascending",
          winblend = 10,
          path_display = { "smart" },
          file_ignore_patterns = {
            "node_modules", "%.git/", "dist/", "build/", "target/",
            "__pycache__", "%.lock", "%.min%.js", "%.pdf",
          },
        },
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown({}),
          },
        },
      })
      require("telescope").load_extension("ui-select")
    end,
  },

  -- File explorer
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    lazy = false,
    keys = {
      { "<leader>e", ":Neotree toggle<CR>", desc = "Toggle file explorer" },
    },
    config = function()
      require("neo-tree").setup({
        close_if_last_window = true,
        window = { position = "left", width = 30 },
        filesystem = {
          filtered_items = {
            visible = true,
            hide_dotfiles = false,
            hide_gitignored = false,
            hide_by_name = {},
            never_show = {},
          },
          follow_current_file = true,
          use_libuv_file_watcher = true,
        },
        git_status = {
          window = { position = "float" },
        },
        event_handlers = {
          {
            event = "file_open_requested",
            handler = function()
              require("neo-tree.command").execute({ action = "close" })
            end,
          },
        },
      })
    end,
  },
}
