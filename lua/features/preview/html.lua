-- ---------------------------------------------------------------------------
-- html_preview — a small "Live Server", for HTML
-- ---------------------------------------------------------------------------
--
--   <leader>hp   serve the current file's directory; opens index.html if that
--                directory has one, otherwise the file you are in
--   <leader>hP   always open *this* file (even when index.html exists)
--   <leader>hq   stop the server
--
-- Serving over real HTTP is what makes this work like VS Code's Live Server:
-- relative <link>/<script>/<img> and fetch() resolve properly instead of
-- fighting file:// rules, and bin/livehtml watches the whole tree, so saving
-- the .html — or its .css or its .js — reloads the browser by itself.
--
-- The server serves files from disk, so <leader>hp saves the buffer first
-- (Settings → HTML → "Save the buffer before the server starts").
--
-- The server is a child of Neovim, so it goes away when Neovim does.

local M = {}

-- Overridable, e.g. if you would rather have a normal browser window:
--   require("features.preview.html").opts.opener = "firefox"
local bin = require("config.bin")
M.opts = {
  server = bin.path("livehtml"), -- bin/livehtml: static server + SSE reload
  opener = bin.path("mdpreview"), -- bin/mdpreview: chrome-less browser window
}

local job, port = nil, nil
local log_lines = {}

function M.is_running()
  return job ~= nil
end

function M.url()
  return port and ("http://127.0.0.1:" .. port .. "/") or nil
end

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO)
end

function M.stop()
  if job then
    pcall(vim.fn.jobstop, job)
    job, port = nil, nil
    return true
  end
  return false
end

local function open_url(entry)
  if not port then
    return
  end
  local url = string.format("http://127.0.0.1:%d/%s", port, entry ~= "" and entry or "")
  vim.fn.jobstart({ M.opts.opener, url }, { detach = true })
  notify("HTML live preview: " .. url)
end

function M.start(force_current, opts)
  opts = opts or {}
  local buf = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" or not name:match("%.[Hh][Tt][Mm][Ll]?$") then
    notify("HTML live preview needs a saved .html buffer", vim.log.levels.WARN)
    return
  end

  -- The server serves files from disk, so an unwritten buffer would just 404.
  -- <leader>hp may write it for you (Settings → HTML); the "start on open"
  -- hook passes write = false, so opening a file never saves it.
  local on_disk = vim.fn.filereadable(name) == 1
  if (not on_disk or vim.bo[buf].modified) and opts.write ~= false
    and require("features.settings").get("html_write_first") then
    local ok = pcall(vim.cmd, "silent write")
    on_disk = ok and vim.fn.filereadable(name) == 1
  end
  if not on_disk then
    if opts.write ~= false then
      notify(
        vim.fn.fnamemodify(name, ":t")
          .. " is not on disk yet — save it first (:w), then start the preview",
        vim.log.levels.WARN
      )
    end
    return
  end

  local dir = vim.fn.fnamemodify(name, ":p:h")

  -- As asked: index.html is the entry point when the directory has one.
  -- <leader>hP bypasses that and serves the buffer's own file.
  local entry
  if not force_current and vim.fn.filereadable(dir .. "/index.html") == 1 then
    entry = "index.html"
  else
    entry = vim.fn.fnamemodify(name, ":t")
  end
  M.last_entry = entry

  M.stop()

  local id
  id = vim.fn.jobstart({ M.opts.server, "--root", dir, "--port", "0" }, {
    on_stdout = function(_, data)
      for _, line in ipairs(data or {}) do
        local found = line:match("^LIVEHTML PORT (%d+)$")
        if found and job == id then
          port = tonumber(found)
          open_url(entry)
        end
      end
    end,
    on_stderr = function(_, data)
      for _, line in ipairs(data or {}) do
        if line ~= "" then
          log_lines[#log_lines + 1] = line
          if #log_lines > 200 then
            table.remove(log_lines, 1)
          end
        end
      end
    end,
    on_exit = function()
      if job == id then
        job, port = nil, nil
      end
    end,
  })

  if id <= 0 then
    notify("Could not start livehtml (" .. M.opts.server .. ")", vim.log.levels.ERROR)
    return
  end
  job = id
end

function M.toggle(force_current, opts)
  if job then
    M.stop()
    notify("HTML live preview stopped")
  else
    M.start(force_current, opts)
  end
end

-- The server's own request log — the place to look when a page 404s.
function M.log()
  vim.cmd("botright new")
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(
    buf,
    0,
    -1,
    false,
    #log_lines > 0 and log_lines or { "(livehtml has not logged anything yet)" }
  )
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = "log"
  vim.api.nvim_buf_set_name(buf, "livehtml.log")
end

function M.setup()
  vim.api.nvim_create_user_command("HtmlPreview", function()
    M.start(false)
  end, { desc = "HTML live preview (index.html first)" })

  vim.api.nvim_create_user_command("HtmlPreviewThis", function()
    M.start(true)
  end, { desc = "HTML live preview of this file" })

  vim.api.nvim_create_user_command("HtmlPreviewStop", function()
    if M.stop() then
      notify("HTML live preview stopped")
    end
  end, { desc = "Stop the HTML live preview" })

  vim.api.nvim_create_user_command("HtmlPreviewLog", function()
    M.log()
  end, { desc = "Show the HTML live preview server log" })

  -- Optional: start on open (Settings → HTML)
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("html_preview_open", { clear = true }),
    pattern = "html",
    callback = function(args)
      if not require("features.settings").get("html_server_on_open") then
        return
      end
      vim.schedule(function()
        if
          vim.api.nvim_buf_is_valid(args.buf)
          and vim.api.nvim_get_current_buf() == args.buf
          and not M.is_running()
        then
          M.start(false, { write = false })
        end
      end)
    end,
  })
end

return M
