-- Set leader keys before lazy and plugins load
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Load core configurations
require("config.options")
require("config.keymaps")
require("config.lazy")
