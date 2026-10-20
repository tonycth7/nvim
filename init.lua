-- ═══════════════════════════════════════════════════════════════════════════
--  Neovim config — the table of contents
-- ═══════════════════════════════════════════════════════════════════════════
--  Everything else lives in lua/, one concern per file. To find or add
--  something, follow this map:
--
--    lua/config/        how the editor behaves
--                         options.lua    options (and PATH for mason tools)
--                         lazy.lua       plugin manager bootstrap
--                         keymaps.lua    every keymap
--                         autocmds.lua   every autocommand, grouped by purpose
--                         bin.lua        finds the helper scripts in bin/
--                         health.lua     :checkhealth config
--
--    lua/features/      functionality written for this config
--                         settings.lua       the :Settings panel (<leader>uS)
--                         templates.lua      "new from template" (<leader>nt)
--                         theme_picker.lua   <leader>th, restores the pick
--                         preview/live.lua   autosync .tex/.typ to disk
--                         preview/typst.lua  typst watch + PDF viewer
--                         preview/html.lua   the HTML live server
--
--    lua/dashboard/     dashboard art, and the theme dashboard-nvim requires
--    lua/plugins/       lazy.nvim specs, one file per area
--    bin/               helper executables the features call
--
--  README.md has the same map with "how to add X" recipes; setup.sh installs
--  the external dependencies on a fresh machine. Nothing below needs editing
--  to add a plugin, a keymap, an autocommand or a feature.
-- ═══════════════════════════════════════════════════════════════════════════

require("config.options") -- options first: plugins read them while loading
require("config.lazy") -- loads every lua/plugins/*.lua
require("config.keymaps") -- all keymaps, in one file
require("config.autocmds") -- all autocommands, grouped by purpose

-- Features that own a background job or an autocommand. setup() is tiny for
-- each of these; the work happens when you actually open a matching file.
require("features.preview.live").setup() -- write .tex/.typ shortly after you pause
require("features.preview.typst").setup() -- "preview on open" for .typ
require("features.preview.html").setup() -- "live server on open" for .html

-- The settings panel goes last: it applies your saved choices to the modules
-- above (and to the options), so it has to run after they are loaded.
require("features.settings").setup()

-- Restore the colourscheme picked with <leader>th.
require("features.theme_picker").restore()
