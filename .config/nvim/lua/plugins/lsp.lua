return {
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      require("mason").setup({
        ui = {
          border = "single",
        },
      })

      local capabilities = require("blink.cmp").get_lsp_capabilities()

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
        callback = function(event)
          local bufnr = event.buf
          local nmap = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = bufnr, desc = "LSP: " .. desc })
          end

          nmap("K", vim.lsp.buf.hover, "Hover Documentation")
          nmap("gd", vim.lsp.buf.definition, "Go to Definition")
          nmap("gD", vim.lsp.buf.references, "Go to References")
          nmap("gi", vim.lsp.buf.implementation, "Go to Implementation")
          nmap("gt", vim.lsp.buf.type_definition, "Go to Type Definition")
          nmap("gr", vim.lsp.buf.references, "Go to References")
          nmap("<leader>rn", vim.lsp.buf.rename, "Rename Symbol")
          nmap("<leader>ca", vim.lsp.buf.code_action, "Code Action")
        end,
      })

      -- Pure ASCII diagnostic appearance (no dots, circles, or unicode characters)
      vim.diagnostic.config({
        virtual_text = {
          prefix = ">",
          spacing = 2,
        },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "E",
            [vim.diagnostic.severity.WARN] = "W",
            [vim.diagnostic.severity.INFO] = "I",
            [vim.diagnostic.severity.HINT] = "H",
          },
        },
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      })

      local signs = { Error = "E", Warn = "W", Hint = "H", Info = "I" }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
      end

      -- Helper to auto-detect virtual environments (.venv) for Python
      local function get_python_path(workspace)
        if vim.env.VIRTUAL_ENV then
          local p = vim.fs.joinpath(vim.env.VIRTUAL_ENV, "bin", "python")
          if vim.fn.executable(p) == 1 then return p end
        end
        if workspace then
          local match = vim.fs.find(".venv", { path = workspace, upward = true, type = "directory" })[1]
          if match then
            local p = vim.fs.joinpath(match, "bin", "python")
            if vim.fn.executable(p) == 1 then return p end
          end
        end
        return "python3"
      end

      -- Language servers for Python, Lua, Go, HTML/CSS, JS/TS, C/C++, Rust
      local servers = {
        ruff = {},
        pyright = {
          root_markers = { ".venv", ".git", "pyproject.toml", "setup.py", "requirements.txt", ".envrc" },
          before_init = function(_, config)
            local root = config.root_dir or vim.fn.getcwd()
            local py = get_python_path(root)
            config.settings = config.settings or {}
            config.settings.python = config.settings.python or {}
            config.settings.python.pythonPath = py
            local venv = vim.fs.find(".venv", { path = root, upward = true, type = "directory" })[1]
            if venv then
              config.settings.python.venvPath = vim.fs.dirname(venv)
              config.settings.python.venv = vim.fs.basename(venv)
            end
            config.settings.python.analysis = vim.tbl_deep_extend("force", config.settings.python.analysis or {}, {
              typeCheckingMode = "off",
            })
          end,
          handlers = {
            -- Pyright is used purely for language intelligence (completion, hover, definitions);
            -- Ruff handles all linting and diagnostics.
            ["textDocument/publishDiagnostics"] = function() end,
          },
          settings = {
            python = {
              analysis = {
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "openFilesOnly",
                typeCheckingMode = "off",
              },
            },
          },
        },
        html = {},
        cssls = {},
        ts_ls = {},
        clangd = {},
        rust_analyzer = {},
        lua_ls = {
          settings = {
            Lua = {
              runtime = {
                version = "LuaJIT",
              },
              diagnostics = {
                globals = { "vim" },
              },
              workspace = {
                checkThirdParty = false,
                library = {
                  vim.env.VIMRUNTIME,
                },
              },
              telemetry = {
                enable = false,
              },
            },
          },
        },
      }

      -- Only auto-install gopls if Go runtime is present on system
      if vim.fn.executable("go") == 1 then
        servers.gopls = {}
      end

      -- Configure servers using Neovim 0.11+ native vim.lsp.config & vim.lsp.enable
      for server_name, server_opts in pairs(servers) do
        server_opts.capabilities = vim.tbl_deep_extend("force", capabilities, server_opts.capabilities or {})
        vim.lsp.config(server_name, server_opts)
        vim.lsp.enable(server_name)
      end

      require("mason-lspconfig").setup({
        ensure_installed = vim.tbl_keys(servers),
        automatic_enable = false,
      })
    end,
  },
}
