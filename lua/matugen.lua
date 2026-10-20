 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#000000',
    base01 = '#101416',
    base02 = '#1a1f20',
    base03 = '#879396',
    base04 = '#bdc8cc',
    base05 = '#dfe3e5',
    base06 = '#dfe3e5',
    base07 = '#dfe3e5',
    base08 = '#ffb4ab',
    base09 = '#e5b4ff',
    base0A = '#a9ccd8',
    base0B = '#71d4ef',
    base0C = '#e5b4ff',
    base0D = '#71d4ef',
    base0E = '#a9ccd8',
    base0F = '#c4e8f4',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  -- telescope.nvim
  hi('TelescopeNormal',         { fg = '#dfe3e5',          bg = '#000000' })
  hi('TelescopeBorder',         { fg = '#879396',             bg = '#000000' })
  hi('TelescopePromptNormal',   { fg = '#dfe3e5',          bg = '#000000' })
  hi('TelescopePromptBorder',   { fg = '#879396',             bg = '#000000' })
  hi('TelescopePromptPrefix',   { fg = '#71d4ef',             bg = '#000000' })
  hi('TelescopePromptCounter',  { fg = '#bdc8cc',  bg = '#000000' })
  hi('TelescopePromptTitle',    { fg = '#000000',             bg = '#71d4ef' })
  hi('TelescopePreviewTitle',   { fg = '#000000',             bg = '#a9ccd8' })
  hi('TelescopeResultsTitle',   { fg = '#000000',             bg = '#e5b4ff' })
  hi('TelescopeSelection',      { fg = '#dfe3e5',          bg = '#1a1f20' })
  hi('TelescopeSelectionCaret', { fg = '#71d4ef',             bg = '#1a1f20' })
  hi('TelescopeMatching',       { fg = '#71d4ef',             bold = true })

  -- mini.pick
  hi('MiniPickNormal',         { fg = '#dfe3e5',          bg = '#000000' })
  hi('MiniPickBorder',         { fg = '#879396',             bg = '#000000' })
  hi('MiniPickPrompt',   { fg = '#dfe3e5',          bg = '#000000' })
  hi('MiniPickPromptPrefix',   { fg = '#71d4ef',             bg = '#000000' })
  hi('MiniPickBorderText',    { fg = '#000000',             bg = '#71d4ef' })
  hi('MiniPickMatchCurrent',      { fg = '#dfe3e5',          bg = '#1a1f20' })
  hi('MiniPickPromptCaret', { fg = '#71d4ef',             bg = '#1a1f20' })
  hi('MiniPickMatchRanges',       { fg = '#71d4ef',             bold = true })
end

-- Register a signal handler for SIGUSR1 (matugen updates).
-- The handler re-requires this module, which re-runs the code below, so the
-- previous handle is stopped first; otherwise handlers double on every signal.
if _G.__matugen_signal then
  _G.__matugen_signal:stop()
  _G.__matugen_signal:close()
end

local signal = vim.uv.new_signal()
_G.__matugen_signal = signal
signal:start(
  'sigusr1',
  vim.schedule_wrap(function()
    package.loaded['matugen'] = nil
    require('matugen').setup()
  end)
)

return M
