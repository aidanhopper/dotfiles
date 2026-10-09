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
map("n", "<leader>q", vim.diagnostic.setqflist, { desc = "Diagnostics in quickfix list" })

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

-- Interactive IPython REPL Execution
local repl = require("config.repl")
map("n", "<leader>rr", repl.send_cell, { desc = "REPL: Run current cell (# %%)" })
map("n", "<leader>rl", repl.send_line, { desc = "REPL: Run current line" })
map("v", "<leader>rx", repl.send_selection, { desc = "REPL: Run visual selection" })
map("n", "<leader>ro", repl.toggle, { desc = "REPL: Toggle bottom split" })
map("n", "<leader>rb", repl.send_buffer, { desc = "REPL: Run entire file" })
map("n", "<leader>rc", repl.clear, { desc = "REPL: Clear screen" })
