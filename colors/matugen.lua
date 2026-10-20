vim.g.colors_name = 'matugen'

-- Wrap base16-colorscheme.setup so transparency + lualine always apply,
-- even when matugen regenerates lua/matugen.lua or fires SIGUSR1.
local b16 = require('base16-colorscheme')
if not b16._matugen_wrapped then
  b16._matugen_wrapped = true
  local orig_setup = b16.setup
  b16.setup = function(colors, config)
    orig_setup(colors, config)

    -- Transparent background
    vim.api.nvim_set_hl(0, 'Normal', { bg = 'NONE' })

    -- Build lualine theme from base16 colors
    local c = b16.colors
    if c then
      vim.g.matugen_lualine_theme = {
        normal = {
          a = { fg = c.base00, bg = c.base0B, gui = 'bold' },
          b = { fg = c.base05, bg = c.base02 },
          c = { fg = c.base05, bg = c.base00 },
        },
        insert = {
          a = { fg = c.base00, bg = c.base0A, gui = 'bold' },
          b = { fg = c.base05, bg = c.base02 },
          c = { fg = c.base05, bg = c.base00 },
        },
        visual = {
          a = { fg = c.base00, bg = c.base09, gui = 'bold' },
          b = { fg = c.base05, bg = c.base02 },
          c = { fg = c.base05, bg = c.base00 },
        },
        replace = {
          a = { fg = c.base00, bg = c.base08, gui = 'bold' },
          b = { fg = c.base05, bg = c.base02 },
          c = { fg = c.base05, bg = c.base00 },
        },
        command = {
          a = { fg = c.base00, bg = c.base03, gui = 'bold' },
          b = { fg = c.base05, bg = c.base02 },
          c = { fg = c.base05, bg = c.base00 },
        },
        inactive = {
          a = { fg = c.base03, bg = c.base00 },
          b = { fg = c.base03, bg = c.base00 },
          c = { fg = c.base03, bg = c.base00 },
        },
      }
    end
  end
end

require('matugen').setup()
