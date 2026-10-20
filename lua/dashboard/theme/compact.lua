-- compact.lua — dashboard-nvim theme.
--
-- Like the bundled "doom" theme (same highlights, keys, cursor behaviour) but
-- with **one line per entry** instead of inserting a blank line after every
-- entry. A single blank line is still kept *above* keyless entries, so section
-- headings ("Recent", "Projects", ...) still read as groups.
--
-- This lives in the user config so `require("dashboard.theme.compact")` finds it
-- before anything else on the runtimepath.
local api, keymap = vim.api, vim.keymap
local utils = require('dashboard.utils')

local vert_offset

-- Build the center block. Returns the buffer lines plus a map from 1-based line
-- number (relative to the center block) to the index in `config.center`.
local function gen_center(config)
  local center = config.center or {}
  local lines, counts, index_of = {}, {}, {}

  for idx, item in ipairs(center) do
    local count = item.keymap and #item.keymap or 0
    local line = (item.icon or '') .. item.desc

    if item.key then
      line = line .. (' '):rep(#item.key + 4)
      count = count + #item.key + 3
      local desc = 'Dashboard-action: ' .. item.desc:gsub('^%s+', '')
      keymap.set('n', item.key, function()
        if type(item.action) == 'string' then
          local dump = loadstring(item.action)
          if not dump then
            vim.cmd(item.action)
          else
            dump()
          end
        elseif type(item.action) == 'function' then
          item.action()
        end
      end, { buffer = config.bufnr, nowait = true, silent = true, desc = desc })
    end

    if item.keymap then
      line = line .. (' '):rep(#item.keymap)
    end

    -- A keyless entry is a section heading: keep one blank line above it
    -- (never at the very top) so sections stay visually separated.
    if item.key == nil and #lines > 0 then
      table.insert(lines, '')
      table.insert(counts, 0)
      table.insert(index_of, false)
    end

    table.insert(lines, line)
    table.insert(counts, count)
    table.insert(index_of, idx)
  end

  if #lines == 0 then
    local msg = utils.center_align({ 'Please config your own center section', '' })
    api.nvim_buf_set_lines(config.bufnr, vert_offset, -1, false, msg)
    return msg, {}
  end

  lines = utils.element_align(lines)
  lines = utils.center_align(lines)
  for i, count in ipairs(counts) do
    lines[i] = lines[i]:sub(1, #lines[i] - count)
  end

  api.nvim_buf_set_lines(config.bufnr, vert_offset, -1, false, lines)
  return lines, index_of
end

local function gen_highlights(config, lines, index_of)
  local ns = api.nvim_create_namespace('DashboardCompact')
  local position_map = {}
  for i = 1, #lines do
    local idx = index_of[i]
    if idx and lines[i]:find('%w') then
      position_map[i] = idx
      local item = config.center[idx]
      local _, scol = lines[i]:find('%s+')
      local ecol = (scol or 0) + (item.icon and #item.icon or 0)

      if item.icon then
        api.nvim_buf_add_highlight(
          config.bufnr,
          0,
          item.icon_hl or 'DashboardIcon',
          vert_offset + i - 1,
          0,
          ecol
        )
      end

      api.nvim_buf_add_highlight(
        config.bufnr,
        0,
        item.desc_hl or 'DashboardDesc',
        vert_offset + i - 1,
        ecol,
        -1
      )

      if item.key then
        local virt_tbl = {}
        if item.keymap then
          table.insert(virt_tbl, { item.keymap, 'DashboardShortCut' })
        end
        table.insert(virt_tbl, {
          string.format(item.key_format or ' [%s]', item.key),
          item.key_hl or 'DashboardKey',
        })
        api.nvim_buf_set_extmark(config.bufnr, ns, vert_offset + i - 1, 0, {
          virt_text_pos = 'eol',
          virt_text = virt_tbl,
        })
      end
    end
  end
  return position_map
end

local function move_cursor_behaviour(config, bottom_linenr)
  local line = api.nvim_buf_get_lines(config.bufnr, vert_offset, vert_offset + 1, false)[1]
  local col = line:find('%w')
  local col_width = api.nvim_strwidth(line:sub(1, col or 1))
  col = col and col - 1 or 9999
  api.nvim_win_set_cursor(config.winid, { vert_offset + 1, col })

  vim.defer_fn(function()
    local before = 0
    if api.nvim_get_current_buf() ~= config.bufnr then
      return
    end

    local group = api.nvim_create_augroup('DashboardCompactCursor', { clear = true })
    api.nvim_create_autocmd('CursorMoved', {
      buffer = config.bufnr,
      group = group,
      callback = function()
        local buf = api.nvim_win_get_buf(0)
        if api.nvim_get_option_value('filetype', { buf = buf }) ~= 'dashboard' then
          return
        end

        local curline = api.nvim_win_get_cursor(0)[1]
        if curline < vert_offset + 1 then
          curline = bottom_linenr - 1
        elseif curline > bottom_linenr - 1 then
          curline = vert_offset + 1
        elseif not api.nvim_get_current_line():find('%w') then
          curline = curline + (before > curline and -1 or 1)
        end
        before = curline

        local curline_str = api.nvim_buf_get_lines(config.bufnr, curline - 1, curline, false)[1]
        local strwidth = api.nvim_strwidth(curline_str:sub(1, col + 1))
        local col_with_offset = col + col_width - strwidth
        if col_with_offset < 0 then
          col_with_offset = 0
        end
        api.nvim_win_set_cursor(config.winid, { curline, col_with_offset })
      end,
    })
  end, 0)
end

local function confirm_key(config, position_map)
  keymap.set('n', config.confirm_key or '<CR>', function()
    local curline = api.nvim_win_get_cursor(0)[1]
    local index = position_map[curline - vert_offset]
    if index and config.center[index].action then
      local action = config.center[index].action
      if type(action) == 'string' then
        local dump = loadstring(action)
        if not dump then
          vim.cmd(action)
        else
          dump()
        end
      elseif type(action) == 'function' then
        action()
      else
        print('Error with action, check your config')
      end
    end
  end, { buffer = config.bufnr, nowait = true, silent = true })
end

local function load_packages(config)
  local packages = config.packages or { enable = true }
  if not packages.enable then
    return
  end

  local stats = utils.get_package_manager_stats()
  local lines
  if stats.name == 'lazy' then
    lines = {
      '',
      'Startuptime: ' .. stats.time .. ' ms',
      'Plugins: ' .. stats.loaded .. ' loaded / ' .. stats.count .. ' installed',
    }
  else
    lines = { '', 'neovim loaded ' .. stats.count .. ' plugins' }
  end

  local first_line = api.nvim_buf_line_count(config.bufnr)
  api.nvim_buf_set_lines(config.bufnr, first_line, -1, false, utils.center_align(lines))
  for i = 1, #lines do
    api.nvim_buf_add_highlight(config.bufnr, 0, 'Comment', first_line + i - 1, 0, -1)
  end
  return lines
end

local function gen_footer(config)
  local lines = {}
  if config.footer then
    if type(config.footer) == 'function' then
      lines = config.footer()
    elseif type(config.footer) == 'string' then
      local dump = loadstring(config.footer)
      if dump then
        lines = dump()
      end
    elseif type(config.footer) == 'table' then
      lines = config.footer
    end
    local first_line = api.nvim_buf_line_count(config.bufnr)
    api.nvim_buf_set_lines(config.bufnr, first_line, -1, false, utils.center_align(lines))
    for i = 1, #lines do
      api.nvim_buf_add_highlight(config.bufnr, 0, 'DashboardFooter', first_line + i - 1, 0, -1)
    end
  else
    lines = load_packages(config)
  end
  utils.add_update_footer_command(config.bufnr, lines)
  return #lines
end

local function vertical_center(config)
  if config.vertical_center ~= true then
    return
  end

  local size = math.floor(vim.o.lines / 2)
    - math.ceil(api.nvim_buf_line_count(config.bufnr) / 2)
    - 2
  local fill = utils.generate_empty_table(size)
  api.nvim_buf_set_lines(config.bufnr, 0, 0, false, fill)

  vert_offset = vert_offset + (size < 0 and 0 or size)
end

local function theme_instance(config)
  require('dashboard.theme.header').generate_header(config)
  vert_offset = api.nvim_buf_line_count(config.bufnr)

  local lines, index_of = gen_center(config)
  local footer_size = gen_footer(config)
  vertical_center(config)
  local position_map = gen_highlights(config, lines, index_of)

  local last_entry_pos = api.nvim_buf_line_count(config.bufnr) - footer_size
  move_cursor_behaviour(config, last_entry_pos)
  confirm_key(config, position_map)

  vim.bo[config.bufnr].modifiable = false
  vim.bo[config.bufnr].modified = false
  -- defer until next event loop
  vim.schedule(function()
    api.nvim_exec_autocmds('User', {
      pattern = 'DashboardLoaded',
      modeline = false,
    })
  end)
end

return setmetatable({}, {
  __call = function(_, t)
    return theme_instance(t)
  end,
})
