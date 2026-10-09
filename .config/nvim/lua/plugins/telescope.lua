return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = {
      defaults = {
        prompt_prefix = "> ",
        selection_caret = "> ",
        layout_strategy = "horizontal",
        layout_config = {
          prompt_position = "top",
          preview_width = 0.55,
        },
        sorting_strategy = "ascending",
      },
      pickers = {
        find_files = {
          hidden = true,
        },
      },
    },
  },
}
