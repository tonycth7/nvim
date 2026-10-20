-- ---------------------------------------------------------------------------
-- bin — the helper scripts that ship with this config
-- ---------------------------------------------------------------------------
-- The previews, the :Settings panel and the LaTeX compiler shell out to small
-- scripts that live in bin/ next to this config (livehtml, mdpreview,
-- texbuild), so a clone of the config is self-contained. setup.sh also links
-- them into ~/.local/bin for use from a shell.
--
-- This is the one place that decides which copy to run: the config's own first
-- (works before setup.sh has ever run), then anything on PATH.

local M = {}

local DIR = vim.fn.stdpath("config") .. "/bin"

--- Absolute path to a helper script from bin/ (or its PATH equivalent).
function M.path(name)
  local shipped = DIR .. "/" .. name
  if vim.fn.executable(shipped) == 1 then
    return shipped
  end
  local on_path = vim.fn.exepath(name)
  if on_path ~= "" then
    return on_path
  end
  return vim.fn.expand("~/.local/bin/" .. name)
end

--- True when the script exists somewhere we would find it.
function M.available(name)
  return vim.fn.executable(M.path(name)) == 1
end

return M
