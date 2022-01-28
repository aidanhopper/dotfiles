return require'packer'.startup(function()

	-- Plugin manager
	use 'wbthomason/packer.nvim'

	-- Colorsheme
	use {
		'shaunsingh/nord.nvim',
		config = function ()
			vim.cmd[[
				let g:nord_disable_background = v:true
				let g:nord_cursorline_transparent = v:true
			]]
			--require'nord'.set()
		end
	}

	use {
		'AlphaTechnolog/pywal.nvim', as = 'pywal',
		config = function ()
			local pywal = require('pywal')
			pywal.setup()
		end
	}

	use {
		'rmehri01/onenord.nvim',
		config = function ()
			require'onenord'.setup({
				disable = {
					background = true,
				},
			})
			--vim.cmd[[colorscheme onenord]]
		end
	}

	-- Syntax highlighting
	use {
		'nvim-treesitter/nvim-treesitter',
		run = ':TSUpdate',
		config = function ()
			require'nvim-treesitter.configs'.setup ({
				highlight = { enable = true },
				indent = { enable = true }
			})
		end
	}

	-- Statusline
	use {
		'nvim-lualine/lualine.nvim',
		requires = { 'kyazdani42/nvim-web-devicons', opt = true },
		config = function ()


			local pywal_theme = require('pywal.lualine.themes.pywal-nvim')
			require'lualine'.setup({
				options = { theme = pywal_theme }
			})
		end
	}

	-- Autocomplete
	use {
		'hrsh7th/nvim-cmp',
	}

	-- Autopairs
	use {
		'windwp/nvim-autopairs',
		requires = { 'hrsh7th/nvim-cmp' },
		config = function ()
			require'nvim-autopairs'.setup{}
		end
	}

	-- Lspconfig
	use {
		'neovim/nvim-lspconfig',
    	'williamboman/nvim-lsp-installer',
	}

	-- Filetree
	use {
		'kyazdani42/nvim-tree.lua',
    	requires = {
      		'kyazdani42/nvim-web-devicons', -- optional, for file icon
    	},
    	config = function() require'nvim-tree'.setup {} end
	}

end)
