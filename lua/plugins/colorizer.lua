-- Show colour codes (#rrggbb, rgb(), ...) in their own colour.
return {
  "norcalli/nvim-colorizer.lua",
  event = "BufReadPre",
  config = function()
    require("colorizer").setup({
      "*",
      css = { rgb_fn = true, hsl_fn = true },
      html = { names = false },
    })
  end,
}
