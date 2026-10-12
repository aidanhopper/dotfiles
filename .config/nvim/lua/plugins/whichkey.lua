return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "classic",
      delay = 600, -- Delay in ms before popup appears
      win = {
        border = "single",
      },
      spec = {
        { "<leader>r", group = "notebook / run" },
        { "<leader>p", group = "project" },
        { "<leader>f", group = "find / format" },
        { "<leader>c", group = "code" },
        { "<leader>q", group = "quarto preview" },
        { "<leader>d", group = "diagnostics" },
      },
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer Local Keymaps (which-key)",
      },
    },
  },
}
