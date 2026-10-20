-- Telescope theme picker (used by <leader>th and the dashboard).
-- The pick is written to stdpath("data")/theme and re-applied on startup.
local M = {}

M.themes = {
  "catppuccin-latte", "catppuccin-frappe", "catppuccin-macchiato", "catppuccin-mocha",
  "tokyonight", "kanagawa", "gruvbox",
  "dracula", "rose-pine", "matugen",
}

function M.pick()
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local finders = require("telescope.finders")
  local pickers = require("telescope.pickers")
  local sorters = require("telescope.sorters")

  pickers.new({}, {
    prompt_title = " Themes ",
    finder = finders.new_table({ results = M.themes }),
    sorter = sorters.get_generic_fuzzy_sorter(),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if selection then
          vim.cmd.colorscheme(selection[1])
          local f = io.open(vim.fn.stdpath("data") .. "/theme", "w")
          if f then
            f:write(selection[1])
            f:close()
          end
        end
      end)
      return true
    end,
  }):find()
end

--- Apply the colourscheme chosen last time, if any.
function M.restore()
  local f = io.open(vim.fn.stdpath("data") .. "/theme", "r")
  if not f then
    return
  end
  local saved = f:read("*l")
  f:close()
  if saved and saved ~= "" then
    vim.cmd.colorscheme(saved)
  end
end

return M
