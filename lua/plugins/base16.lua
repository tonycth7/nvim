-- Colours from matugen (base16) — regenerated from the wallpaper.
return { 'RRethy/base16-nvim',
  config = function()
    local ok, matugen = pcall(require, 'matugen')
    if ok then matugen.setup() end
  end,
}
