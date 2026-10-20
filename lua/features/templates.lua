-- Starter templates for new files (used by the <leader>n* keymaps and the
-- dashboard "Template" entry).
local M = {}

local function new_file(ft, ext, lines)
  vim.ui.input({
    prompt = "New " .. ft .. " file: ",
    default = vim.fn.getcwd() .. "/",
    completion = "file",
  }, function(input)
    if not input or input == "" then
      return
    end
    if not input:match("%." .. ext .. "$") then
      input = input .. "." .. ext
    end

    -- Never clobber something that is already there.
    if vim.fn.filereadable(input) == 1 then
      vim.notify(
        vim.fn.fnamemodify(input, ":t") .. " already exists — opened it instead",
        vim.log.levels.WARN
      )
      vim.cmd("edit " .. vim.fn.fnameescape(input))
      return
    end

    vim.cmd("edit " .. vim.fn.fnameescape(input))
    vim.bo.filetype = ft
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.cmd("normal! G")

    -- Write it out. A template file that lives only in the buffer breaks
    -- everything that works from disk: VimTeX compiles the file, `typst watch`
    -- watches it, and the HTML live server serves it. "New from template"
    -- should leave an actual file behind.
    local path = vim.api.nvim_buf_get_name(0)
    if path ~= "" and not path:match("^%w+://") then
      local ok = pcall(vim.cmd, "silent write")
      if ok and vim.uv.fs_stat(path) then
        vim.notify("Created " .. vim.fn.fnamemodify(path, ":t"), vim.log.levels.INFO)
      else
        vim.notify("Could not write " .. path, vim.log.levels.WARN)
      end
    end
  end)
end

-- Every template: a label, the filetype (drives syntax/LSP/treesitter), the
-- extension, and the initial content.
local T = {}

T.markdown = {
  label = "Markdown      .md",
  ft = "markdown",
  ext = "md",
  lines = {
    "---",
    "title: Title",
    "date: " .. os.date("%Y-%m-%d"),
    "---",
    "",
    "# Heading",
    "",
    "Write your content here.",
    "",
  },
}

T.latex = {
  label = "LaTeX         .tex",
  ft = "tex",
  ext = "tex",
  lines = {
    "\\documentclass[11pt]{article}",
    "\\usepackage[margin=1in]{geometry}",
    "\\usepackage{amsmath, amssymb}",
    "\\usepackage{graphicx}",
    "\\usepackage{hyperref}",
    "",
    "\\title{Title}",
    "\\author{Author}",
    "\\date{\\today}",
    "",
    "\\begin{document}",
    "\\maketitle",
    "",
    "\\section{Introduction}",
    "",
    "Write your content here.",
    "",
    "\\end{document}",
  },
}

T.typst = {
  label = "Typst         .typ",
  ft = "typst",
  ext = "typ",
  lines = {
    '#set page(paper: "a4", margin: 2.5cm)',
    '#set text(font: "New Computer Modern", size: 11pt)',
    "#set par(justify: true)",
    '#set heading(numbering: "1.")',
    "",
    "#align(center)[",
    '  #text(size: 20pt, weight: "bold")[Title]',
    "]",
    "",
    "= Introduction",
    "",
    "Write your content here. Inline math: $a^2 + b^2 = c^2$.",
    "",
    "== Section",
    "",
    "- First point",
    "- Second point",
    "",
  },
}

T.rust = {
  label = "Rust          .rs",
  ft = "rust",
  ext = "rs",
  lines = {
    "use std::io;",
    "",
    "fn main() {",
    '    println!("Hello, world!");',
    "}",
    "",
  },
}

T.python = {
  label = "Python        .py",
  ft = "python",
  ext = "py",
  lines = {
    "#!/usr/bin/env python3",
    '"""Short description."""',
    "",
    "",
    "def main() -> None:",
    '    print("Hello, world!")',
    "",
    "",
    'if __name__ == "__main__":',
    "    main()",
    "",
  },
}

T.c = {
  label = "C             .c",
  ft = "c",
  ext = "c",
  lines = {
    "#include <stdio.h>",
    "",
    "int main(void) {",
    '    printf("Hello, world!\\n");',
    "    return 0;",
    "}",
    "",
  },
}

T.cpp = {
  label = "C++           .cpp",
  ft = "cpp",
  ext = "cpp",
  lines = {
    "#include <iostream>",
    "",
    "int main() {",
    '    std::cout << "Hello, world!" << std::endl;',
    "    return 0;",
    "}",
    "",
  },
}

T.go = {
  label = "Go            .go",
  ft = "go",
  ext = "go",
  lines = {
    "package main",
    "",
    'import "fmt"',
    "",
    "func main() {",
    '    fmt.Println("Hello, world!")',
    "}",
    "",
  },
}

T.shell = {
  label = "Shell         .sh",
  ft = "sh",
  ext = "sh",
  lines = {
    "#!/usr/bin/env sh",
    "set -eu",
    "",
    'echo "Hello, world!"',
    "",
  },
}

T.html = {
  label = "HTML          .html",
  ft = "html",
  ext = "html",
  lines = {
    "<!DOCTYPE html>",
    '<html lang="en">',
    "  <head>",
    '    <meta charset="utf-8" />',
    '    <meta name="viewport" content="width=device-width, initial-scale=1" />',
    "    <title>Document</title>",
    "  </head>",
    "  <body>",
    "    <h1>Hello, world!</h1>",
    "  </body>",
    "</html>",
    "",
  },
}

-- Display order for the picker (and any menu built from it).
local ORDER = {
  "markdown",
  "latex",
  "typst",
  "rust",
  "python",
  "c",
  "cpp",
  "go",
  "shell",
  "html",
}

-- Create a specific template by name.
function M.create(name)
  local t = T[name]
  if t then
    new_file(t.ft, t.ext, t.lines)
  end
end

-- Keep the simple named entry points used elsewhere (e.g. M.latex()).
for name, t in pairs(T) do
  M[name] = function()
    new_file(t.ft, t.ext, t.lines)
  end
end

-- A picker: "New from template".
function M.pick()
  local items = {}
  for _, name in ipairs(ORDER) do
    items[#items + 1] = { name = name, label = T[name].label }
  end
  vim.ui.select(items, {
    prompt = "New from template",
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if choice then
      M.create(choice.name)
    end
  end)
end

return M
