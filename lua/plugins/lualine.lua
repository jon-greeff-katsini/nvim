vim.pack.add { { src = 'https://github.com/nvim-lualine/lualine.nvim' } }

vim.o.laststatus = 3

require('lualine').setup {
  options = {
    theme = 'catppuccin-nvim',
    globalstatus = true,
    section_separators = '',
    component_separators = '',
  },
}
