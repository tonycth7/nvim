-- Live PDF preview for Typst.
--
-- `typst watch` keeps <file>.pdf up to date as you write, and Zathura reloads
-- a changed PDF on its own — so the buffer and the view stay in sync without
-- any browser. We own the job here (rather than pattern-matching processes
-- with pkill) so start/stop are exact.
local M = {}

-- Which program shows the PDF. Settings → Viewers can flip this to sioyek.
M.opts = { viewer = "zathura" }

function M.set_viewer(viewer)
  if viewer and viewer ~= "" then
    M.opts.viewer = viewer
  end
end

local job = nil

function M.stop()
  if job then
    pcall(vim.fn.jobstop, job)
    job = nil
    return true
  end
  return false
end

function M.start()
  local src = vim.api.nvim_buf_get_name(0)
  if src == "" or vim.bo.filetype ~= "typst" then
    vim.notify("Typst live preview needs a saved .typ buffer", vim.log.levels.WARN)
    return
  end

  M.stop()

  local id
  id = vim.fn.jobstart({ "typst", "watch", src }, {
    on_exit = function()
      if job == id then
        job = nil
      end
    end,
  })

  if id <= 0 then
    vim.notify("Could not start `typst watch`", vim.log.levels.ERROR)
    return
  end
  job = id

  -- Open the PDF once the first render has landed.
  local pdf = vim.fn.fnamemodify(src, ":r") .. ".pdf"
  local viewer = M.opts.viewer
  vim.defer_fn(function()
    if vim.fn.filereadable(pdf) == 1 and vim.fn.executable(viewer) == 1 then
      vim.fn.jobstart({ viewer, pdf }, { detach = true })
    end
  end, 700)
end

function M.toggle()
  if job then
    M.stop()
    vim.notify("Typst live preview stopped", vim.log.levels.INFO)
  else
    M.start()
  end
end

function M.is_running()
  return job ~= nil
end

function M.setup()
  -- Optional: start on open (Settings → Typst)
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("typst_preview_open", { clear = true }),
    pattern = "typst",
    callback = function(args)
      if not require("features.settings").get("typst_preview_on_open") then
        return
      end
      vim.schedule(function()
        if
          vim.api.nvim_buf_is_valid(args.buf)
          and vim.api.nvim_get_current_buf() == args.buf
          and not M.is_running()
        then
          M.start()
        end
      end)
    end,
  })
end

return M
