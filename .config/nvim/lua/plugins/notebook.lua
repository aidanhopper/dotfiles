return {
  -- 1. Image rendering via Ghostty's Kitty graphics protocol
  {
    "3rd/image.nvim",
    opts = {
      backend = "kitty",
      processor = "magick_cli",
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = false,
          filetypes = { "markdown", "quarto" },
        },
      },
      max_width = 100,
      max_height = 20,
      max_width_window_percentage = math.huge,
      max_height_window_percentage = math.huge,
      window_overlap_clear_enabled = true,
      window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
    },
  },

  -- 2. Molten: Jupyter kernel code runner with output display
  {
    "benlubas/molten-nvim",
    version = "^1.0.0",
    dependencies = { "3rd/image.nvim" },
    build = ":UpdateRemotePlugins",
    init = function()
      vim.g.molten_image_provider = "image.nvim"
      vim.g.molten_output_win_max_height = 20
      vim.g.molten_auto_open_output = false
      vim.g.molten_wrap_output = true
      vim.g.molten_virt_text_output = true
      vim.g.molten_virt_lines_off_by_1 = true
      vim.g.molten_auto_init_behavior = "raise"
    end,
  },

  -- 3. Otter: Embedded language LSP support in markdown code blocks
  {
    "jmbuhr/otter.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {},
  },

  -- 5. Quarto: Literate notebook tools and runner integration
  {
    "quarto-dev/quarto-nvim",
    dependencies = {
      "jmbuhr/otter.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    ft = { "quarto", "markdown" },
    opts = {
      lspFeatures = {
        enabled = true,
        chunks = "all",
        languages = { "python" },
        diagnostics = {
          enabled = true,
          triggers = { "BufWritePost" },
        },
        completion = {
          enabled = true,
        },
      },
      codeRunner = {
        enabled = true,
        default_method = "molten",
      },
    },
    config = function(_, opts)
      local q = require("quarto")
      q.setup(opts)

      -- Intercept Quarto preview to always render in /tmp without tabs or cwd pollution
      local nb = require("config.notebook")
      q.quartoPreview = function() nb.start_preview() end
      q.quartoClosePreview = function() nb.close_preview() end

      vim.api.nvim_create_user_command("QuartoPreview", function()
        nb.start_preview()
      end, { force = true, desc = "Start Quarto live preview in /tmp" })

      vim.api.nvim_create_user_command("QuartoClosePreview", function()
        nb.close_preview()
      end, { force = true, desc = "Close Quarto live preview" })
    end,
  },
}
