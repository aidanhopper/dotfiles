return {
  {
    "saghen/blink.cmp",
    dependencies = { "rafamadriz/friendly-snippets" },
    version = "*",
    opts = {
      -- Vi-style keybindings: C-n / C-p to cycle, C-y to accept, C-e to cancel
      keymap = {
        preset = "none",
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"] = { "hide", "fallback" },
        ["<C-y>"] = { "select_and_accept" },
        ["<C-p>"] = { "select_prev", "fallback" },
        ["<C-n>"] = { "select_next", "fallback" },
        ["<C-b>"] = { "scroll_documentation_up", "fallback" },
        ["<C-f>"] = { "scroll_documentation_down", "fallback" },
      },
      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = "mono",
      },
      completion = {
        -- Show documentation window beside completion menu with function details & docstrings
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 150,
          treesitter_highlighting = true,
          window = {
            border = "single",
          },
        },
        menu = {
          border = "single",
          draw = {
            columns = {
              { "label", "label_description", gap = 1 },
              { "kind_icon", "kind", gap = 1 },
            },
          },
        },
      },
      -- Signature help popup when calling functions foo(...)
      signature = {
        enabled = true,
        window = {
          border = "single",
        },
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
    },
    opts_extend = { "sources.default" },
  },
}
