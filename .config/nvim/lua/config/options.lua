local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Vi-like status & UI
opt.laststatus = 2      -- Always display standard statusline
opt.showmode = true     -- Display -- INSERT --, -- VISUAL -- etc.
opt.ruler = true        -- Show line and column number of the cursor position
opt.signcolumn = "yes"  -- Keep signcolumn open so text doesn't shift for diagnostics
opt.showtabline = 0     -- Never display tabs at the top of the editor

-- Cursor and visual guides
opt.cursorline = true   -- Highlight current line
opt.cursorcolumn = true -- Highlight current column crosshair
opt.colorcolumn = "80"  -- Visual guideline at column 80

-- Indentation & Tabs
opt.expandtab = true    -- Convert tabs to spaces
opt.smarttab = true     -- Insert shiftwidth spaces when hitting Tab at line beginning
opt.shiftwidth = 4      -- Indent by 4 spaces
opt.tabstop = 4         -- Tab width 4 spaces
opt.smartindent = true  -- Autoindent new lines smartly

-- Search
opt.ignorecase = true   -- Case insensitive searching
opt.smartcase = true    -- Case-sensitive if pattern contains uppercase
opt.incsearch = true    -- Incremental search
opt.hlsearch = true     -- Highlight search matches

-- Command-line wildmenu & recursive path search (:find, :e **/)
opt.wildmenu = true
opt.wildmode = "longest:full,full"
opt.path:append("**")   -- Search down into subdirectories recursively
opt.wildignore:append({
  "*/node_modules/*",
  "*/.git/*",
  "*/.venv/*",
  "*/__pycache__/*",
  "*.o",
  "*.so",
  "*.pyc",
  "*/target/*",
})

-- Behavior & Windows
opt.splitright = true   -- Open new vertical splits to the right
opt.splitbelow = true   -- Open new horizontal splits below
opt.clipboard = "unnamedplus" -- Sync with system clipboard
opt.undofile = true     -- Persistent undo history across sessions
opt.swapfile = false    -- Disable swap files
opt.updatetime = 250    -- Faster completion and diagnostic updates
opt.timeoutlen = 1000   -- Wait time for mapped sequences before timing out

-- Colors
opt.termguicolors = true

-- Python provider (dedicated environment for Neovim remote plugins & Molten)
local py3_path = vim.fn.expand("~/.local/share/nvim/molten-venv/bin/python")
if vim.fn.executable(py3_path) == 1 then
  vim.g.python3_host_prog = py3_path
elseif vim.fn.executable(vim.fn.expand("~/.local/share/nvim/venv/bin/python")) == 1 then
  vim.g.python3_host_prog = vim.fn.expand("~/.local/share/nvim/venv/bin/python")
end

-- Netrw (built-in file explorer) vi styling
vim.g.netrw_banner = 0         -- Remove the header banner
vim.g.netrw_liststyle = 0      -- Thin/simple vi file listing
vim.g.netrw_browse_split = 0   -- Open files in current window
vim.g.netrw_winsize = 25       -- Default window width if opened as a split
vim.g.netrw_keepdir = 1        -- Keep the current directory synchronized
