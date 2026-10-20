# Snippets

LuaSnip loads every `.lua` file in this directory
(`lua/plugins/completion.lua`: `from_lua.load({ paths = "~/.config/nvim/snippets" })`).
Adding a snippet is adding a file here — no restart of anything else.

One file per filetype is the easy convention: `lua.lua`, `markdown.lua`,
`python.lua`, …

```lua
-- snippets/markdown.lua
local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

ls.add_snippets("markdown", {
  -- typing `tee` + <Tab> expands to the block below; <Tab> jumps between $1/$2
  s({ trig = "tee", name = "code fence", dscr = "fenced code block" }, {
    t({ "```$1", "" }),          -- $1 = language
    i(1),
    t({ "```", "" }),
    i(0),                        -- final cursor position
  }),
})
```

Tips

- `trig` must be unique per filetype; `dscr` is what nvim-cmp shows in the menu.
- `ls.snippet` / `text_node` / `insert_node` / `choice_node` cover almost
  everything; `:h luasnip` for dynamic and function nodes.
- Snippets are also offered by nvim-cmp as you type (they appear as `Snippet`
  in the completion menu), not only with <Tab>.
