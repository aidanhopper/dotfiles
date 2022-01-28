global_options = {
    mouse = 'a',    
    hidden = true,
    ruler = true,
    history = 1000,
    ignorecase = true,
    termguicolors = true,
    scrolloff = 8,
}

local_options = {
    shiftwidth = 4,
    tabstop = 4,
}

window_options = {
    relativenumber = true,
	number = true,
    cursorline = true,
}

local function bind_global(options)
    for k, v in pairs(options) do
        vim.api.nvim_set_option(k, v)
    end
end

local function bind_local(options)
    for k, v in pairs(options) do
        vim.api.nvim_buf_set_option(0, k, v)
    end
end

local function bind_window(options)
    for k, v in pairs(options) do
        vim.api.nvim_win_set_option(0, k, v)
    end
end

vim.g.mapleader = ' '
bind_global(global_options)
bind_local(local_options)
bind_window(window_options)
