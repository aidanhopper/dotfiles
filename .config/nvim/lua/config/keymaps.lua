local map = vim.keymap.set

-- Clear search highlight on Esc in normal mode
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Built-in Netrw explorer (pure vi)
map("n", "<leader>pv", "<cmd>Explore<CR>", { silent = true, desc = "Project view (netrw)" })
map("n", "<leader>e", "<cmd>Explore<CR>", { silent = true, desc = "Open netrw file explorer" })

-- Telescope fuzzy finder (Project shortcuts)
map("n", "<leader>pf", "<cmd>Telescope find_files<CR>", { silent = true, desc = "Find project files" })
map("n", "<leader>pg", "<cmd>Telescope live_grep<CR>", { silent = true, desc = "Project live grep" })
map("n", "<leader>pc", "<cmd>Telescope git_commits<CR>", { silent = true, desc = "Project git commits" })

-- Telescope fuzzy finder (Standard shortcuts)
map("n", "<leader>ff", "<cmd>Telescope find_files<CR>", { silent = true, desc = "Find files" })
map("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", { silent = true, desc = "Live grep" })
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { silent = true, desc = "Buffers" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", { silent = true, desc = "Help tags" })

-- Diagnostic navigation (standard vim style)
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "<leader>d", vim.diagnostic.open_float, { desc = "Show line diagnostic" })
map("n", "<leader>dq", vim.diagnostic.setqflist, { desc = "Diagnostics in quickfix list" })

-- Quarto Live Browser Preview (renders 100% in /tmp, zero cwd pollution)
map("n", "<leader>qp", function()
  require("config.notebook").start_preview()
end, { silent = true, desc = "Quarto: Live browser preview (in /tmp)" })

map("n", "<leader>qc", function()
  require("config.notebook").close_preview()
end, { silent = true, desc = "Quarto: Close preview" })

-- Manual code formatting
map({ "n", "v" }, "<leader>fm", function()
  require("conform").format({ lsp_fallback = true, async = false, timeout_ms = 2000 })
  vim.notify("Buffer formatted", vim.log.levels.INFO)
end, { desc = "Format buffer manually" })

-- User command :Format
vim.api.nvim_create_user_command("Format", function(args)
  local range = nil
  if args.count ~= -1 then
    local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
    range = {
      start = { args.line1, 0 },
      ["end"] = { args.line2, end_line and end_line:len() or 0 },
    }
  end
  require("conform").format({ lsp_fallback = true, async = false, timeout_ms = 2000, range = range })
  vim.notify("Buffer formatted", vim.log.levels.INFO)
end, { range = true, desc = "Format current buffer or selection" })

-- Notebook & Molten execution
local nb = require("config.notebook")
map("n", "<leader>rr", nb.run_cell, { desc = "Notebook: Run current cell" })
map("n", "<leader>ra", nb.run_above, { desc = "Notebook: Run cell and above" })
map("n", "<leader>rA", nb.run_all, { desc = "Notebook: Run all cells" })
map("n", "<leader>rl", nb.run_line, { desc = "Notebook: Run current line" })
map("v", "<leader>rx", nb.run_selection, { desc = "Notebook: Run visual selection" })
map("n", "<leader>ro", nb.show_output, { desc = "Notebook: Show/focus output" })
map("n", "<leader>rh", nb.hide_output, { desc = "Notebook: Hide output window" })
map("n", "<leader>rd", nb.delete_output, { desc = "Notebook: Clear cell output" })
map("n", "<leader>rR", nb.restart_kernel, { desc = "Notebook: Restart kernel" })
map("n", "<leader>rk", nb.kernel_info, { desc = "Notebook: Check kernel & python path" })
map("n", "<leader>ri", nb.init_kernel, { desc = "Notebook: Init / switch kernel" })
map("n", "<leader>rc", nb.new_cell, { desc = "Notebook: Insert new cell below" })
map("n", "]c", nb.next_cell, { desc = "Notebook: Next cell" })
map("n", "[c", nb.prev_cell, { desc = "Notebook: Previous cell" })
