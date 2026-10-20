-- Curated ASCII art for the dashboard header.
--
-- Sources (all permissive / public collections):
--   * github.com/MaximilianLloyd/ascii.nvim  (MIT)  -> hydra, neovim, arch, saturn
--   * personal "AS|" brand with the ❄ / ♱ motif
--
-- The active art is picked automatically (random on first run, remembered
-- after that) and can be changed live with the dashboard "New Art" entry,
-- <leader>da, or the :DashboardArt command. Each art is normalised so every
-- line has the same display width, which keeps the shape intact when the
-- dashboard centres the header.

local M = {}

local function to_lines(s)
  local out = {}
  for line in (s .. "\n"):gmatch("(.-)\n") do
    out[#out + 1] = line
  end
  -- drop only fully-empty leading/trailing lines (space-only padding is kept)
  while #out > 0 and out[1] == "" do
    table.remove(out, 1)
  end
  while #out > 0 and out[#out] == "" do
    table.remove(out)
  end
  return out
end

-- right-pad every line to the widest one so centring preserves the shape
local function make(s)
  local raw = to_lines(s)
  local width = 0
  for _, l in ipairs(raw) do
    width = math.max(width, vim.api.nvim_strwidth(l))
  end
  local lines = {}
  for _, l in ipairs(raw) do
    lines[#lines + 1] = l .. string.rep(" ", width - vim.api.nvim_strwidth(l))
  end
  return { lines = lines, width = width, height = #lines }
end

-- Order matters: "brand" is both the default and the fallback.
M.order = { "brand", "moon", "tux", "arch", "neovim", "hydra", "saturn", "doom" }

M.arts = {
  brand = make([==[
         ❄
   _    ____   ____
  / \  |  _ \ / ___|
 / _ \ | |_) | |
/ ___ \|  _ <| |___
/_/   \_\_| \_\\____|
         ♱
]==]),

  neovim = make([==[
 ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
 ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
 ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
 ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
 ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
 ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
]==]),

  hydra = make([==[
   ⣴⣶⣤⡤⠦⣤⣀⣤⠆     ⣈⣭⣿⣶⣿⣦⣼⣆
    ⠉⠻⢿⣿⠿⣿⣿⣶⣦⠤⠄⡠⢾⣿⣿⡿⠋⠉⠉⠻⣿⣿⡛⣦
          ⠈⢿⣿⣟⠦ ⣾⣿⣿⣷    ⠻⠿⢿⣿⣧⣄
           ⣸⣿⣿⢧ ⢻⠻⣿⣿⣷⣄⣀⠄⠢⣀⡀⠈⠙⠿⠄
          ⢠⣿⣿⣿⠈    ⣻⣿⣿⣿⣿⣿⣿⣿⣛⣳⣤⣀⣀
   ⢠⣧⣶⣥⡤⢄ ⣸⣿⣿⠘  ⢀⣴⣿⣿⡿⠛⣿⣿⣧⠈⢿⠿⠟⠛⠻⠿⠄
  ⣰⣿⣿⠛⠻⣿⣿⡦⢹⣿⣷   ⢊⣿⣿⡏  ⢸⣿⣿⡇ ⢀⣠⣄⣾⠄
 ⣠⣿⠿⠛ ⢀⣿⣿⣷⠘⢿⣿⣦⡀ ⢸⢿⣿⣿⣄ ⣸⣿⣿⡇⣪⣿⡿⠿⣿⣷⡄
 ⠙⠃   ⣼⣿⡟  ⠈⠻⣿⣿⣦⣌⡇⠻⣿⣿⣷⣿⣿⣿ ⣿⣿⡇ ⠛⠻⢷⣄
      ⢻⣿⣿⣄   ⠈⠻⣿⣿⣿⣷⣿⣿⣿⣿⣿⡟ ⠫⢿⣿⡆
       ⠻⣿⣿⣿⣿⣶⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⡟⢀⣀⣤⣾⡿⠃
]==]),

  arch = make([==[
                _       _     _
               | |     | |   | |
  __ _ _ __ ___| |__   | |__ | |___      __
 / _` | '__/ __| '_ \  | '_ \| __\ \ /\ / /
| (_| | | | (__| | | | | |_) | |_ \ V  V /
 \__,_|_|  \___|_| |_| |_.__/ \__| \_/\_/
]==]),

  saturn = make([==[
                                          _.oo.
                  _.u[[/;:,.         .odMMMMMM'
               .o888UU[[[/;:-.  .o@P^    MMM^
              oN88888UU[[[/;::-.        dP^
             dNMMNN888UU[[[/;:--.   .o@P^
            ,MMMMMMN888UU[[/;::-. o@^
            NNMMMNN888UU[[[/~.o@P^
            888888888UU[[[/o@^-..
           oI8888UU[[[/o@P^:--..
        .@^  YUU[[[/o@^;::---..
      oMP     ^/o@P^;:::---..
   .dMMM    .o@^ ^;::---...
  dMMMMMMM@^`       `^^^^
 YMMMUP^
  ^^
]==]),

  moon = make([==[
                       _.._
                     .' .-'`
                    /  /
                    |  |
                    \  '.___.;
             jgs     '._  _.'
                        ``
]==]),

  tux = make([==[
       .---.
      /     \
      \.@-@./
      /`\_/`\
     //  _  \\
    | \     )|_
   /`\_`>  <_/ \
jgs\__/'---'\__/
]==]),

  doom = make([==[
 =================     ===============     ===============   ========  ========
 \ . . . . . . .\   //. . . . . . .\   //. . . . . . .\  \. . .\// . . //
 ||. . ._____. . .|| ||. . ._____. . .|| ||. . ._____. . .|| || . . .\/ . . .||
 || . .||   ||. . || || . .||   ||. . || || . .||   ||. . || ||. . . . . . . ||
 ||. . ||   || . .|| ||. . ||   || . .|| ||. . ||   || . .|| || . | . . . . .||
 || . .||   ||. _-|| ||-_ .||   ||. . || || . .||   ||. _-|| ||-_.|\ . . . . ||
 ||. . ||   ||-'  || ||  `-||   || . .|| ||. . ||   ||-'  || ||  `|\_ . .|. .||
 || . _||   ||    || ||    ||   ||_ . || || . _||   ||    || ||   |\ `-_/| . ||
 ||_-' ||  .|/    || ||    \|.  || `-_|| ||_-' ||  .|/    || ||   | \  / |-_.||
 ||    ||_-'      || ||      `-_||    || ||    ||_-'      || ||   | \  / |  `||
 ||    `'         || ||         `'    || ||    `'         || ||   | \  / |   ||
 ||            .===' `===.         .==='.`===.         .===' /==. |  \/  |   ||
 ||         .=='   \_|-_ `===. .==='   _|_   `===. .===' _-|/   `==  \/  |   ||
 ||      .=='    _-'    `-_  `='    _-'   `-_    `='  _-'   `-_  /|  \/  |   ||
 ||   .=='    _-'          `-__\._-'         `-_./__-'         `' |. /|  |   ||
 ||.=='    _-'                                                     `' |  /==.||
 =='    _-'                                                            \/   `==
 \   _-'                                                                `-_   /
  `''                                                                      ``'
]==]),
}

-- ---- state ---------------------------------------------------------------

local function state_path()
  return vim.fn.stdpath("state") .. "/dashboard_art"
end

local function read_saved()
  local ok, fd = pcall(io.open, state_path(), "r")
  if not ok or not fd then
    return nil
  end
  local name = fd:read("*l")
  fd:close()
  if name and M.arts[name] then
    return name
  end
  return nil
end

local function save(name)
  if not M.arts[name] then
    return false
  end
  pcall(function()
    local fd = io.open(state_path(), "w")
    if fd then
      fd:write(name)
      fd:close()
    end
  end)
  return true
end

local seeded = false
local function seed()
  if not seeded then
    seeded = true
    pcall(math.randomseed, (tonumber(os.time()) or 0) + (vim.fn.getpid() or 0))
  end
end

-- ---- public API ----------------------------------------------------------

function M.names()
  return vim.deepcopy(M.order)
end

-- every art that fits the given max_width / max_height (missing = no limit)
function M.eligible(opts)
  opts = opts or {}
  local out = {}
  for _, name in ipairs(M.order) do
    local a = M.arts[name]
    if (not opts.max_width or a.width <= opts.max_width)
      and (not opts.max_height or a.height <= opts.max_height) then
      out[#out + 1] = name
    end
  end
  if #out == 0 then
    out[1] = "brand" -- always keep something usable
  end
  return out
end

-- returns lines, name. Defaults to the personal brand; only an art you pick
-- with :DashboardArt / <leader>ua is remembered (so the AS| brand always comes
-- back unless you choose otherwise).
function M.choose(opts)
  local eligible = M.eligible(opts)
  local saved = read_saved()
  if saved then
    for _, name in ipairs(eligible) do
      if name == saved then
        return M.arts[name].lines, name
      end
    end
  end
  return M.arts[eligible[1]].lines, eligible[1]
end

-- pick and remember a random art
function M.random(opts)
  seed()
  local eligible = M.eligible(opts)
  local name = eligible[math.random(#eligible)]
  save(name)
  return M.arts[name].lines, name
end

-- advance to the next art and remember it
function M.advance()
  local saved = read_saved()
  local idx = 0
  for i, name in ipairs(M.order) do
    if name == saved then
      idx = i
      break
    end
  end
  idx = (idx % #M.order) + 1
  save(M.order[idx])
  return M.order[idx]
end

function M.set(name)
  return save(name)
end

function M.saved()
  return read_saved()
end

return M
