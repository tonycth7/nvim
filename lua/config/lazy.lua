-- ---------------------------------------------------------------------------
-- lazy.nvim — the plugin manager
-- ---------------------------------------------------------------------------
-- On a fresh machine this clones lazy.nvim itself, then loads every file in
-- lua/plugins/ as a plugin spec: one file per area, so adding a plugin means
-- adding a file there — nothing else has to be registered anywhere.
--
-- Plugin revisions are pinned in lazy-lock.json. Keep that file with the
-- config: `:Lazy restore` on another machine installs the exact same set.

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.notify("Could not clone lazy.nvim:\n" .. out, vim.log.levels.ERROR)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({ { import = "plugins" } })
