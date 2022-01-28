function map(mode, lhs, rhs, opts)
	local options = { noremap = true }
	if opts then
		options = vim.tbl_extend('force', options, opts)
	end
	vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

-- Enter normal mode with jk in insert mode
map('i', 'jk', "<ESC><UP><CR>")

-- Use ctrl to navigate in insert mode
map('i', '<C-j>', "<Down>")
map('i', '<C-h>', "<Left>")
map('i', '<C-l>', "<Right>")
map('i', '<C-k>', "<Up>")

-- Cycle through buffers with tab in normal mode
map('n', '<Tab>', ":bn<CR>", { silent = true })
map('n', '<S-Tab>', ":bp<CR>", { silent = true })

-- Runner 
map('n', '<F5>', ':! ./run<CR>', { silent = true })

-- Tree
map('n', '<C-n>', ':NvimTreeToggle<CR>', { silent = true })

