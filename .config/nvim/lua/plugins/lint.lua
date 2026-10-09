return {
  {
    -- Manual code formatting
    "stevearc/conform.nvim",
    opts = {
      -- Format-on-save is disabled (manual trigger via <leader>fm or :Format)
      format_on_save = false,
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "ruff_organize_imports", "ruff_format" },
        javascript = { "prettierd", "prettier", stop_after_first = true },
        typescript = { "prettierd", "prettier", stop_after_first = true },
        javascriptreact = { "prettierd", "prettier", stop_after_first = true },
        typescriptreact = { "prettierd", "prettier", stop_after_first = true },
        html = { "prettierd", "prettier", stop_after_first = true },
        css = { "prettierd", "prettier", stop_after_first = true },
        go = { "goimports", "gofmt" },
        c = { "clang-format" },
        cpp = { "clang-format" },
        rust = { "rustfmt" },
      },
    },
  },
  {
    -- Standalone linter runner on save (hands-free)
    "mfussenegger/nvim-lint",
    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {
        python = { "ruff" },
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        go = { "golangcilint" },
      }

      local lint_augroup = vim.api.nvim_create_augroup("nvim-lint", { clear = true })
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
        group = lint_augroup,
        callback = function()
          lint.try_lint()
        end,
      })
    end,
  },
}
