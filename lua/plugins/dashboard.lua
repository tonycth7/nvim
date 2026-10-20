-- Start screen: menu, ASCII art, recent files, git branch. The art and the
-- compact theme it draws are in lua/dashboard/.
return {
  {
    "nvimdev/dashboard-nvim",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local art = require("dashboard.art")
      local config_dir = vim.fn.stdpath("config")
      local cheatsheet = config_dir .. "/CHEATSHEET.md"

      -- Recent files (defensive: never break the dashboard)
      local function recent_files(max)
        local out = {}
        local ok, oldfiles = pcall(function()
          return vim.v.oldfiles
        end)
        if not ok or type(oldfiles) ~= "table" then
          return out
        end
        local seen = {}
        for _, f in ipairs(oldfiles) do
          if #out >= max then
            break
          end
          if vim.fn.filereadable(f) == 1
            and not seen[f]
            and not f:match("^term://")
            and not f:match("COMMIT_EDITMSG")
            and not f:match("/%.git/") then
            seen[f] = true
            out[#out + 1] = f
          end
        end
        return out
      end

      -- small, cached git helpers (never let a git hiccup break the dashboard)
      local function git_root(dir)
        if vim.fn.executable("git") ~= 1 or dir == nil or dir == "" then
          return nil
        end
        local ok, found = pcall(vim.fs.find, ".git", {
          path = dir,
          upward = true,
          stop = vim.env.HOME,
        })
        if ok and found and found[1] then
          return vim.fs.dirname(found[1])
        end
        return nil
      end

      -- { branch, repo } for the current working directory, or nil outside a repo
      local function git_branch()
        if vim.fn.executable("git") ~= 1 then
          return nil
        end
        local root = git_root(vim.fn.getcwd())
        if not root then
          return nil
        end
        local out = vim.fn.systemlist({ "git", "-C", root, "rev-parse", "--abbrev-ref", "HEAD" })
        if vim.v.shell_error ~= 0 or not out[1] or out[1] == "" then
          return nil
        end
        local branch = out[1]
        if branch == "HEAD" then -- detached head: fall back to the short sha
          local sha = vim.fn.systemlist({ "git", "-C", root, "rev-parse", "--short", "HEAD" })
          branch = (vim.v.shell_error == 0 and sha[1]) or "detached"
        end
        return branch, vim.fs.basename(root)
      end

      -- distinct git repositories among recently opened files
      local function recent_projects(max)
        local out, seen_dir, seen_root = {}, {}, {}
        local ok, oldfiles = pcall(function()
          return vim.v.oldfiles
        end)
        if not ok or type(oldfiles) ~= "table" then
          return out
        end
        local budget = 60 -- only inspect the first N entries (cheap, bounded)
        for _, f in ipairs(oldfiles) do
          if #out >= max or budget <= 0 then
            break
          end
          if type(f) == "string"
            and f ~= ""
            and not f:match("^%a+://")
            and not f:match("COMMIT_EDITMSG")
          then
            local dir = vim.fn.fnamemodify(f, ":p:h")
            if dir ~= "" and not seen_dir[dir] then
              seen_dir[dir] = true
              budget = budget - 1
              local root = git_root(dir)
              if root and not seen_root[root] then
                seen_root[root] = true
                out[#out + 1] = { root = root, name = vim.fs.basename(root) }
              end
            end
          end
        end
        return out
      end

      -- forward declaration: the center entries below need to re-render
      local render
      -- last header that was rendered, used to paint the gradient
      local last_header = {}

      local function build_center()
        local center = {
          { icon = " ", desc = "Find File", key = "f", action = "Telescope find_files" },
          { icon = " ", desc = "Live Grep", key = "g", action = "Telescope live_grep" },
          { icon = " ", desc = "New File",  key = "n", action = "ene | startinsert" },
          { icon = " ", desc = "Template",  key = "t", action = function() require("features.templates").pick() end },
          {
            icon = " ",
            desc = "Config",
            key = "c",
            action = "Telescope find_files cwd=" .. config_dir,
          },
          { icon = " ", desc = "Settings", key = "s", action = "Settings" },
          { icon = " ", desc = "Cheat Sheet", key = "k", action = "edit " .. vim.fn.fnameescape(cheatsheet) },
          {
            icon = " ",
            desc = "New Art",
            key = "a",
            action = function()
              art.advance()
              if render then
                render()
              end
            end,
          },
          { icon = " ", desc = "Plugins", key = "l", action = "Lazy" },
          { icon = " ", desc = "Mason",   key = "m", action = "Mason" },
          { icon = " ", desc = "Quit",    key = "q", action = function() vim.api.nvim_input("<cmd>qa<cr>") end },
        }

        -- Numbered shortcuts are shared between the "Recent" and "Projects"
        -- sections so their keys never collide.
        local n = 0
        local function next_key()
          n = n + 1
          return tostring(n)
        end

        -- Append a few recent files under a heading
        local recents = recent_files(3)
        if #recents > 0 then
          center[#center + 1] = { icon = " ", desc = "Recent ──────────────", key = nil, action = nil }
          for _, f in ipairs(recents) do
            local display = vim.fn.fnamemodify(f, ":~:.")
            if #display > 42 then
              display = "…" .. display:sub(-41)
            end
            center[#center + 1] = {
              icon = " ",
              desc = display,
              key = next_key(),
              action = "edit " .. vim.fn.fnameescape(f),
            }
          end
        end

        -- Append a few git repositories you have been working in
        local projects = recent_projects(3)
        if #projects > 0 then
          center[#center + 1] = { icon = " ", desc = "Projects ────────────", key = nil, action = nil }
          for _, p in ipairs(projects) do
            local name = p.name
            if #name > 42 then
              name = name:sub(1, 41) .. "…"
            end
            center[#center + 1] = {
              icon = " ",
              desc = name,
              key = next_key(),
              action = "Telescope find_files cwd=" .. vim.fn.fnameescape(p.root),
            }
          end
        end

        return center
      end

      local function build_opts()
        local center = build_center()
        -- The compact theme draws one line per entry (plus one blank line above
        -- each keyless heading), so count those to keep the header on screen.
        local headings = 0
        for _, item in ipairs(center) do
          if item.key == nil and item.action == nil then
            headings = headings + 1
          end
        end
        local max_height = vim.o.lines - (#center + headings + 5)
        local max_width = vim.o.columns - 6
        local header = art.choose({ max_height = max_height, max_width = max_width })
        last_header = header

        return {
          theme = "compact",
          hide = { statusline = false, tabline = true },
          config = {
            header = header,
            vertical_center = true,
            center = center,
            footer = function()
              local stats = require("lazy").stats()
              local ms = math.floor(stats.startuptime * 100 + 0.5) / 100
              local parts = {
                "❄  " .. stats.loaded .. "/" .. stats.count .. " plugins in " .. ms .. "ms",
              }
              local branch, repo = git_branch()
              if branch then
                parts[#parts + 1] = "" .. " " .. repo .. ":" .. branch
              end
              parts[#parts + 1] = os.date("%a %d %b  %H:%M")
              return { "", table.concat(parts, "   ·   ") .. "  ♱" }
            end,
          },
        }
      end

      -- re-draw the dashboard in place (used by "New Art" and <leader>ua).
      -- Leaving the dashboard buffer triggers the plugin's cleanup, which wipes
      -- its stored options, so we set them *after* the fresh buffer is opened.
      render = function()
        if vim.bo.filetype == "dashboard" then
          vim.cmd("enew")
        end
        require("dashboard").setup(build_opts())
        require("dashboard"):instance()
      end

      vim.api.nvim_create_user_command("DashboardArt", function(a)
        local arg = a.args ~= "" and a.args or nil
        if arg == "list" then
          vim.notify("Dashboard art: " .. table.concat(art.names(), ", "), vim.log.levels.INFO)
        elseif arg == "random" then
          local _, name = art.random()
          render()
          vim.notify("Dashboard art: " .. name, vim.log.levels.INFO)
        elseif arg and art.set(arg) then
          render()
        elseif arg == nil or arg == "next" then
          local name = art.advance()
          render()
          vim.notify("Dashboard art: " .. name, vim.log.levels.INFO)
        else
          vim.notify("Unknown art '" .. arg .. "' — try :DashboardArt list", vim.log.levels.WARN)
        end
      end, {
        nargs = "?",
        desc = "Pick the dashboard ASCII art",
        complete = function(arglead)
          local names = art.names()
          names[#names + 1] = "random"
          names[#names + 1] = "list"
          return vim.tbl_filter(function(n)
            return n:find(arglead, 1, true) == 1
          end, names)
        end,
      })

      vim.keymap.set("n", "<leader>ua", function()
        local name = art.advance()
        if vim.bo.filetype == "dashboard" then
          render()
        end
        vim.notify("Dashboard art: " .. name, vim.log.levels.INFO)
      end, { desc = "Next dashboard art" })

      -- Vertical gradient over the header art (cool winter palette).
      local grad_ns = vim.api.nvim_create_namespace("dashboard_art_gradient")
      local grad_palette = { "#89dceb", "#89b4fa", "#cba6f7" }

      local function hex2rgb(h)
        return tonumber(h:sub(2, 3), 16), tonumber(h:sub(4, 5), 16), tonumber(h:sub(6, 7), 16)
      end

      local function grad_color(t)
        local seg = t * (#grad_palette - 1)
        local i = math.min(math.floor(seg) + 1, #grad_palette - 1)
        local f = seg - (i - 1)
        local r1, g1, b1 = hex2rgb(grad_palette[i])
        local r2, g2, b2 = hex2rgb(grad_palette[i + 1])
        return string.format(
          "#%02x%02x%02x",
          math.floor(r1 + (r2 - r1) * f + 0.5),
          math.floor(g1 + (g2 - g1) * f + 0.5),
          math.floor(b1 + (b2 - b1) * f + 0.5)
        )
      end

      -- (never let a cosmetic touch break the dashboard)
      local function paint_header(buf)
        pcall(function()
          buf = buf or vim.api.nvim_get_current_buf()
          if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].filetype ~= "dashboard" then
            return
          end
          if #last_header == 0 then
            return
          end
          local want = {}
          for i, line in ipairs(last_header) do
            local key = vim.trim(line)
            if key ~= "" and not want[key] then
              want[key] = i
            end
          end
          if vim.tbl_isempty(want) then
            return
          end
          local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
          local n = #last_header
          vim.api.nvim_buf_clear_namespace(buf, grad_ns, 0, -1)
          for row, line in ipairs(lines) do
            local idx = want[vim.trim(line)]
            if idx then
              local hl = "DashHeaderGrad" .. idx
              vim.api.nvim_set_hl(0, hl, {
                fg = grad_color((idx - 1) / math.max(n - 1, 1)),
                bold = true,
              })
              vim.api.nvim_buf_set_extmark(buf, grad_ns, row - 1, 0, {
                end_col = #line,
                hl_group = hl,
                priority = 200,
              })
            end
          end
        end)
      end

      vim.api.nvim_create_autocmd("User", {
        pattern = "DashboardLoaded",
        callback = function()
          paint_header()
        end,
      })
      vim.api.nvim_create_autocmd("VimResized", {
        callback = function()
          vim.schedule(function()
            paint_header()
          end)
        end,
      })
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function()
          vim.schedule(function()
            for _, b in ipairs(vim.api.nvim_list_bufs()) do
              paint_header(b)
            end
          end)
        end,
      })

      -- Neovim reads the shada file (v:oldfiles) AFTER init.lua, so we set the
      -- dashboard up on VimEnter (which fires before the dashboard is shown).
      vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = function()
          require("dashboard").setup(build_opts())
        end,
      })
    end,
  },
}
