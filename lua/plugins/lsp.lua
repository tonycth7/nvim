-- Language servers: mason installs them, none-ls formats and lints.
return {
  -- Auto-install LSP servers via Mason
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = {
      "mason-org/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    opts = {
      ensure_installed = {
        "lua_ls", "ts_ls", "pyright", "gopls", "rust_analyzer",
        "texlab", "tinymist", "marksman",
      },
      automatic_installation = true,
      handlers = {},
    },
  },

  -- LSP server configs (Neovim 0.12+ native API)
  {
    "neovim/nvim-lspconfig",
    config = function()
      local capabilities = vim.lsp.protocol.make_client_capabilities()

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          local bufopts = { buffer = ev.buf, silent = true }

          bufopts.desc = "Definition"
          vim.keymap.set("n", "<leader>ld", vim.lsp.buf.definition, bufopts)
          bufopts.desc = "Type definition"
          vim.keymap.set("n", "<leader>lD", vim.lsp.buf.type_definition, bufopts)
          bufopts.desc = "Declaration"
          vim.keymap.set("n", "<leader>lL", vim.lsp.buf.declaration, bufopts)
          bufopts.desc = "Implementation"
          vim.keymap.set("n", "<leader>li", vim.lsp.buf.implementation, bufopts)
          bufopts.desc = "References"
          vim.keymap.set("n", "<leader>lr", vim.lsp.buf.references, bufopts)
          bufopts.desc = "Hover"
          vim.keymap.set("n", "<leader>lh", vim.lsp.buf.hover, bufopts)
          bufopts.desc = "Signature help"
          vim.keymap.set("n", "<leader>ls", vim.lsp.buf.signature_help, bufopts)
          bufopts.desc = "Document symbols"
          vim.keymap.set("n", "<leader>lo", vim.lsp.buf.document_symbol, bufopts)
          bufopts.desc = "Workspace symbols"
          vim.keymap.set("n", "<leader>lw", vim.lsp.buf.workspace_symbol, bufopts)
          bufopts.desc = "Code actions"
          vim.keymap.set({ "n", "v" }, "<leader>la", vim.lsp.buf.code_action, bufopts)
          bufopts.desc = "Rename"
          vim.keymap.set("n", "<leader>lrn", vim.lsp.buf.rename, bufopts)
          bufopts.desc = "Line diagnostics"
          vim.keymap.set("n", "<leader>ldd", vim.diagnostic.open_float, bufopts)
          bufopts.desc = "Prev diagnostic"
          vim.keymap.set("n", "<leader>ldp", vim.diagnostic.goto_prev, bufopts)
          bufopts.desc = "Next diagnostic"
          vim.keymap.set("n", "<leader>ldn", vim.diagnostic.goto_next, bufopts)
          bufopts.desc = "Format"
          vim.keymap.set("n", "<leader>lf", function()
            vim.lsp.buf.format({ async = false })
          end, bufopts)
        end,
      })

      vim.diagnostic.config({
        virtual_text = { prefix = "●", spacing = 4, source = "if_many" },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "",
            [vim.diagnostic.severity.WARN] = "",
            [vim.diagnostic.severity.INFO] = "",
            [vim.diagnostic.severity.HINT] = "",
          },
        },
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = { border = "rounded", source = "if_many", header = "", prefix = "" },
      })

      vim.lsp.config("*", { capabilities = capabilities })

      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
            hint = { enable = true },
          },
        },
      })

      vim.lsp.config("tinymist", {
        settings = {
          tinymist = {
            formatterMode = "typstyle",
            semanticTokens = "disable",
          },
        },
      })

      vim.lsp.config("texlab", {
        settings = {
          texlab = {
            build = { onSave = false },
            chktex = { onOpenAndSave = false, onEdit = false },
            diagnosticsDelay = 300,
            latexFormatter = "latexindent",
            latexindent = { modifyLineBreaks = false },
          },
        },
      })

      -- bacon-ls is auto-enabled by Mason but only makes sense inside a Cargo
      -- project; without one it just sprays `cargo` errors at loose .rs files.
      vim.lsp.config("bacon_ls", { workspace_required = true })

      vim.lsp.enable({
        "lua_ls",
        "ts_ls",
        "pyright",
        "gopls",
        "rust_analyzer",
        "texlab",
        "tinymist",
        "marksman",
      })
    end,
  },

  -- Extra formatters via none-ls (only the ones actually available)
  {
    "nvimtools/none-ls.nvim",
    event = { "BufWritePre", "BufReadPre" },
    config = function()
      local null_ls = require("null-ls")
      local sources = {}

      local map = {
        stylua = null_ls.builtins.formatting.stylua,
        shfmt = null_ls.builtins.formatting.shfmt,
        prettier = null_ls.builtins.formatting.prettier,
        black = null_ls.builtins.formatting.black,
        goimports = null_ls.builtins.formatting.goimports,
      }

      for bin, source in pairs(map) do
        if vim.fn.executable(bin) == 1 then
          table.insert(sources, source)
        end
      end

      null_ls.setup({ sources = sources })
    end,
  },
}
