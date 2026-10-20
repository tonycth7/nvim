-- Prose: LaTeX (VimTeX), Typst, Markdown. Live previews live in lua/features/preview/.
return {
  -- LaTeX: compile, preview, navigation, TOC (Vimtex)
  {
    "lervag/vimtex",
    lazy = false,
    init = function()
      -- VimTeX supports: latexmk / tectonic / arara / latexrun / texpresso / generic
      -- Prefer latexmk (Arch package: texlive-binextra). If it's missing, fall
      -- back to a tiny multi-pass wrapper so LaTeX still builds out of the box.
      if vim.fn.executable("latexmk") == 1 then
        vim.g.vimtex_compiler_method = "latexmk"
      else
        vim.g.vimtex_compiler_method = "generic"
        vim.g.vimtex_compiler_generic = {
          command = require("config.bin").path("texbuild") .. " @tex",
        }
      end

      vim.g.tex_flavor = "latex"

      -- Viewer (SyncTeX capable). The panel can swap this to Sioyek
      -- (Settings → Viewers), which re-sets both globals at runtime.
      vim.g.vimtex_view_method = "zathura"
      vim.g.vimtex_view_general_viewer = "zathura"

      -- Compilation / quickfix
      vim.g.vimtex_quickfix_mode = 0
      vim.g.vimtex_quickfix_autoclose_after_keystrokes = 2
      vim.g.vimtex_compiler_latexmk = {
        continuous = 1,
        options = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "-file-line-error" },
      }

      -- Live reload for the PDF: recompile on every write. zathura reloads a
      -- changed PDF by itself, so this makes <leader>lv a live preview.
      -- (Only needed while latexmk is absent — with latexmk, continuous mode
      -- does the same thing in the background.)
      vim.api.nvim_create_autocmd("BufWritePost", {
        group = vim.api.nvim_create_augroup("vimtex_compile_on_save", { clear = true }),
        pattern = "*.tex",
        callback = function()
          if vim.fn.executable("latexmk") == 1 then
            return
          end
          if not require("features.settings").get("latex_compile_on_save") then
            return
          end
          vim.cmd("silent VimtexCompile")
        end,
      })

      -- Start a compile as soon as a LaTeX document is initialised, so the PDF
      -- exists and <leader>lv (view) has something to read. Without this, the
      -- generic compiler never runs on its own and viewing an uncompiled
      -- document reports "Viewer cannot read PDF file!". (Canonical recipe from
      -- VimTeX's docs, :h VimtexEventInitPost.)
      vim.api.nvim_create_autocmd("User", {
        group = vim.api.nvim_create_augroup("vimtex_autocompile", { clear = true }),
        pattern = "VimtexEventInitPost",
        callback = function()
          if not require("features.settings").get("latex_compile_on_open") then
            return
          end
          vim.cmd("silent VimtexCompile!")
        end,
      })

      -- Neovim's Tree-sitter handles LaTeX highlighting, so VimTeX's
      -- "Syntax highlighting is controlled by Treesitter!" notice (shown with
      -- the red VimtexError highlight, i.e. it looks like an error) is pure
      -- noise. Silence it; it stays available via :VimtexLog.
      --
      -- Under Wayland (niri) xdotool cannot find Zathura's X11 window, so the
      -- "Viewer cannot find Zathura window ID!" warning fires on every compile
      -- — also pure noise. Zathura still opens and SyncTeX still works on
      -- start; only the "focus an existing window" path is X11-only.
      vim.g.vimtex_log_ignore = {
        "^Syntax highlighting is controlled by Treesitter",
        "Viewer cannot find Zathura window ID",
      }

      -- Quality of life
      vim.g.vimtex_mappings_enabled = 1
      vim.g.vimtex_imaps_enabled = 0        -- don't clash with nvim-cmp
      vim.g.vimtex_indent_enabled = 1
      vim.g.vimtex_syntax_enabled = 1
      vim.g.vimtex_complete_enabled = 0     -- use nvim-cmp instead

      -- Table of contents sidebar
      vim.g.vimtex_toc_config = {
        name = "LaTeX TOC",
        split_pos = "vert left",
        split_width = 32,
        show_help = 0,
        toc_depth = 3,
        layers = { "content", "labels", "todo" },
      }
    end,
  },

  -- Typst: syntax, indent, conceal, watch
  {
    "kaarmu/typst.vim",
    ft = "typst",
    init = function()
      -- The PDF viewer itself is chosen in the settings panel (Settings →
      -- Viewers → Zathura/Sioyek), which also sets vim.g.typst_pdf_viewer.
      vim.g.typst_conceal = 1
      vim.g.typst_conceal_math = 1
      vim.g.typst_conceal_emoji = 1
      vim.g.typst_folding = 0
      vim.g.typst_output_to_tmp = 0
    end,
  },

  -- Typst: live preview in the browser (via tinymist)
  -- Typst live preview in a browser (tinymist backend + bundled websocat,
  -- fetched by :TypstPreviewUpdate). <leader>tp toggles it.
  {
    "chomosuke/typst-preview.nvim",
    ft = "typst",
    version = "1.*",
    opts = {
      dependencies_bin = { tinymist = "tinymist" },
      -- open in the same chrome-less window as the markdown preview
      open_cmd = require("config.bin").path("mdpreview") .. " %s",
      follow_cursor = true,
      invert_colors = "never",
      partial_rendering = true,
      port = 0,
    },
  },

  -- Markdown: render the document *in place* (headings, tables, checkboxes,
  -- code blocks, ...) — no browser, no second window. Toggle with <leader>mr.
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      -- keep it calm: no fold/extra signs, just nicer rendering
      sign = { enabled = false },
      heading = { sign = false },
    },
  },

  -- Obsidian: notes, backlinks, graph and live preview
  {
    "epwalsh/obsidian.nvim",
    ft = { "markdown" },
    lazy = true,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "hrsh7th/nvim-cmp",
      "nvim-treesitter/nvim-treesitter",
    },
  },

  -- Markdown: browser preview, opened in a chrome-less window (mdpreview) so it
  -- reads like a side pane instead of a full browser with tabs/search.
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && npx --yes yarn install",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
      vim.g.mkdp_auto_close = 1
      vim.g.mkdp_theme = "dark"
      -- bin/mdpreview: qutebrowser without tabs/statusbar, else firefox -kiosk
      local mdpreview = require("config.bin").path("mdpreview")
      if vim.fn.executable(mdpreview) == 1 then
        vim.g.mkdp_browser = mdpreview
      elseif vim.fn.executable("mdpreview") == 1 then
        vim.g.mkdp_browser = "mdpreview"
      end
    end,
    ft = { "markdown" },
  },
}
