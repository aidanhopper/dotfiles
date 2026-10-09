return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    init = function()
      -- Neovim 0.12 compatibility shim:
      -- In Neovim 0.12, query matches return quantified captures as tables of nodes ({ [1] = TSNode })
      -- whereas nvim-treesitter query predicates expect single TSNode objects.
      -- Unwrapping them prevents "attempt to call method 'range' (a nil value)" in decoration providers.
      local orig_get_range = vim.treesitter.get_range
      vim.treesitter.get_range = function(node, source, metadata)
        if type(node) == "table" and not node.range then
          node = node[1] or node[#node]
        end
        if not node or not node.range then
          return { 0, 0, 0, 0, 0, 0 }
        end
        return orig_get_range(node, source, metadata)
      end

      local orig_get_node_text = vim.treesitter.get_node_text
      vim.treesitter.get_node_text = function(node, source, opts)
        if type(node) == "table" and not node.range then
          node = node[1] or node[#node]
        end
        if not node or not node.range then
          return ""
        end
        return orig_get_node_text(node, source, opts)
      end
    end,
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "c",
          "cpp",
          "go",
          "html",
          "css",
          "javascript",
          "typescript",
          "lua",
          "python",
          "rust",
          "vim",
          "vimdoc",
        },
        auto_install = true,
        highlight = {
          enable = true,
          disable = { "markdown", "markdown_inline" },
          additional_vim_regex_highlighting = false,
        },
        indent = {
          enable = true,
        },
      })
    end,
  },
}
