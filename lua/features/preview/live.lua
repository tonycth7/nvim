-- ---------------------------------------------------------------------------
-- live_preview — live preview without ever pressing :w
-- ---------------------------------------------------------------------------
--
-- Shortly after you stop typing in a .tex / .typ buffer, that buffer is synced
-- to disk. Everything downstream already reacts to a write:
--
--   .tex  -> VimTeX rebuilds the PDF      (BufWritePost hook in plugins/writing.lua)
--   .typ  -> `typst watch` re-renders it  (lua/features/preview/typst.lua)
--   .pdf  -> zathura watches the file with a glib file monitor and reloads itself
--
-- So the preview catches up roughly a second after you pause — no :w required.
--
-- The sync uses `noautocmd write` deliberately: it must NOT run the other
-- BufWritePre hooks. The "strip trailing whitespace on save" hook would eat the
-- space you had just typed while pausing mid-sentence and glue words together.
-- BufWritePost is fired by hand afterwards so the compile hooks still see it.
--
-- Toggle with :LivePreview or <leader>up.

local M = {}

local TYPING_DELAY = 1000 -- ms of quiet after a text change
local LEAVE_DELAY = 250   -- ms after leaving Insert mode
local FILE_TYPES = { tex = true, plaintex = true, typst = true }

local timer = vim.uv.new_timer()
local pending = nil

-- Is a build running right now? VimTeX exposes b:vimtex.compiler.is_running().
local function building(buf)
  local running = false
  pcall(function()
    vim.api.nvim_buf_call(buf, function()
      running = vim.fn.eval("b:vimtex.compiler.is_running()") == 1
    end)
  end)
  return running
end

local function ready(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end
  local bo = vim.bo[buf]
  if not bo.modified or bo.buftype ~= "" then
    return false
  end
  if bo.readonly or not bo.modifiable then
    return false
  end
  if not FILE_TYPES[bo.filetype] then
    return false
  end
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" or name:match("^%w+://") then
    return false
  end
  -- Only sync files that already exist: a brand new buffer belongs to the user
  -- until they save it for the first time.
  if not vim.uv.fs_stat(name) then
    return false
  end
  -- Don't stack builds.
  if building(buf) then
    return false
  end
  return true
end

local function sync(buf)
  if not ready(buf) then
    return
  end
  vim.api.nvim_buf_call(buf, function()
    vim.cmd("silent! noautocmd write")
  end)
  -- noautocmd swallowed BufWritePost; fire it so the compile hooks still run.
  vim.api.nvim_exec_autocmds("BufWritePost", { buffer = buf, modeline = false })
end

function M.enabled()
  local ok, settings = pcall(require, "settings")
  if ok then
    return settings.get("live_sync") ~= false
  end
  return vim.g.live_preview ~= false
end

function M.schedule(buf, delay)
  if not M.enabled() then
    return
  end
  pending = buf or vim.api.nvim_get_current_buf()
  timer:stop()
  timer:start(delay or TYPING_DELAY, 0, vim.schedule_wrap(function()
    local b = pending
    pending = nil
    if b then
      sync(b)
    end
  end))
end

-- For lualine: shows up only where live preview actually applies.
function M.status()
  if not M.enabled() or not FILE_TYPES[vim.bo.filetype] then
    return ""
  end
  return "live"
end

function M.toggle()
  local ok, settings = pcall(require, "settings")
  if ok then
    local on = settings.toggle("live_sync")
    vim.notify(
      "Live sync (rebuild without :w): " .. (on and "ON" or "OFF"),
      vim.log.levels.INFO
    )
    return
  end

  vim.g.live_preview = not M.enabled()
  if M.enabled() then
    M.schedule(nil, LEAVE_DELAY) -- catch up anything already modified
    vim.notify("Live preview: ON — .tex/.typ sync shortly after you pause", vim.log.levels.INFO)
  else
    timer:stop()
    pending = nil
    vim.notify("Live preview: OFF — preview updates on :w again", vim.log.levels.INFO)
  end
end

function M.setup()
  if vim.g.live_preview == nil then
    vim.g.live_preview = true
  end

  local group = vim.api.nvim_create_augroup("live_preview", { clear = true })
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = group,
    callback = function(args)
      M.schedule(args.buf, TYPING_DELAY)
    end,
  })
  vim.api.nvim_create_autocmd("InsertLeave", {
    group = group,
    callback = function(args)
      M.schedule(args.buf, LEAVE_DELAY)
    end,
  })

  vim.api.nvim_create_user_command("LivePreview", function()
    M.toggle()
  end, { desc = "Toggle live preview (sync without :w)" })
end

return M
