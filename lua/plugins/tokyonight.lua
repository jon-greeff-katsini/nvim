vim.pack.add{
	{ src = "https://github.com/folke/tokyonight.nvim", name = "tokyonight" }
}


-- configure the theme
require('tokyonight').setup({ style = 'night' })
vim.cmd.colorscheme("tokyonight")
